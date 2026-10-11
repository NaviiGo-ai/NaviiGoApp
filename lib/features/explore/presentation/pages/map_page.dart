import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../places/domain/models/place_model.dart';

/// Coordinate-preserving map handoff. No decorative canvas pretends to be a
/// navigable map, and no map SDK/provider key is bundled in the client.
class MapPage extends StatelessWidget {
  final MasterDestination? selectedDestination;
  final PlaceModel? selectedPlace;
  const MapPage({super.key, this.selectedDestination, this.selectedPlace});

  @override
  Widget build(BuildContext context) {
    final points = selectedPlace != null
        ? [selectedPlace!]
        : (selectedDestination != null
                  ? [selectedDestination!]
                  : kMasterDestinations)
              .map(
                (d) =>
                    PlaceModel(id: d.id, name: d.name, lat: d.lat, lng: d.lng),
              )
              .toList();
    final valid = points.where((place) => place.hasCoordinates).toList();
    final tokens = AdaptiveThemeExtension.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: const NavHubLeading(),
        title: const Text('Destination map'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Take it to the map.',
            style: AppTypography.editorialTitle(color: tokens.editorialBrown),
          ),
          const SizedBox(height: 12),
          const Text(
            'Open the selected coordinates in your maps app. Live routes and travel times are provided there.',
          ),
          if (valid.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Coordinates unavailable'),
            ),
          ...valid.map(
            (place) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: AppTypography.sectionTitle()),
                    Text('${place.lat}, ${place.lng}'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in maps'),
                      onPressed: () async {
                        final uri = Uri.https(
                          'www.google.com',
                          '/maps/search/',
                          {'api': '1', 'query': '${place.lat},${place.lng}'},
                        );
                        var opened = false;
                        try {
                          opened = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          /* Display the coordinates if no maps handler exists. */
                        }
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Maps could not open. Coordinates are shown above.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
