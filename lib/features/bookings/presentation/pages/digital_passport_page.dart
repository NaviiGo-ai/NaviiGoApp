import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/passport_model.dart';
import '../providers/passport_provider.dart';
import '../providers/saved_places_provider.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';
import '../../../places/domain/models/place_model.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../explore/presentation/widgets/discovery_widgets.dart';

class DigitalPassportPage extends ConsumerWidget {
  const DigitalPassportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(passportStatsStreamProvider);
    final stampsAsync = ref.watch(passportStampsStreamProvider);
    final userTripsAsync = ref.watch(userTripsStreamProvider);
    final savedPlaces = ref.watch(safeSavedPlacesProvider);

    final hasInitialLoading =
        (statsAsync.isLoading && !statsAsync.hasValue) ||
        (stampsAsync.isLoading && !stampsAsync.hasValue) ||
        (userTripsAsync.isLoading && !userTripsAsync.hasValue);
    final hasLoadError =
        statsAsync.hasError || stampsAsync.hasError || userTripsAsync.hasError;

    if (hasInitialLoading) {
      return _buildStateScaffold(
        context,
        title: 'Passport',
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (hasLoadError &&
        !statsAsync.hasValue &&
        !stampsAsync.hasValue &&
        !userTripsAsync.hasValue) {
      return _buildStateScaffold(
        context,
        title: 'Passport',
        child: _buildUnavailableState(context, ref),
      );
    }

    final stamps = stampsAsync.valueOrNull ?? [];
    // Only authoritative lifecycle buckets are eligible for Passport. In
    // particular, cancelled journeys and unconfirmed generation previews are
    // not visits, even if their dates have elapsed or they are present in a
    // retained provider value.
    final pastTrips = ref.watch(pastTripsProvider);
    final upcomingTrips = ref.watch(upcomingTripsProvider);
    final passportJourneyCount = pastTrips.length;
    final passportMomentCount = stamps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'Passport',
          style: AppTypography.editorialTitle(
            color: AppColors.brown,
          ).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.brown,
              size: 22,
            ),
            tooltip: 'Saved Places',
            onPressed: () => context.push('/saved-places'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Travel Archive Editorial Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.brown,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NAVIIGO TRAVEL ARCHIVE',
                        style: AppTypography.eyebrow(
                          color: AppColors.cream,
                        ).copyWith(letterSpacing: 1.5),
                      ),
                      Image.asset(
                        'assets/brand/naviigo-mark-orange.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome,
                          color: AppColors.cream,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your Living Journey Record',
                    style: AppTypography.editorialTitle(
                      color: Colors.white,
                    ).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every city walked, checkpoint reached, and memory captured across India.',
                    style: AppTypography.caption(color: AppColors.cream),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildArchiveStat(
                        '$passportJourneyCount',
                        'COMPLETED JOURNEYS',
                      ),
                      _buildArchiveStat('$passportMomentCount', 'MOMENTS'),
                      _buildArchiveStat(
                        '${savedPlaces.length}',
                        'SAVED PLACES',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasLoadError) ...[
              const SizedBox(height: 10),
              _buildPartialErrorNotice(ref),
            ],
            const SizedBox(height: 28),

            // UPCOMING JOURNEYS
            Text(
              'UPCOMING JOURNEYS',
              style: AppTypography.eyebrow(color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            if (upcomingTrips.isEmpty)
              _buildEmptyUpcomingNotice(context)
            else
              ...upcomingTrips
                  .take(2)
                  .map(
                    (trip) => _buildTripCard(context, trip, isUpcoming: true),
                  ),

            const SizedBox(height: 28),

            // PAST JOURNEYS SHOWCASE
            Text(
              'PAST JOURNEYS',
              style: AppTypography.eyebrow(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            if (pastTrips.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Completed journeys will be archived here with your route and memories.',
                  style: AppTypography.caption(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...pastTrips.map(
                (trip) => _buildTripCard(context, trip, isUpcoming: false),
              ),

            const SizedBox(height: 28),

            // SAVED PLACES QUICK ACCESS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SAVED PLACES',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                GestureDetector(
                  onTap: () => context.push('/saved-places'),
                  child: Text(
                    'View all (${savedPlaces.length})',
                    style: AppTypography.micro(
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (savedPlaces.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.brown,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bookmarks from the Explore Atlas appear here for fast trip additions.',
                        style: AppTypography.caption(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: savedPlaces.length,
                  itemBuilder: (context, idx) {
                    final place = savedPlaces[idx];
                    return GestureDetector(
                      onTap: () {
                        // A saved place is either a top-level curated
                        // destination (Varanasi, Jaipur, ...) or a specific
                        // venue (a restaurant, a monument, a ghat). Each has
                        // its own route; routing a venue into `/destination/:id`
                        // asks the destination page to render a restaurant as
                        // a city.
                        final isCity =
                            findDestinationById(place.id) != null ||
                            place.type.toLowerCase() == 'destination';
                        if (isCity) {
                          context.push('/destination/${place.id}');
                        } else {
                          context.push(
                            '/place-details',
                            extra: PlaceModel(
                              id: place.id,
                              name: place.name,
                              photoUrl: place.image,
                              vicinity: place.location ?? '',
                              types: [place.type],
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DiscoveryImage(
                                image: approvedDestinationImage(
                                  destinationId: place.id,
                                  image: place.image,
                                ),
                                label: place.name,
                                height: 120,
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withAlpha(
                                        (0.85 * 255).round(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  place.name,
                                  style: AppTypography.tripTitle(
                                    color: Colors.white,
                                  ).copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),

            // CAPTURED MOMENTS & CHECK-INS
            Text(
              'MOMENTS & STAMPS',
              style: AppTypography.eyebrow(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            if (stamps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.textTertiary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No moments recorded yet',
                      style: AppTypography.caption(
                        color: AppColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use "Add Moment" in the Live Companion to record travel memories.',
                      style: AppTypography.micro(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...stamps.map((stamp) => _buildStampTile(stamp)),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildStateScaffold(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          title,
          style: AppTypography.editorialTitle(
            color: AppColors.brown,
          ).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: child,
    );
  }

  Widget _buildUnavailableState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              'Passport unavailable',
              style: AppTypography.sectionTitle(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your Passport could not be verified right now. No counts or awards are assumed.',
              style: AppTypography.caption(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                ref.invalidate(passportStatsStreamProvider);
                ref.invalidate(passportStampsStreamProvider);
                ref.invalidate(userTripsStreamProvider);
              },
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartialErrorNotice(WidgetRef ref) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Some Passport data is unavailable. Counts may be incomplete.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withAlpha(75)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.error),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Some Passport data is unavailable. Counts may be incomplete.',
                style: AppTypography.caption(color: AppColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(passportStatsStreamProvider);
                ref.invalidate(passportStampsStreamProvider);
                ref.invalidate(userTripsStreamProvider);
              },
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.sectionTitle(
            color: Colors.white,
          ).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.micro(
            color: AppColors.cream,
          ).copyWith(letterSpacing: 1.0),
        ),
      ],
    );
  }

  Widget _buildEmptyUpcomingNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start a New Chapter',
                  style: AppTypography.tripTitle(color: AppColors.brown),
                ),
                const SizedBox(height: 2),
                Text(
                  'Plan an expedition to add to your archive.',
                  style: AppTypography.caption(),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/trip-planner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'PLAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    TripItineraryModel trip, {
    required bool isUpcoming,
  }) {
    return GestureDetector(
      onTap: () => context.push('/itinerary', extra: trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                trip.heroImage,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 76,
                  height: 76,
                  color: AppColors.surfaceWarm,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.totalDays} DAYS · ${trip.startDateFormatted.toUpperCase()}',
                    style: AppTypography.micro(
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.destName,
                    style: AppTypography.tripTitle(
                      color: AppColors.textPrimary,
                    ).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.dayPlans.length} chapters crafted',
                    style: AppTypography.micro(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampTile(PassportStampModel stamp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 18,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stamp.name}, ${stamp.state}',
                  style: AppTypography.caption(
                    color: AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  stamp.verificationFailure != null
                      ? 'Verification unavailable · ${stamp.verificationFailure}'
                      : stamp.isVerified
                      ? 'Verified visit'
                      : 'Memory · not verified',
                  style: AppTypography.micro(
                    color: stamp.verificationFailure != null
                        ? AppColors.error
                        : stamp.isVerified
                        ? AppColors.teal
                        : AppColors.textTertiary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                if (stamp.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    stamp.location,
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
