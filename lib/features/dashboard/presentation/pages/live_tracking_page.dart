import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/no_journey_state.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  bool _isSosHolding = false;

  @override
  Widget build(BuildContext context) {
    TripItineraryModel? activeTrip = ref.watch(activeTripProvider);
    if (activeTrip == null) {
      final allTrips = ref.watch(userTripsStreamProvider).value ?? [];
      if (allTrips.isNotEmpty) {
        activeTrip = allTrips.first;
      }
    }

    if (activeTrip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: const NavHubLeading(),
          title: Text(
            'LIVE TRACKING & BUDDY',
            style: AppTypography.eyebrow(color: AppColors.brown),
          ),
          centerTitle: true,
        ),
        body: const NoJourneyState(
          title: 'Tracking Idle',
          message:
              'Live tracking and buddy sharing activate once you have an upcoming or active journey.',
          icon: Icons.location_off_outlined,
        ),
      );
    }

    final trip = activeTrip;
    final nextActivity = _nextActivity(trip);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'LIVE TRACKING & BUDDY',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journey anchor card. Deliberately does not render a map or GPS
            // telemetry until a real location stream is wired up — no invented
            // accuracy, battery or session values.
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cream.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      size: 28,
                      color: AppColors.brown,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    trip.destName,
                    style: AppTypography.editorialTitle(
                      color: AppColors.textPrimary,
                    ).copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      'Live map, waypoints and route guidance appear here once location sharing is enabled.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Destination Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EN ROUTE TO',
                    style: AppTypography.micro(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.destName,
                    style: AppTypography.editorialTitle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  if (nextActivity != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT WAYPOINT',
                                style: AppTypography.micro(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextActivity.title,
                                style: AppTypography.bodyMedium(
                                  color: AppColors.textPrimary,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        if (nextActivity.time != null) ...[
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'SCHEDULED',
                                style: AppTypography.micro(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextActivity.time!,
                                style: AppTypography.bodyMedium(
                                  color: AppColors.primary,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  else
                    Text(
                      'No upcoming waypoints on this itinerary yet.',
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buddy Sharing Mode Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUDDY MODE',
                          style: AppTypography.eyebrow(color: AppColors.teal),
                        ),
                        Text(
                          'No buddy paired yet',
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency SOS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.red, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'EMERGENCY SOS',
                        style: AppTypography.eyebrow(color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Press and hold to open your phone dialer and call emergency services. NaviiGo does not contact anyone on your behalf.',
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onLongPressStart: (_) {
                      setState(() => _isSosHolding = true);
                    },
                    onLongPressEnd: (_) {
                      if (!_isSosHolding) return;
                      setState(() => _isSosHolding = false);
                      _launchEmergencyDialer();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _isSosHolding
                              ? 'RELEASE TO CALL 112'
                              : 'HOLD FOR EMERGENCY CALL',
                          style: AppTypography.button(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// First not-yet-completed activity across the itinerary's day plans.
  TripActivityModel? _nextActivity(TripItineraryModel trip) {
    for (final day in trip.dayPlans) {
      for (final activity in day.activities) {
        if (!activity.isCompleted) return activity;
      }
    }
    return null;
  }

  /// Opens the device dialer for the national emergency number. We only claim
  /// what actually happened — this hands off to the OS, it does not dispatch.
  Future<void> _launchEmergencyDialer() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: '112'));
      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the dialer. Please call 112 directly.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open the dialer. Please call 112 directly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
