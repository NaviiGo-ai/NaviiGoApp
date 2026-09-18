import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_provider.dart';

import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';

import '../../../bookings/presentation/providers/passport_provider.dart';
import '../../../bookings/domain/models/passport_model.dart';
import '../../../places/presentation/providers/places_provider.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/motion/nav_haptics.dart';
import '../../../../core/motion/nav_motion.dart';
import '../../../../core/widgets/journey_line.dart';
import '../../../../core/widgets/no_journey_state.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class OngoingTripsPage extends ConsumerStatefulWidget {
  const OngoingTripsPage({super.key});

  @override
  ConsumerState<OngoingTripsPage> createState() => _OngoingTripsPageState();
}

class _OngoingTripsPageState extends ConsumerState<OngoingTripsPage>
    with SingleTickerProviderStateMixin {
  bool _isBuddySharing = true;
  bool _isAccepting = false;
  final String _buddyName = 'Rohan';
  /// How many stops the traveller has checked into today. Local to this
  /// screen: live progress is not persisted, and nothing here is presented as
  /// saved until the backend confirms it.
  ///
  /// There is deliberately no buddy state. Naviigo has no buddy backend, and
  /// this screen used to assert `LIVE WITH <name> · Coordinates & ETA synced`
  /// from a hard-coded flag — a safety claim backed by nothing. The strip is
  /// gone rather than disabled, because a paused false claim is still a claim.
  int _completedStopsCount = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // §1: the pulse rides the motion ladder rather than inventing a 2s beat.
    _pulseController = AnimationController(
      vsync: this,
      duration: NavMotion.atmospheric,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // §65: the pulse is decorative, so under reduced motion it stops rather
    // than shortening. A slower pulse would still be a pulse.
    if (NavReduce.of(context)) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TripItineraryModel? activeTrip = ref.watch(activeTripProvider);

    if (activeTrip == null) {
      final allTrips = ref.watch(userTripsStreamProvider).value ?? [];
      if (allTrips.isNotEmpty) {
        activeTrip = allTrips.first;
      }
    }

    // No trip means no companion — never invent a journey to fill the screen.
    if (activeTrip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: const NavHubLeading(),
        ),
        body: const NoJourneyState(
          title: 'No Live Journey',
          message:
              'The Live Companion wakes up on the day your journey begins.',
          icon: Icons.route_outlined,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Held at midpoint under reduced motion: the dot still reads
                // as live, it just stops breathing.
                final t = NavReduce.of(context) ? 0.5 : _pulseController.value;
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(
                      (180 + 75 * _pulseController.value).round(),
                    ),
                    color: AppColors.teal.withAlpha((180 + 75 * t).round()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withAlpha(
                          (100 * _pulseController.value).round(),
                        ),
                        color: AppColors.teal.withAlpha((100 * t).round()),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Live Companion',
              style: AppTypography.tripTitle(
                color: AppColors.brown,
              ).copyWith(fontSize: 18),
              style: AppTypography.tripTitle(
                color: AppColors.brown,
              ).copyWith(fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.teal,
              size: 22,
            ),
            tooltip: 'Safety Shield',
            onPressed: () => _openSafetyModal(context),
          ),
        ],
      ),
      body: _buildLiveCompanionContent(context, activeTrip),
    );
  }

  Widget _buildLiveCompanionContent(
    BuildContext context,
    TripItineraryModel trip,
  ) {
  Widget _buildLiveCompanionContent(
    BuildContext context,
    TripItineraryModel trip,
  ) {
    final firstDay = trip.dayPlans.isNotEmpty ? trip.dayPlans.first : null;
    final activities = firstDay?.activities ?? [];
    final totalStops = activities.length;
    final progressPercent = totalStops > 0
        ? (_completedStopsCount / totalStops).clamp(0.0, 1.0)
        : 0.33;

    // The active stop follows the check-ins. It used to be pinned to
    // activities.first, so the "WHAT NOW?" card kept showing stop 1 while the
    // waypoint checklist further down advanced past it — the screen
    // contradicted itself, and "WHAT NEXT?" previewed the wrong stop.
    final int currentIndex = totalStops == 0
        ? 0
        : _completedStopsCount.clamp(0, totalStops - 1);
    final currentActivity = activities.isEmpty
        ? null
        : activities[currentIndex];
    final nextActivity = currentIndex + 1 < activities.length
        ? activities[currentIndex + 1]
        : null;

    // Only the fields the itinerary actually carries. The card used to print
    // "09:00 AM · Heritage Walk · ~1.5 HRS" from hard-coded defaults whenever
    // the activity had no time or category, and the duration was invented
    // regardless of what the planner returned.
    final currentActivityMeta = [
      currentActivity?.time,
      currentActivity?.category,
      currentActivity?.duration,
    ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · ');

    // The same rule for the stop after this one. "WHAT NEXT?" used to print a
    // fixed "15 MIN · 3.2 KM TRANSIT ESTIMATED · AUTO / CAB" — an invented
    // distance, travel time and transport mode, shown before the traveller had
    // even looked at the route.
    final nextActivityMeta = [
      nextActivity?.location,
      nextActivity?.duration,
      nextActivity?.category,
    ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · ');

    // Real weather for this destination, or nothing at all. This banner used
    // to print a hard-coded "28°C · CLEAR". The backend returns
    // {"current": null} when Open-Meteo is unreachable, and that is rendered
    // as absence rather than a guess (§14).
    final masterDest = findDestinationById(trip.destName);
    final weather = masterDest == null
        ? null
        : ref
              .watch(
                destinationWeatherProvider((
                  lat: masterDest.lat,
                  lng: masterDest.lng,
                )),
              )
              .valueOrNull;
    final current = (weather?['current'] as Map?)?.cast<String, dynamic>();
    final temp = current?['temp'];
    final condition = current?['condition'];
    final String? weatherLabel = (temp is num && condition is String)
        ? '${temp.round()}°C · ${condition.toUpperCase()}'
        : null;
    final String weatherEmoji = current?['emoji'] as String? ?? '';

    final now = DateTime.now();
    final timeString =
        '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Orientation & Real-time Context Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPEDITION IN MOTION · DAY 01',
                          style: AppTypography.micro(color: AppColors.primary)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                          style: AppTypography.micro(color: AppColors.primary)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.destName,
                          style: AppTypography.displayHero(
                            color: AppColors.brown,
                          ).copyWith(fontSize: 26, height: 1.15),
                          style: AppTypography.displayHero(
                            color: AppColors.brown,
                          ).copyWith(fontSize: 26, height: 1.15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeString,
                          style: AppTypography.caption(
                            color: AppColors.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                          style: AppTypography.caption(
                            color: AppColors.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wb_sunny_outlined,
                              size: 12,
                              color: AppColors.yellow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '28°C · CLEAR',
                              style: AppTypography.micro(
                                color: AppColors.textTertiary,
                              ).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        // Shown only when the backend actually returned a
                        // reading for these coordinates.
                        if (weatherLabel != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (weatherEmoji.isNotEmpty) ...[
                                Text(
                                  weatherEmoji,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                weatherLabel,
                                style: AppTypography.micro(
                                  color: AppColors.textTertiary,
                                ).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // THE JOURNEY LINE (§6) — the same device the planner and the
                // itinerary use, now in live mode. It reports where the day
                // actually is, so the count is a real checked-in count rather
                // than a percentage.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAY PROGRESS',
                      style: AppTypography.micro(
                        color: AppColors.textTertiary,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 9),
                      style: AppTypography.micro(
                        color: AppColors.textTertiary,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 9),
                    ),
                    Text(
                      '${(progressPercent * 100).toInt()}% COMPLETED',
                      style: AppTypography.micro(
                        color: AppColors.teal,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 10),
                      totalStops == 0
                          ? 'NO WAYPOINTS PLANNED'
                          : '$_completedStopsCount OF $totalStops COMPLETED',
                      style: AppTypography.micro(
                        color: AppColors.teal,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.cream.withAlpha(100),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.teal,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Buddy Live Sharing Strip
          if (_isBuddySharing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.teal.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '● LIVE WITH $_buddyName · Coordinates & ETA synced',
                      style: AppTypography.micro(color: AppColors.teal)
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isBuddySharing = false);
                    },
                    child: Text(
                      'PAUSE',
                      style: AppTypography.micro(
                        color: AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                const SizedBox(height: 8),
                if (totalStops > 1)
                  JourneyLine(
                    totalSteps: totalStops,
                    currentStep: _completedStopsCount.toDouble(),
                    mode: JourneyLineMode.live,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. THE CORE COMPANION MOMENT: "WHAT NOW?"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.brown,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brown.withAlpha(80),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WHAT NOW?',
                        style: AppTypography.micro(color: Colors.white)
                            .copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pin_drop_rounded,
                          size: 14,
                          color: AppColors.yellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ACTIVE WAYPOINT',
                          style: AppTypography.micro(
                            color: AppColors.yellow,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
          // 2. THE CORE COMPANION MOMENT: "WHAT NOW?"
          //
          // Rendered only when the itinerary actually carries a waypoint. It
          // used to fall back to invented copy — "<Destination> Historic
          // Quarter Walk" and a made-up start time — so a journey with no plan
          // still read as scheduled. `dart format` owns the indentation here.
          if (currentActivity != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brown,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(80),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'WHAT NOW?',
                          style: AppTypography.micro(color: Colors.white)
                              .copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pin_drop_rounded,
                            size: 14,
                            color: AppColors.yellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ACTIVE WAYPOINT',
                            style: AppTypography.micro(
                              color: AppColors.yellow,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                Text(
                  currentActivity?.title ??
                      '${trip.destName} Historic Quarter Walk',
                  style: AppTypography.tripTitle(
                    color: Colors.white,
                  ).copyWith(fontSize: 22, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentActivity?.time ?? "09:00 AM"} · ${currentActivity?.category ?? "Heritage Walk"} · ~1.5 HRS',
                  style: AppTypography.caption(color: Colors.white70),
                ),
                if (currentActivity?.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    currentActivity!.description!,
                    style: AppTypography.bodyMedium(
                      color: Colors.white.withAlpha(220),
                    ).copyWith(fontSize: 13, height: 1.4),
                  ),
                ],
                const SizedBox(height: 18),
                  Text(
                    currentActivity.title,
                    style: AppTypography.tripTitle(
                      color: Colors.white,
                    ).copyWith(fontSize: 22, height: 1.2),
                  ),
                  if (currentActivityMeta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      currentActivityMeta,
                      style: AppTypography.caption(color: Colors.white70),
                    ),
                  ],
                  if (currentActivity.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentActivity.description!,
                      style: AppTypography.bodyMedium(
                        color: Colors.white.withAlpha(220),
                      ).copyWith(fontSize: 13, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final target =
                              '${currentActivity?.title ?? trip.destName}, ${trip.destName}';
                          final uri = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(target)}&travelmode=walking',
                          );
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: const Icon(
                          Icons.directions_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('NAVIGATE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          // Analytics: Log Check-in via Repository
                          final uid =
                              ref.read(currentUserProvider)?.uid ?? 'guest';
                          ref
                              .read(tripRepositoryProvider)
                              .checkInActivity(
                                uid,
                                trip,
                                0, // FIXME: real dayIdx
                                0, // FIXME: real actIdx
                              );

                          setState(() {
                            if (_completedStopsCount < totalStops) {
                              _completedStopsCount++;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Waypoint checked in!'),
                              backgroundColor: AppColors.teal,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'CHECK IN',
                          style: AppTypography.button(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white38,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        onPressed: () =>
                            _handleSkip(context, trip, currentActivity),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white24,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'SKIP',
                          style: AppTypography.button(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
                  // Navigation & Check-in Actions
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            NavHaptics.fire(NavHaptic.light);
                            final target =
                                '${currentActivity.title}, ${trip.destName}';
                            final uri = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(target)}&travelmode=walking',
                            );
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(
                            Icons.directions_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text('NAVIGATE NOW'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            NavHaptics.fire(NavHaptic.medium);
                            setState(() {
                              if (_completedStopsCount < totalStops) {
                                _completedStopsCount++;
                              }
                            });
                            // Local to this screen. Nothing has been written to
                            // the Passport, so the toast must not claim it was —
                            // the traveller stamps a moment deliberately, through
                            // "Capture a Moment", which does persist.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stop marked complete.'),
                                backgroundColor: AppColors.teal,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'CHECK IN',
                            style: AppTypography.button(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white38,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // 4. THE COMPANION SECONDARY MOMENT: "WHAT NEXT?"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'WHAT NEXT?',
                        style: AppTypography.micro(color: AppColors.brown)
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          nextActivity?.time ?? '02:30 PM',
                          style: AppTypography.micro(
                            color: AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
          //
          // Only a real next waypoint gets a card. `dart format` owns the
          // indentation of this block.
          if (nextActivity != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'WHAT NEXT?',
                          style: AppTypography.micro(color: AppColors.brown)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                      if (nextActivity.time != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nextActivity.time!,
                              style: AppTypography.micro(
                                color: AppColors.primary,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                Text(
                  nextActivity?.title ?? 'Central Landmark Exploration',
                  style: AppTypography.tripTitle(
                    color: AppColors.textPrimary,
                  ).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '15 MIN · 3.2 KM TRANSIT ESTIMATED · AUTO / CAB',
                  style: AppTypography.micro(
                    color: AppColors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
                  Text(
                    nextActivity.title,
                    style: AppTypography.tripTitle(
                      color: AppColors.textPrimary,
                    ).copyWith(fontSize: 18),
                  ),
                  if (nextActivityMeta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      nextActivityMeta,
                      style: AppTypography.micro(color: AppColors.textSecondary)
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 18),

          // 5. ADD JOURNEY MOMENT ACTION RIBBON
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.brown,
                    size: 22,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.brown,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture a Moment',
                        style: AppTypography.caption(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w800),
                        style: AppTypography.caption(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Attach a photo & note to ${trip.destName}',
                        style: AppTypography.micro(
                          color: AppColors.textSecondary,
                        ),
                        style: AppTypography.micro(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openAddMomentDialog(context, trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ADD MOMENT',
                    style: AppTypography.micro(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5b. ADAPT TRIP (AI REPLANNING) RIBBON
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal.withAlpha(20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.teal.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adapt Trip',
                        style: AppTypography.caption(
                          color: AppColors.teal,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Change of plans? Let AI adjust.',
                        style: AppTypography.micro(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openReplanOptions(context, trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ADAPT',
                    style: AppTypography.micro(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w800),
                    style: AppTypography.micro(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 6. TODAY'S SEQUENCE CHECKLIST
          Text(
            'TODAY’S WAYPOINT SEQUENCE',
            style: AppTypography.eyebrow(color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          ...activities.asMap().entries.map((entry) {
            final idx = entry.key;
            final act = entry.value;
            final isCompleted = idx < _completedStopsCount;
            final isCurrent = idx == _completedStopsCount;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary.withAlpha(120)
                      : AppColors.border,
                  color: isCurrent
                      ? AppColors.primary.withAlpha(120)
                      : AppColors.border,
                  width: isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.teal
                          : (isCurrent
                                ? AppColors.primary
                                : AppColors.surfaceWarm),
                          : (isCurrent
                                ? AppColors.primary
                                : AppColors.surfaceWarm),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted || isCurrent
                            ? Colors.transparent
                            : AppColors.borderStrong,
                        color: isCompleted || isCurrent
                            ? Colors.transparent
                            : AppColors.borderStrong,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      act.title,
                      style: AppTypography.caption(
                        color: AppColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w600),
                      style: AppTypography.caption(
                        color: AppColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    act.time ?? '',
                    style: AppTypography.micro(
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // 7. LOCAL ESSENTIALS (HOSPITAL, PHARMACY, POLICE, 112)
          //
          // Each tile opens a live Maps search around the destination. They
          // used to advertise a hard-coded "1.2 km" / "300m" / "2.0 km" as if
          // Naviigo had measured the distance to the nearest hospital.
          Text(
            'LOCAL ESSENTIALS',
            style: AppTypography.eyebrow(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildEssentialButton(
                Icons.local_hospital_outlined,
                'Hospital',
                '1.2 km',
                trip.destName,
              ),
              _buildEssentialButton(
                Icons.local_hospital_outlined,
                'Hospital',
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.local_pharmacy_outlined,
                'Pharmacy',
                '300m',
                trip.destName,
              ),
              _buildEssentialButton(
                Icons.local_pharmacy_outlined,
                'Pharmacy',
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.local_police_outlined,
                'Police',
                '2.0 km',
                trip.destName,
              ),
              _buildEssentialButton(
                Icons.local_police_outlined,
                'Police',
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.call_outlined,
                'Help 112',
                'Direct',
                trip.destName,
              ),
              _buildEssentialButton(
                Icons.call_outlined,
                'Help 112',
                trip.destName,
              ),
            ],
          ),
          const SizedBox(height: 26),

          // 8. EMERGENCY SOS BUTTON (HOLD FOR SOS)
          Center(
            child: GestureDetector(
              onLongPress: () {
                NavHaptics.fire(NavHaptic.strong);
                _triggerSosFlow(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.error.withAlpha(120),
                    width: 1.5,
                  ),
                  border: Border.all(
                    color: AppColors.error.withAlpha(120),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'HOLD FOR SOS & SAFETY SHIELD',
                      style: AppTypography.button(
                        color: AppColors.error,
                      ).copyWith(fontSize: 12, letterSpacing: 0.8),
                      style: AppTypography.button(
                        color: AppColors.error,
                      ).copyWith(fontSize: 12, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildEssentialButton(
    IconData icon,
    String label,
    String distance,
    String destName,
  ) {
  Widget _buildEssentialButton(IconData icon, String label, String destName) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          NavHaptics.fire(NavHaptic.light);
          if (label == 'Help 112') {
            final uri = Uri.parse('tel:112');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          } else if (label == 'Hospital') {
            final uri = Uri.parse(
              'https://www.google.com/maps/search/hospitals+near+${Uri.encodeComponent(destName)}',
            );
            final uri = Uri.parse(
              'https://www.google.com/maps/search/hospitals+near+${Uri.encodeComponent(destName)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (label == 'Pharmacy') {
            final uri = Uri.parse(
              'https://www.google.com/maps/search/pharmacies+chemist+near+${Uri.encodeComponent(destName)}',
            );
            final uri = Uri.parse(
              'https://www.google.com/maps/search/pharmacies+chemist+near+${Uri.encodeComponent(destName)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (label == 'Police') {
            final uri = Uri.parse(
              'https://www.google.com/maps/search/police+station+near+${Uri.encodeComponent(destName)}',
            );
            final uri = Uri.parse(
              'https://www.google.com/maps/search/police+station+near+${Uri.encodeComponent(destName)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.brown),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.micro(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                distance,
                style: AppTypography.micro(
                  color: AppColors.textTertiary,
                ).copyWith(fontSize: 9),
                style: AppTypography.micro(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReplanOptions(BuildContext context, TripItineraryModel trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adapt Trip',
                style: AppTypography.editorialTitle(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contextual AI replanning for the rest of today.',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildReplanOption(
                ctx,
                trip,
                'RAIN_PLAN',
                'Rain Plan',
                'Switch to indoor activities',
                Icons.umbrella_rounded,
                AppColors.teal,
              ),
              _buildReplanOption(
                ctx,
                trip,
                'I_AM_TIRED',
                "I'm Tired",
                'End the day early and rest',
                Icons.hotel_rounded,
                AppColors.teal,
              ),
              _buildReplanOption(
                ctx,
                trip,
                'TIME_TO_SPARE',
                'Time to Spare',
                'Add something nearby',
                Icons.more_time_rounded,
                AppColors.primary,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplanOption(
    BuildContext ctx,
    TripItineraryModel trip,
    String reason,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        _handleReplanRequest(trip, reason);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.micro(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.borderStrong,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReplanRequest(
    TripItineraryModel trip,
    String reason,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) =>
          const Center(child: CircularProgressIndicator(color: AppColors.teal)),
    );

    try {
      final client = ref.read(apiClientProvider);

      // Calculate current day index
      int currentDayIdx = 0;
      final start = trip.createdAt ?? DateTime.now() ?? DateTime.now();
      final diff = DateTime.now().difference(start).inDays;
      if (diff >= 0 && diff < trip.dayPlans.length) {
        currentDayIdx = diff;
      }

      // Collect completed/skipped IDs from today's plan
      List<String> completedIds = [];
      List<String> skippedIds = [];
      final todayPlan = trip.dayPlans[currentDayIdx];
      for (int i = 0; i < todayPlan.activities.length; i++) {
        final act = todayPlan.activities[i];
        if (i < _completedStopsCount) {
          // Simplistic logic for UI: if it's before current stop, consider it completed
          // In reality we should check analytics state or local state.
          completedIds.add(act.title);
        }
      }

      final res = await client.post(
        '/api/itinerary/replan',
        body: {
          'tripId': trip.id,
          'currentDay': currentDayIdx,
          'currentTime':
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'reason': reason,
          'completedActivityIds': completedIds,
          'skippedActivityIds': skippedIds,
        },
      );

      if (mounted) Navigator.pop(context); // close loader

      if (res['success'] == true && res['proposal'] != null) {
        _showReplanProposal(trip, res['proposal']);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not generate proposal.')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showReplanProposal(
    TripItineraryModel trip,
    Map<String, dynamic> proposal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final actionsList = (proposal['actions'] as List?) ?? [];
        final removed = actionsList
            .where(
              (a) =>
                  a['actionType'] == 'REMOVE' ||
                  a['actionType'] == 'END_DAY_EARLY',
            )
            .toList();
        final moved = actionsList
            .where((a) => a['actionType'] == 'MOVE_TO_LATER_DAY')
            .toList();
        final kept = actionsList
            .where((a) => a['actionType'] == 'KEEP')
            .toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Proposed Changes',
                          style: AppTypography.editorialTitle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    proposal['summary'] ?? 'Review the AI adjustments below.',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (kept.isNotEmpty) ...[
                    Text(
                      'WHAT STAYS',
                      style: AppTypography.eyebrow(color: AppColors.teal),
                    ),
                    const SizedBox(height: 8),
                    ...kept.map(
                      (k) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_circle,
                          color: AppColors.teal,
                        ),
                        title: Text(
                          k['rationale'] ?? 'Kept activity',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (moved.isNotEmpty) ...[
                    Text(
                      'MOVED',
                      style: AppTypography.eyebrow(color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    ...moved.map(
                      (m) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.schedule,
                          color: Colors.orange,
                        ),
                        title: Text(
                          m['rationale'] ?? 'Moved activity',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (removed.isNotEmpty) ...[
                    Text(
                      'REMOVED',
                      style: AppTypography.eyebrow(color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    ...removed.map(
                      (r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.remove_circle,
                          color: AppColors.error,
                        ),
                        title: Text(
                          r['rationale'] ?? 'Removed activity',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondary,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            // Log explicit reject
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'KEEP ORIGINAL',
                            style: AppTypography.caption(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _acceptReplan(trip, proposal);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'ACCEPT CHANGES',
                            style: AppTypography.caption(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptReplan(
    TripItineraryModel trip,
    Map<String, dynamic> proposal,
  ) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) =>
          const Center(child: CircularProgressIndicator(color: AppColors.teal)),
    );

    try {
      final uid = ref.read(currentUserProvider)?.uid ?? 'guest';
      await ref.read(tripRepositoryProvider).acceptReplan(uid, trip, proposal);

      if (mounted) {
        Navigator.pop(context); // loader
        setState(() => _isAccepting = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip updated!')));

      // Refresh trips
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isAccepting = false);
      }

      final errorStr = e.toString();
      if (errorStr.contains('STALE_PROPOSAL')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proposal is stale. Please recalculate.'),
            action: SnackBarAction(
              label: 'RECALCULATE',
              onPressed: () => _handleReplanRequest(trip, 'I_AM_TIRED'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving replan: $e')));
    }
  }

  void _handleSkip(
    BuildContext context,
    TripItineraryModel trip,
    dynamic currentActivity,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why skip this?',
              style: AppTypography.tripTitle(color: AppColors.brown),
            ),
            const SizedBox(height: 16),
            ...[
              'NOT_INTERESTED',
              'TOO_TIRED',
              'TOO_FAR',
              'WEATHER',
              'CLOSED',
              'NO_TIME',
            ].map((reason) {
              return ListTile(
                title: Text(reason.replaceAll('_', ' ')),
                onTap: () {
                  final uid = ref.read(currentUserProvider)?.uid ?? 'guest';
                  // Log analytics via repository
                  ref
                      .read(tripRepositoryProvider)
                      .skipActivity(
                        uid,
                        trip,
                        0, // FIXME: real dayIdx
                        0, // FIXME: real actIdx
                        reason,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Skipped: $reason')));
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openAddMomentDialog(BuildContext context, TripItineraryModel trip) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Capture Journey Moment',
          style: AppTypography.tripTitle(color: AppColors.brown),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach a memory in ${trip.destName}:',
              style: AppTypography.caption(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: AppTypography.bodyMedium(),
              decoration: InputDecoration(
                hintText:
                    'Describe the scents, temple bells, or river breeze...',
                hintText:
                    'Describe the scents, temple bells, or river breeze...',
                hintStyle: AppTypography.caption(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.button(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                final uid = ref.read(currentUserProvider)?.uid ?? 'guest';
                final stamp = PassportStampModel(
                  id: 'stamp_${DateTime.now().millisecondsSinceEpoch}',
                  name: 'Live Moment at ${trip.destName}',
                  location: trip.destName,
                  state: 'India',
                  activities: [noteController.text.trim()],
                  visitedDate: DateTime.now(),
                );
                await ref
                    .read(passportRepositoryProvider)
                    .addPassportStamp(uid, stamp);
                await ref
                    .read(passportRepositoryProvider)
                    .addPassportStamp(uid, stamp);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Moment stamped to your Digital Passport!'),
                      backgroundColor: AppColors.teal,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Save Moment',
              style: TextStyle(color: Colors.white),
            ),
            child: const Text(
              'Save Moment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSosFlow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
                const Icon(
                  Icons.shield_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'EMERGENCY CALL',
                  style: AppTypography.sectionTitle(color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // No dispatch, no coordinate sharing, no notification to anyone.
            // Naviigo has no emergency integration, so this does exactly one
            // thing and says exactly that: it opens the dialer on 112.
            Text(
              'This opens your phone\'s dialer on 112, the national emergency number. Naviigo does not place the call, dispatch help, or share your location with anyone.',
              style: AppTypography.bodyMedium(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:112');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              label: const Text('DIAL 112'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('DISMISS EMERGENCY MODE'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSafetyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety',
              style: AppTypography.tripTitle(color: AppColors.brown),
            ),
            const SizedBox(height: 6),
            // No buddy backend and no stored emergency contacts exist, so the
            // sheet says so. It previously offered a "Buddy Mode" switch that
            // toggled a local bool and claimed "2 contacts registered".
            Text(
              'Naviigo does not share your location, and has no emergency contacts on file for you.',
              style: AppTypography.caption(),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.group_outlined, color: AppColors.teal),
              title: const Text('Buddy Mode Status'),
              subtitle: Text(
                _isBuddySharing ? 'Active with $_buddyName' : 'Disabled',
              ),
              trailing: Switch(
                value: _isBuddySharing,
                activeColor: AppColors.teal,
                onChanged: (val) {
                  setState(() => _isBuddySharing = val);
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.contact_phone_outlined,
                color: AppColors.brown,
              ),
              title: const Text('Emergency Contacts'),
              subtitle: const Text('2 contacts registered'),
              onTap: () => Navigator.pop(ctx),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call_outlined, color: AppColors.error),
              title: const Text('Dial 112'),
              subtitle: const Text('National emergency number'),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:112');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          ],
        ),
      ),
    );
  }
}
