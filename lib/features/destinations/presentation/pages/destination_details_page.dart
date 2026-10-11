import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookings/domain/models/saved_place_model.dart';
import '../../../bookings/presentation/widgets/save_place_button.dart';
import '../../../explore/presentation/widgets/discovery_widgets.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../places/presentation/providers/places_provider.dart';

class DestinationDetailsPage extends ConsumerWidget {
  final String id;
  const DestinationDetailsPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest = findDestinationById(id);
    final tokens = AdaptiveThemeExtension.of(context);
    if (dest == null) {
      return Scaffold(
        appBar: AppBar(leading: const NavHubLeading()),
        body: const Center(
          child: Text('Destination unavailable. Return to Explore.'),
        ),
      );
    }
    final provider = nearbyPlacesProvider((
      lat: dest.lat,
      lng: dest.lng,
      type: 'tourist_attraction',
    ));
    final nearby = ref.watch(provider);
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(leading: const NavHubLeading(), title: Text(dest.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            child: DiscoveryImage(
              image: destinationImage(dest),
              label: dest.name,
              height: 230 * tokens.imageProminence,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            dest.state.toUpperCase(),
            style: AppTypography.eyebrow(color: tokens.editorialBrown),
          ),
          Text(
            dest.name,
            style: AppTypography.editorialTitle(color: tokens.editorialBrown),
          ),
          const SizedBox(height: 12),
          Text(
            dest.description.isEmpty
                ? 'Description unavailable.'
                : dest.description,
            style: AppTypography.bodyLarge(color: tokens.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            '${dest.category}${dest.bestTime.isEmpty ? '' : ' · Season guide: ${dest.bestTime}'}',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push(
                  '/trip-planner',
                  extra: {'destination': dest.id},
                ),
                icon: const Icon(Icons.route),
                label: const Text('Plan this trip'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/map?destination=${dest.id}'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open map'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/restaurants?destination=${dest.id}'),
                icon: const Icon(Icons.restaurant_outlined),
                label: const Text('Find food'),
              ),
            ],
          ),
          SavePlaceButton(
            destinationId: dest.id,
            place: SavedPlaceModel(
              id: dest.id,
              name: dest.name,
              type: 'destination',
              image: destinationImage(dest),
              location: dest.state,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Around ${dest.name}',
            style: AppTypography.sectionTitle(color: tokens.editorialBrown),
          ),
          const Text(
            'Provider listings. Check current details before travelling.',
          ),
          nearby.when(
            skipLoadingOnRefresh: false,
            loading: () => const LinearProgressIndicator(
              semanticsLabel: 'Loading nearby places',
            ),
            error: (_, __) => DiscoveryMessage(
              'Nearby places are unavailable.',
              onRetry: () => ref.invalidate(provider),
            ),
            data: (places) => places.isEmpty
                ? DiscoveryMessage(
                    'No nearby results returned. The provider may be unavailable.',
                    onRetry: () => ref.invalidate(provider),
                  )
                : Column(
                    children: places
                        .map(
                          (place) => DiscoveryPlaceTile(
                            place: place,
                            destinationId: dest.id,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
