import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';
import '../../../bookings/presentation/providers/passport_provider.dart';
import '../../../bookings/domain/models/passport_model.dart';
import '../../../../core/auth/auth_provider.dart';
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
  final String _buddyName = 'Rohan';
  int _completedStopsCount = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(
                      (180 + 75 * _pulseController.value).round(),
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withAlpha(
                          (100 * _pulseController.value).round(),
                        ),
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
    final currentActivity = activities.isNotEmpty ? activities.first : null;
    final nextActivity = activities.length > 1 ? activities[1] : null;

    final totalStops = activities.length;
    final progressPercent = totalStops > 0
        ? (_completedStopsCount / totalStops).clamp(0.0, 1.0)
        : 0.33;

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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Live Progress Track
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
                      '${(progressPercent * 100).toInt()}% COMPLETED',
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

                // Navigation & Check-in Actions
                Row(
                  children: [
                    Expanded(
                      flex: 3,
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
                          HapticFeedback.mediumImpact();
                          setState(() {
                            if (_completedStopsCount < totalStops) {
                              _completedStopsCount++;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Waypoint stamped into your Passport!',
                              ),
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
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.local_pharmacy_outlined,
                'Pharmacy',
                '300m',
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.local_police_outlined,
                'Police',
                '2.0 km',
                trip.destName,
              ),
              const SizedBox(width: 8),
              _buildEssentialButton(
                Icons.call_outlined,
                'Help 112',
                'Direct',
                trip.destName,
              ),
            ],
          ),
          const SizedBox(height: 26),

          // 8. EMERGENCY SOS BUTTON (HOLD FOR SOS)
          Center(
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.heavyImpact();
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

  Widget _buildEssentialButton(
    IconData icon,
    String label,
    String distance,
    String destName,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          HapticFeedback.lightImpact();
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
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                distance,
                style: AppTypography.micro(
                  color: AppColors.textTertiary,
                ).copyWith(fontSize: 9),
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
                  'EMERGENCY MODE ACTIVE',
                  style: AppTypography.sectionTitle(color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sharing temporary live coordinates with emergency contacts and Indian National Tourist Helpline.',
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
              label: const Text('CALL EMERGENCY SERVICES (112)'),
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
              child: const Text('DISMISS EMERGENCY MODE'),
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
              'Safety & Buddy Center',
              style: AppTypography.tripTitle(color: AppColors.brown),
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
            ),
          ],
        ),
      ),
    );
  }
}
