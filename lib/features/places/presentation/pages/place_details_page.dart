import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookings/domain/models/saved_place_model.dart';
import '../../../bookings/presentation/widgets/save_place_button.dart';
import '../../../explore/presentation/widgets/discovery_widgets.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../domain/models/place_model.dart';

class PlaceDetailsPage extends StatelessWidget {
  final PlaceModel place;
  const PlaceDetailsPage({super.key, required this.place});
  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: const NavHubLeading(),
        title: const Text('Place details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DiscoveryImage(image: place.photoUrl, label: place.name),
          const SizedBox(height: 20),
          Text(
            place.name,
            style: AppTypography.editorialTitle(color: tokens.editorialBrown),
          ),
          if (place.vicinity.isNotEmpty) Text(place.vicinity),
          const SizedBox(height: 12),
          Text(
            place.rating > 0
                ? 'Provider rating: ${place.rating}'
                : 'Rating unavailable',
          ),
          if (place.userRatingsTotal > 0)
            Text('${place.userRatingsTotal} provider reviews'),
          if (place.description?.isNotEmpty == true) Text(place.description!),
          // Opening status is a retrieved snapshot, not a claim of live freshness.
          Text(
            place.isOpen == null
                ? 'Opening hours unavailable'
                : 'Provider reported ${place.isOpen! ? 'open' : 'closed'} when retrieved. Verify before visiting.',
          ),
          const SizedBox(height: 16),
          SavePlaceButton(
            place: SavedPlaceModel(
              id: place.id,
              name: place.name,
              type: place.types.isEmpty ? 'Place' : place.types.first,
              image: place.photoUrl,
              location: place.vicinity,
            ),
          ),
          if (place.hasCoordinates)
            OutlinedButton.icon(
              onPressed: () => context.push('/map', extra: place),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open place map'),
            )
          else
            const Text('Map coordinates unavailable'),
        ],
      ),
    );
  }
}
