import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/constants/master_destinations.dart';
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

class DiscoveryImage extends StatelessWidget {
  final String? image;
  final String label;
  final double height;
  const DiscoveryImage({
    super.key,
    required this.image,
    required this.label,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
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
    if (image == null || image!.isEmpty) return fallback();
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
