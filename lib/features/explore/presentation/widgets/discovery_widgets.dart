import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../analytics/data/analytics_repository.dart';
import '../../../places/domain/models/place_model.dart';

// Only these bundled images identify their registry city. Other registry
// entries reuse another city's image, so discovery uses an honest placeholder.
String? destinationImage(MasterDestination destination) =>
    switch (destination.id) {
      'varanasi' || 'jaipur' || 'rishikesh' => destination.image,
      _ => null,
    };

String? approvedDestinationImage({
  required String destinationId,
  required String? image,
}) {
  final registryDestination = findDestinationById(destinationId);
  if (registryDestination != null) return destinationImage(registryDestination);
  final uri = image == null ? null : Uri.tryParse(image);
  return uri?.scheme == 'https' ? image : null;
}

final destinationPhotoProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
      (ref, label) => _loadPhoto(ref, label),
    );
final reusableDestinationPhotoProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
      (ref, label) => _loadPhoto(ref, label, reusable: true),
    );
Future<Map<String, dynamic>> _loadPhoto(
  Ref ref,
  String label, {
  bool reusable = false,
}) async {
  final api = ref.read(apiClientProvider);
  final query = String.fromCharCodes(
    (label == 'Manali' ? 'Manali, Himachal Pradesh' : label).trim().runes.take(
      100,
    ),
  );
  final result = await api.get(
    '/api/places/destination-image',
    queryParams: {'query': query, if (reusable) 'reusable': 'true'},
    requiresAuth: false,
    timeout: const Duration(seconds: 90),
  );
  final data = result is Map
      ? Map<String, dynamic>.from(result)
      : <String, dynamic>{};
  final image = data['image'];
  if (image is String && image.startsWith('/')) {
    data['image'] = '${api.baseUrl}$image';
  }
  if (data['image'] is! String) data.remove('image');
  return data;
}

bool _isDiscoveryPhotoSource(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return false;
  if (uri.scheme == 'https') return true;
  final api = Uri.tryParse(AppConfig.apiBaseUrl);
  return uri.scheme == 'http' &&
      api?.scheme == 'http' &&
      uri.origin == api?.origin &&
      uri.path.startsWith('/api/places/');
}

