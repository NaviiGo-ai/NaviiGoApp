import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookings/domain/models/saved_place_model.dart';
import '../../../bookings/presentation/providers/saved_places_provider.dart';
import '../../domain/models/place_model.dart';

class PlaceDetailsPage extends ConsumerWidget {
  final PlaceModel place;

  const PlaceDetailsPage({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final savedPlacesAsync = ref.watch(savedPlacesStreamProvider);
    final isSaved =
        savedPlacesAsync.value?.any(
          (p) => p.id == place.id || p.name == place.name,
        ) ??
        false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? AppColors.yellow : Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () async {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please sign in to save places to your bucket list.',
                        ),
                      ),
                    );
                    return;
                  }
                  final repo = ref.read(savedPlacesRepositoryProvider);
                  await repo.toggleSavedPlace(
                    user.uid,
                    SavedPlaceModel(
                      id: place.id,
                      name: place.name,
                      type: place.types.isNotEmpty
                          ? place.types.first
                          : 'Place',
                      image: place.photoUrl ?? '',
                      location: place.vicinity,
                      createdAt: DateTime.now(),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (place.photoUrl != null && place.photoUrl!.isNotEmpty)
                    Hero(
                      tag: 'place-${place.id}',
                      child: Image.network(
                        place.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/brand/india-cover-full.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Image.asset(
                      'assets/brand/india-cover-full.png',
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(60),
                          Colors.transparent,
                          Colors.black.withAlpha(140),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Open status
                  Row(
                    children: [
                      if (place.types.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            place.types.first.toUpperCase().replaceAll(
                              '_',
                              ' ',
                            ),
                            style: AppTypography.eyebrow(
                              color: AppColors.brown,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (place.isOpen != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: place.isOpen!
                                ? AppColors.teal.withAlpha(25)
                                : Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: place.isOpen!
                                    ? AppColors.teal
                                    : Colors.red,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                place.isOpen! ? 'OPEN NOW' : 'CLOSED',
                                style: AppTypography.caption(
                                  color: place.isOpen!
                                      ? AppColors.teal
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Place Title
                  Text(
                    place.name,
                    style: AppTypography.editorialTitle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating & Review Count
                  if (place.rating > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: AppTypography.bodyMedium(
                            color: AppColors.textPrimary,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (place.userRatingsTotal > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${place.userRatingsTotal} reviews)',
                            style: AppTypography.caption(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Address Card
                  if (place.vicinity.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              place.vicinity,
                              style: AppTypography.bodyMedium(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Contact / External details if available
                  if (place.phone != null || place.website != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (place.phone != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.teal,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    place.phone!,
                                    style: AppTypography.bodyMedium(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (place.website != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.language_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    place.website!,
                                    style: AppTypography.bodyMedium(
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              '/trip-planner',
                              extra: {'destination': place.name},
                            );
                          },
                          icon: const Icon(
                            Icons.add_location_alt_outlined,
                            size: 18,
                          ),
                          label: const Text('ADD TO TRIP'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final query = Uri.encodeComponent(
                              '${place.name} ${place.vicinity}'.trim(),
                            );
                            final uri = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=$query',
                            );
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(
                            Icons.directions,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'DIRECTIONS',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
