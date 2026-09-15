import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';

class HeroDestinationCard extends ConsumerWidget {
  const HeroDestinationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(activeTripProvider);
    final upcomingTrips = ref.watch(upcomingTripsProvider);
    final pastTrips = ref.watch(pastTripsProvider);
    final userAsync = ref.watch(userProfileStreamProvider);

    final String userName =
        userAsync.valueOrNull?.displayName?.split(' ').first ?? 'Traveller';

    // State C: Active Trip
    if (activeTrip != null) {
      return _buildActiveTripCard(context, activeTrip);
    }
    // State B: Planning / Upcoming Trip
    if (upcomingTrips.isNotEmpty) {
      return _buildUpcomingTripCard(context, upcomingTrips.first);
    }
    // State D: Post-Trip Recap
    if (pastTrips.isNotEmpty) {
      return _buildPostTripCard(context, pastTrips.first, userName);
    }
    // State A: New / Discovery State
    return _buildDiscoveryCard(context, userName);
  }

  // ─────────────────────────────────────────────────────────
  // STATE C: ACTIVE TRIP COMPANION
  // ─────────────────────────────────────────────────────────
  Widget _buildActiveTripCard(BuildContext context, TripItineraryModel trip) {
    final currentDayIndex = trip.dayPlans.isNotEmpty ? 1 : 1;
    final firstActivity =
        trip.dayPlans.isNotEmpty && trip.dayPlans.first.activities.isNotEmpty
        ? trip.dayPlans.first.activities.first
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE JOURNEY IN MOTION',
                style: AppTypography.eyebrow(color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Day 0$currentDayIndex · ${trip.destName}',
            style: AppTypography.editorialTitle(
              color: AppColors.brown,
            ).copyWith(fontSize: 26),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(trip.heroImage),
                fit: BoxFit.cover,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((0.15 * 255).round()),
                    Colors.black.withAlpha((0.85 * 255).round()),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEXT STOP',
                      style: AppTypography.micro(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    firstActivity?.title ?? trip.destName,
                    style: AppTypography.sectionTitle(
                      color: Colors.white,
                    ).copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (firstActivity != null && firstActivity.time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${firstActivity.time} · ${firstActivity.category ?? "Activity"}',
                      style: AppTypography.caption(color: AppColors.cream),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/ongoing-trips'),
                        icon: const Icon(
                          Icons.navigation_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('OPEN LIVE COMPANION'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () =>
                            context.push('/itinerary', extra: trip),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Route Map'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STATE B: UPCOMING / PLANNING JOURNEY
  // ─────────────────────────────────────────────────────────
  Widget _buildUpcomingTripCard(BuildContext context, TripItineraryModel trip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'YOUR NEXT JOURNEY',
                style: AppTypography.eyebrow(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            trip.destName,
            style: AppTypography.editorialTitle(
              color: AppColors.brown,
            ).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(trip.heroImage),
                fit: BoxFit.cover,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((0.15 * 255).round()),
                    Colors.black.withAlpha((0.85 * 255).round()),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${trip.totalDays} DAYS · ${trip.startDateFormatted.toUpperCase()}',
                      style: AppTypography.micro(
                        color: AppColors.brown,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${trip.dayPlans.length} Daily Chapters Ready',
                    style: AppTypography.sectionTitle(
                      color: Colors.white,
                    ).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/itinerary', extra: trip),
                    icon: const Icon(
                      Icons.route_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('CONTINUE PLANNING'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STATE D: POST-TRIP MEMORY RECAP
  // ─────────────────────────────────────────────────────────
  Widget _buildPostTripCard(
    BuildContext context,
    TripItineraryModel trip,
    String userName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WELCOME BACK, ${userName.toUpperCase()}',
            style: AppTypography.eyebrow(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Recap Your Journey',
            style: AppTypography.editorialTitle(
              color: AppColors.brown,
            ).copyWith(fontSize: 26),
          ),
          const SizedBox(height: 12),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(trip.heroImage),
                fit: BoxFit.cover,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((0.2 * 255).round()),
                    Colors.black.withAlpha((0.85 * 255).round()),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${trip.destName} · ${trip.totalDays} Days',
                    style: AppTypography.caption(color: AppColors.cream),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Turn your travel moments into a story',
                    style: AppTypography.sectionTitle(
                      color: Colors.white,
                    ).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/story-creator'),
                        icon: const Icon(
                          Icons.movie_creation_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('CREATE STORY'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.push('/digital-passport'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Passport'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STATE A: DISCOVERY-FIRST / NO ACTIVE TRIP
  // ─────────────────────────────────────────────────────────
  Widget _buildDiscoveryCard(BuildContext context, String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'GOOD MORNING, ${userName.toUpperCase()}',
                style: AppTypography.eyebrow(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Where will curiosity\ntake you?',
            style: AppTypography.displayHero(
              color: AppColors.brown,
            ).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 14),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/brand/india-cover-full.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((0.15 * 255).round()),
                    Colors.black.withAlpha((0.85 * 255).round()),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FEATURED JOURNEY · VARANASI',
                      style: AppTypography.micro(
                        color: AppColors.brown,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sacred Ghats & Twilight Chants',
                    style: AppTypography.sectionTitle(
                      color: Colors.white,
                    ).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/trip-planner'),
                        icon: const Icon(
                          Icons.navigation_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('PLAN A TRIP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.push('/explore-discover'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Explore Atlas'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
