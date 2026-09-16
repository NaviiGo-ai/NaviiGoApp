import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../bookings/presentation/providers/saved_places_provider.dart';
import '../../../bookings/domain/models/saved_place_model.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class RestaurantDetailsPage extends ConsumerWidget {
  final String id;
  const RestaurantDetailsPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Curated regional dining profiles for Naviigo Explorer
    final title = id == '2' ? '1135 AD, Amer' : 'Baradari Heritage Dining';
    final vicinity = id == '2'
        ? 'Amer Palace Complex, Jaipur, Rajasthan'
        : 'City Palace Courtyard, Jaipur, Rajasthan';
    final cuisine = id == '2'
        ? 'Royal Rajasthani & Mughlai'
        : 'Heritage Continental & Indian Contemporary';
    final rating = id == '2' ? 4.9 : 4.8;
    final reviewsCount = id == '2' ? 840 : 1240;
    final description = id == '2'
        ? 'Perched high within the ancient ramparts of Amer Fort, 1135 AD serves royal Rajput banquets with silver thalis, hand-painted murals, and candlelit courtyard acoustics.'
        : 'Set inside the historic City Palace of Jaipur, Baradari combines centuries-old Mughal arches with contemporary artisanal dining, celebrating seasonal produce of Rajasthan.';

    final specialities = id == '2'
        ? [
            {
              'name': 'Laal Maas',
              'desc': 'Fiery slow-braised mutton in Mathania red chilies.',
            },
            {
              'name': 'Dal Baati Churma',
              'desc':
                  'Wood-fired wheat baatis drenched in pure ghee with spiced lentils.',
            },
            {
              'name': 'Shahi Tukda',
              'desc':
                  'Crisp saffron bread pudding infused with cardamom and rabri.',
            },
          ]
        : [
            {
              'name': 'Kachori Chaat Tart',
              'desc':
                  'Deconstructed Rajasthani street kachori with mint emulsion.',
            },
            {
              'name': 'Smoked Paneer Tikka',
              'desc':
                  'Cottage cheese charred over mesquite with wild pomegranate chutney.',
            },
            {
              'name': 'Ghevar Mille-Feuille',
              'desc': 'Honeycomb pastry with pistachio mousse and silver leaf.',
            },
          ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const NavHubLeading(iconColor: AppColors.brown),
        title: Text(
          'HERITAGE DINING',
          style: AppTypography.editorialTitle(
            color: AppColors.brown,
          ).copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_add_outlined,
              color: AppColors.brown,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final user = ref.read(currentUserProvider);
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please sign in to save dining places to your bucket list.',
                    ),
                  ),
                );
                return;
              }

              final place = SavedPlaceModel(
                id: 'rest_$id',
                name: title,
                type: 'Dining',
                location: vicinity,
                createdAt: DateTime.now(),
              );

              await ref
                  .read(savedPlacesRepositoryProvider)
                  .toggleSavedPlace(user.uid, place);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $title to your Saved Places'),
                    backgroundColor: AppColors.teal,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmCream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cuisine.toUpperCase(),
                          style: AppTypography.micro(color: AppColors.brown),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.yellow,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.caption(
                          color: AppColors.brown,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewsCount reviews)',
                        style: AppTypography.micro(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTypography.editorialTitle(
                      color: AppColors.brown,
                    ).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vicinity,
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'About this Table',
                    style: AppTypography.caption(
                      color: AppColors.brown,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTypography.bodySmall(
                      color: AppColors.textPrimary,
                    ).copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Signature Dishes
            Text(
              'Signature Offerings',
              style: AppTypography.tripTitle(color: AppColors.brown),
            ),
            const SizedBox(height: 12),
            ...specialities.map(
              (dish) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dish['name']!,
                            style: AppTypography.caption(
                              color: AppColors.brown,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dish['desc']!,
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final uri = Uri.parse('tel:+911412530135');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        final webSearchUri = Uri.parse(
                          'https://www.google.com/search?q=${Uri.encodeComponent('$title $vicinity contact number')}',
                        );
                        await launchUrl(
                          webSearchUri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brown,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(
                      'Call Restaurant',
                      style: AppTypography.button(color: AppColors.brown),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final query = Uri.encodeComponent(
                        '$title $vicinity'.trim(),
                      );
                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$query',
                      );
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: Text(
                      'Directions',
                      style: AppTypography.button(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
