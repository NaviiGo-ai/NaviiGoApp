import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  bool _isBuddyActive = true;
  final String _buddyName = 'Rohan';
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

    final destName = activeTrip?.destName ?? 'Current Waypoint';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'LIVE TRACKING & BUDDY',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 3, backgroundColor: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE',
                  style: AppTypography.micro(color: AppColors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radar Map Card with Warm Editorial Styling
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stylized topographic rings
                  ...[60.0, 110.0, 160.0, 210.0].map((radius) {
                    return Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(20),
                          width: 1,
                        ),
                      ),
                    );
                  }),

                  // User location indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // GPS telemetry overlay
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 12,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'High Precision • 12m accuracy',
                            style: AppTypography.micro(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.battery_charging_full,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Battery Saver On',
                            style: AppTypography.micro(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EN ROUTE TO',
                        style: AppTypography.micro(color: AppColors.primary),
                      ),
                      Text(
                        'SESSION #NV-4092',
                        style: AppTypography.micro(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    destName,
                    style: AppTypography.editorialTitle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                            'Historic City Gate',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EST. TIME',
                            style: AppTypography.micro(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '18 Mins',
                            style: AppTypography.bodyMedium(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                              style: AppTypography.eyebrow(
                                color: AppColors.teal,
                              ),
                            ),
                            Text(
                              _isBuddyActive
                                  ? 'Sharing live location with $_buddyName'
                                  : 'Location sharing inactive',
                              style: AppTypography.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isBuddyActive,
                        activeColor: AppColors.teal,
                        onChanged: (val) {
                          setState(() => _isBuddyActive = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? 'Live tracking shared with $_buddyName'
                                    : 'Buddy tracking stopped.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Hold-for-SOS
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
                    'Press and hold for 3 seconds to trigger emergency broadcast to your trusted buddies and emergency contact.',
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onLongPressStart: (_) {
                      setState(() {
                        _isSosHolding = true;
                      });
                    },
                    onLongPressEnd: (_) {
                      if (_isSosHolding) {
                        setState(() {
                          _isSosHolding = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'EMERGENCY BROADCAST SENT TO TRUSTED CONTACTS.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                              ? 'TRANSMITTING...'
                              : 'HOLD 3S FOR EMERGENCY',
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
}
