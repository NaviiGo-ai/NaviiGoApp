import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
                    color: AppColors.teal.withAlpha((180 + 75 * t).round()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
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
    final firstDay = trip.dayPlans.isNotEmpty ? trip.dayPlans.first : null;
    final activities = firstDay?.activities ?? [];
    final totalStops = activities.length;

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
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.destName,
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
                        ),
                        const SizedBox(height: 2),
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
                    ),
                    Text(
                      totalStops == 0
                          ? 'NO WAYPOINTS PLANNED'
                          : '$_completedStopsCount OF $totalStops COMPLETED',
                      style: AppTypography.micro(
                        color: AppColors.teal,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ],
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
                      ),
                      Text(
                        'Attach a photo & note to ${trip.destName}',
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
                      shape: BoxShape.circle,
                      border: Border.all(
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
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
                    ),
                  ),
                  Text(
                    act.time ?? '',
                    style: AppTypography.micro(
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
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.local_pharmacy_outlined,
                'Pharmacy',
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.local_police_outlined,
                'Police',
                trip.destName,
              ),
              const SizedBox(width: 8),
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
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(24),
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
                    const SizedBox(width: 10),
                    Text(
                      'HOLD FOR SOS & SAFETY SHIELD',
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
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (label == 'Pharmacy') {
            final uri = Uri.parse(
              'https://www.google.com/maps/search/pharmacies+chemist+near+${Uri.encodeComponent(destName)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (label == 'Police') {
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
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 9),
              ),
            ],
          ),
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
