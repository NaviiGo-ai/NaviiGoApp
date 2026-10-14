import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/network/api_provider.dart';
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
    FutureProvider.family<Map<String, dynamic>, String>((ref, label) async {
      final query =
          const {
            'Manali': 'Manali, Himachal Pradesh',
            'Kochi': 'Kochi',
          }[label] ??
          label;
      final result = await ref
          .read(apiClientProvider)
          .get(
            '/api/places/destination-image',
            queryParams: {'query': query},
            requiresAuth: false,
          );
      return result is Map ? Map<String, dynamic>.from(result) : const {};
    });

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
    final tokens = AdaptiveThemeExtension.of(context);
    Widget fallback() => Semantics(
      label: 'Photo unavailable for $label',
      child: Container(
        height: height,
        width: double.infinity,
        color: tokens.surfaceWarm,
        alignment: Alignment.center,
        child: Icon(
          Icons.landscape_outlined,
          size: 44,
          color: tokens.editorialBrown,
        ),
      ),
    );
    if (image == null || image!.isEmpty) {
      final photo = ref.watch(destinationPhotoProvider(label));
      final data = photo.valueOrNull;
      final url = data?['image'] as String?;
      if (url == null) return fallback();
      return Stack(
        children: [
          Image.network(
            url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: label,
            errorBuilder: (_, __, ___) => fallback(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: creditAtTop ? null : 0,
            top: creditAtTop ? 0 : null,
            child: Material(
              color: Colors.black.withAlpha(160),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse(data!['sourceUrl'] as String),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    '${data?['credit']} · ${data?['license']} · Wikimedia Commons',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    maxLines: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final uri = Uri.tryParse(image!);
    if (uri?.scheme == 'https') {
      return Image.network(
        image!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: label,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }
    if (image!.startsWith('assets/')) {
      return Image.asset(
        image!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: label,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }
    return fallback();
  }
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