class DiscoveryImage extends ConsumerWidget {
  final String? image;
  final String label;
  final double height;
  final bool creditAtTop;
  const DiscoveryImage({
    super.key,
    required this.image,
    required this.label,
    this.height = 200,
    this.creditAtTop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget placeholder({bool loading = false, VoidCallback? retry}) =>
        _DiscoveryPhotoPlaceholder(
          label: label,
          loading: loading,
          onRetry: retry,
        );
    final explicit = image?.trim();
    if (explicit != null && explicit.startsWith('assets/')) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          explicit,
          fit: BoxFit.cover,
          semanticLabel: label,
          errorBuilder: (_, _, _) => placeholder(),
        ),
      );
    }
    if (explicit != null && _isDiscoveryPhotoSource(explicit)) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: _RemoteDiscoveryPhoto(url: explicit, label: label),
      );
    }
    final photo = ref.watch(destinationPhotoProvider(label));
    final data = photo.valueOrNull;
    final candidate = data?['image'];
    final url = candidate is String && candidate.startsWith('/')
        ? '${AppConfig.apiBaseUrl}$candidate'
        : candidate;
    void retry() => ref.invalidate(destinationPhotoProvider(label));
    if (url is! String || !_isDiscoveryPhotoSource(url)) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: placeholder(
          loading: photo.isLoading,
          retry: photo.isLoading ? null : retry,
        ),
      );
    }
    final credit = [
      data?['credit'],
      data?['source'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final sourceValue = data?['sourceUrl'];
    final source = sourceValue is String ? Uri.tryParse(sourceValue) : null;
    final colors = AdaptiveThemeExtension.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        verticalDirection: creditAtTop
            ? VerticalDirection.up
            : VerticalDirection.down,
        children: [
          Expanded(
            child: _RemoteDiscoveryPhoto(
              url: url,
              label: label,
              onRetryMetadata: retry,
            ),
          ),
          Material(
            color: colors.surface,
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Photo credits'),
                  content: Text(
                    '${credit.isEmpty ? 'Photo source' : credit}\n${data?['license'] is String ? data!['license'] : ''}',
                  ),
                  actions: [
                    if (source?.scheme == 'https')
                      TextButton(
                        onPressed: () => launchUrl(
                          source!,
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text('View source'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              child: SizedBox(
                height: 20,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          credit.isEmpty ? 'Photo credits' : credit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryPhotoPlaceholder extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onRetry;
  const _DiscoveryPhotoPlaceholder({
    required this.label,
    this.loading = false,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    return Semantics(
      label: loading
          ? 'Loading photo for $label'
          : 'Photo unavailable for $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surfaceWarm, colors.surface, colors.surfaceWarm],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  loading
                      ? Icons.wb_twilight_outlined
                      : Icons.landscape_outlined,
                  size: 34,
                  color: colors.editorialBrown.withAlpha(100),
                ),
              ),
              if (constraints.maxHeight >= 100)
                Positioned(
                  left: 14,
                  right: 50,
                  bottom: 12,
                  child: Text(
                    loading ? 'Finding a view…' : 'Photo unavailable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(color: colors.textSecondary),
                  ),
                ),
              if (onRetry != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: onRetry,
                    tooltip: 'Retry photo',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteDiscoveryPhoto extends StatefulWidget {
  final String url;
  final String label;
  final VoidCallback? onRetryMetadata;
  const _RemoteDiscoveryPhoto({
    required this.url,
    required this.label,
    this.onRetryMetadata,
  });
  @override
  State<_RemoteDiscoveryPhoto> createState() => _RemoteDiscoveryPhotoState();
}

class _RemoteDiscoveryPhotoState extends State<_RemoteDiscoveryPhoto> {
  int _attempt = 0;
  bool _retrying = false;
  @override
  void didUpdateWidget(covariant _RemoteDiscoveryPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _attempt = 0;
  }

  Future<void> _retry() async {
    if (_retrying) return;
    _retrying = true;
    try {
      await NetworkImage(widget.url).evict();
      if (!mounted) return;
      setState(() {
        _attempt++;
        _retrying = false;
      });
      widget.onRetryMetadata?.call();
    } catch (_) {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final logicalWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final decodeWidth =
          (logicalWidth * MediaQuery.devicePixelRatioOf(context))
              .clamp(120, 1600)
              .round();
      return Image.network(
        widget.url,
        key: ValueKey('${widget.url}:$_attempt'),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: decodeWidth,
        semanticLabel: widget.label,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) =>
            _DiscoveryPhotoPlaceholder(label: widget.label, onRetry: _retry),
        frameBuilder: (context, child, frame, synchronous) {
          if (frame == null) {
            return _DiscoveryPhotoPlaceholder(
              label: widget.label,
              loading: true,
            );
          }
          if (synchronous || MediaQuery.disableAnimationsOf(context)) {
            return child;
          }
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            builder: (_, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: child,
          );
        },
      );
    },
  );
}

class OptionalPlacePhoto extends ConsumerWidget {
  final String title;
  const OptionalPlacePhoto({super.key, required this.title});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(destinationPhotoProvider(title)).valueOrNull;
    if (photo?['image'] == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DiscoveryImage(image: null, label: title, height: 120),
      ),
    );
  }
}

class DiscoveryMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const DiscoveryMessage(this.message, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(liveRegion: true, child: Text(message)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class DiscoveryPlaceTile extends ConsumerWidget {
  final PlaceModel place;
  final String? destinationId;
  const DiscoveryPlaceTile({
    super.key,
    required this.place,
    this.destinationId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(place.name, style: AppTypography.bodyLarge()),
      subtitle: Text(
        [
          if (place.vicinity.isNotEmpty) place.vicinity,
          if (place.rating > 0) 'Provider rating ${place.rating}',
        ].join('\n'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Interaction only, never a rebuild. The frozen queue captures UID
        // synchronously before persistence; failures cannot block navigation.
        ref
            .read(analyticsRepositoryProvider)
            .logEvent(
              eventType: 'PLACE_VIEWED',
              placeId: place.id,
              destinationId: destinationId,
            )
            .catchError((Object _) {});
        context.push('/place-details', extra: place);
      },
    ),
  );
}
