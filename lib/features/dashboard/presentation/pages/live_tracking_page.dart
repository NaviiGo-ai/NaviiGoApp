import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/motion/nav_haptics.dart';
import '../../../../core/widgets/no_journey_state.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/models/booking_model.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/presentation/providers/live_trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';
import '../../../trips/domain/models/live_trip_state.dart';
import '../../../trips/domain/services/trip_validation_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LIVE JOURNEY
/// Section order is fixed: NOW / NEXT / ROUTE / BOOKINGS / BUDDY / LOCAL /
/// SAFETY. Everything rendered here is either a fact the traveller supplied, a
/// value the server wrote, or a measurement from a real fix. Where a signal is
/// missing the screen says so — it never fills the gap with invented telemetry.
/// ─────────────────────────────────────────────────────────────────────────────
class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({super.key, this.initialTrip});

  /// The journey the traveller arrived here to begin or follow. Passed by
  /// screens that already know which itinerary was tapped, so the start gate
  /// always judges that journey rather than whichever happens to be first.
  final TripItineraryModel? initialTrip;

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  bool _isSosHolding = false;

  /// Set by the "Pre-Trip Mode" recovery action — the traveller is not going to
  /// start today, so the screen stops offering to begin the journey.
  bool _isPreTripMode = false;

  @override
  Widget build(BuildContext context) {
    TripItineraryModel? trip = ref.watch(activeTripProvider);
    trip ??= widget.initialTrip;
    if (trip == null) {
      final allTrips = ref.watch(userTripsStreamProvider).value ?? [];
      if (allTrips.isNotEmpty) {
        trip = allTrips.first;
      }
    }

    if (trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _appBar(),
        body: const NoJourneyState(
          title: 'Tracking Idle',
          message:
              'Live tracking activates once you have an upcoming or active journey.',
          icon: Icons.location_off_outlined,
        ),
      );
    }

    final state = ref.watch(liveTripStateProvider(trip));
    final controller = ref.read(liveTripControllerProvider(trip.id).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JourneyHeader(trip: trip, state: state),
            const SizedBox(height: 16),

            if (state.lastActionError != null) ...[
              _ActionNotice(
                message: state.lastActionError!,
                onDismiss: controller.clearCommandError,
              ),
              const SizedBox(height: 16),
            ],

            // ── Start gate, or the journey itself ──────────────────────────
            if (state.phase == LiveTripPhase.atStart ||
                state.phase == LiveTripPhase.wrongCity ||
                state.phase == LiveTripPhase.preTrip)
              _StartGate(
                trip: trip,
                state: state,
                controller: controller,
                isPreTripMode: _isPreTripMode,
                onEnterPreTripMode: () {
                  NavHaptics.fire(NavHaptic.light);
                  setState(() => _isPreTripMode = true);
                },
                onLeavePreTripMode: () {
                  NavHaptics.fire(NavHaptic.light);
                  setState(() => _isPreTripMode = false);
                },
              )
            else if (state.phase == LiveTripPhase.inMotion) ...[
              // ── ROUTE ──────────────────────────────────────────────────
              if (state.isOffRoute) ...[
                _RouteDeviationNotice(state: state),
                const SizedBox(height: 16),
              ],
              _RoutePreviewCard(trip: trip, state: state),
              const SizedBox(height: 20),
              // ── NOW ────────────────────────────────────────────────────
              _NowCard(state: state, controller: controller),
              const SizedBox(height: 16),
              // ── NEXT ───────────────────────────────────────────────────
              _NextCard(state: state),
            ] else
              _JourneyClosedCard(state: state),

            const SizedBox(height: 20),

            // ── ROUTE (full rail) ────────────────────────────────────────
            _RouteRailCard(state: state),
            const SizedBox(height: 20),

            // ── BOOKINGS ─────────────────────────────────────────────────
            _BookingsCard(trip: trip),

            // ── BUDDY ────────────────────────────────────────────────────
            const _BuddyCard(),

            // ── LOCAL ────────────────────────────────────────────────────
            _LocalEssentialsCard(trip: trip),

            // ── SAFETY ───────────────────────────────────────────────────
            _SafetyCard(
              state: state,
              isSosHolding: _isSosHolding,
              onHoldStart: () => setState(() => _isSosHolding = true),
              onHoldEnd: () {
                if (!_isSosHolding) return;
                setState(() => _isSosHolding = false);
                _launchEmergencyDialer();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const NavHubLeading(),
      title: Text(
        'LIVE JOURNEY',
        style: AppTypography.eyebrow(color: AppColors.brown),
      ),
      centerTitle: true,
    );
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

/// ─────────────────────────────────────────────────────────────────────────────
/// SHARED PIECES
/// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Color? borderColor;

  const _SectionCard({required this.child, this.background, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const _SectionLabel(this.label, {this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
        ],
        Text(label, style: AppTypography.eyebrow(color: tint)),
      ],
    );
  }
}

/// A chip that only ever states something we can back with a real value.
class _FactChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FactChip({
    required this.label,
    required this.icon,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.micro(
              color: color,
            ).copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// HEADER — destination, lifecycle status, real sync state
/// ─────────────────────────────────────────────────────────────────────────────
class _JourneyHeader extends StatelessWidget {
  final TripItineraryModel trip;
  final LiveTripState state;

  const _JourneyHeader({required this.trip, required this.state});

  Color get _statusColor {
    switch (state.status) {
      case TripStatus.active:
        return AppColors.teal;
      case TripStatus.eligibleToStart:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.textTertiary;
      case TripStatus.cancelled:
        return Colors.red;
      default:
        return AppColors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trip.destName,
          style: AppTypography.editorialTitle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          '${trip.startDateFormatted} · ${trip.totalDays} days',
          style: AppTypography.caption(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FactChip(
              label: state.status.label.toUpperCase(),
              icon: Icons.timeline_rounded,
              color: _statusColor,
            ),
            // Offline is only ever shown from a real failed read or write.
            if (state.isOffline)
              const _FactChip(
                label: 'OFFLINE',
                icon: Icons.cloud_off_rounded,
                color: Colors.orange,
              ),
            _FactChip(
              label: state.lastUpdatedLabel.toUpperCase(),
              icon: state.isOffline
                  ? Icons.history_rounded
                  : Icons.sync_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionNotice extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ActionNotice({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption(color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ROUTE DEVIATION
/// States a measurement, not an alarm. We know the distance from the journey's
/// region; we do not know the traveller's intent.
/// ─────────────────────────────────────────────────────────────────────────────
class _RouteDeviationNotice extends StatelessWidget {
  final LiveTripState state;

  const _RouteDeviationNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    final region = state.trip?.startRegionName ?? 'the journey';
    final distance = state.startCheck?.distanceLabel ?? '';
    final measured = state.distanceFromStartRegionKm;
    final label = measured == null ? distance : '${measured.round()} km';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yellow.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellow.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.alt_route_rounded, size: 20, color: AppColors.brown),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OFF THE PLANNED REGION',
                  style: AppTypography.micro(
                    color: AppColors.brown,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your last fix is $label from $region. If that is intentional, '
                  'carry on — nothing is shared automatically.',
                  style: AppTypography.caption(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// START GATE — at the start, wrong city, or pre-trip
/// ─────────────────────────────────────────────────────────────────────────────
class _StartGate extends StatelessWidget {
  final TripItineraryModel trip;
  final LiveTripState state;
  final LiveTripController controller;
  final bool isPreTripMode;
  final VoidCallback onEnterPreTripMode;
  final VoidCallback onLeavePreTripMode;

  const _StartGate({
    required this.trip,
    required this.state,
    required this.controller,
    required this.isPreTripMode,
    required this.onEnterPreTripMode,
    required this.onLeavePreTripMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isPreTripMode) return _buildPreTripMode(context);

    final check = state.startCheck;
    final status = check?.status;

    // Another journey is under way. The traveller resolves that first — the app
    // never ends a journey on its own.
    if (status == StartTripStatus.conflictWithActiveTrip) {
      return _buildConflict(context);
    }

    final isAtStart = state.phase == LiveTripPhase.atStart;
    final isWrongCity = status == StartTripStatus.wrongCity;

    // A location problem is not a wrong-city problem: the headline, the reason
    // and the recovery all differ. Blurring them would leave the traveller with
    // no idea what to fix.
    final headline = switch (status) {
      StartTripStatus.valid => 'YOU ARE AT THE START',
      StartTripStatus.wrongCity => 'NOT AT THE START YET',
      StartTripStatus.permissionDenied => 'LOCATION NOT VERIFIED',
      StartTripStatus.permissionPermanentlyDenied ||
      StartTripStatus.locationRestricted => 'LOCATION IS BLOCKED',
      StartTripStatus.servicesDisabled => 'LOCATION IS TURNED OFF',
      StartTripStatus.locationTimeout ||
      StartTripStatus.staleFix ||
      StartTripStatus.inaccurateGps => "COULDN'T GET A RELIABLE LOCATION",
      StartTripStatus.dateMismatch => 'TOO EARLY TO START',
      _ => 'NOT AT THE START YET',
    };

    return _SectionCard(
      background: isAtStart ? AppColors.teal.withAlpha(14) : AppColors.surface,
      borderColor: isAtStart ? AppColors.teal.withAlpha(80) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            headline,
            color: isAtStart ? AppColors.teal : AppColors.brown,
            icon: isAtStart
                ? Icons.check_circle_outline_rounded
                : Icons.wrong_location_outlined,
          ),
          const SizedBox(height: 10),

          if (isAtStart)
            Text(
              'You are within ${check?.distanceLabel ?? 'the start region'} of '
              '${trip.startRegionName}. Start the journey when you are ready.',
              style: AppTypography.caption(color: AppColors.textPrimary),
            )
          else ...[
            if (isWrongCity)
              Text(
                check?.expectedDestinationName != null
                    ? 'This journey begins in ${check!.expectedDestinationName}.'
                    : 'This journey cannot be started right now.',
                style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            if (isWrongCity) const SizedBox(height: 6),
            Text(
              // The reason comes straight from the gate that failed — never a
              // generic "cannot start".
              _reasonFor(status, check?.message),
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
          ],

          if (check?.hasDistance == true && !isAtStart) ...[
            const SizedBox(height: 12),
            _FactChip(
              label:
                  '${check!.distanceLabel.toUpperCase()} FROM '
                  '${trip.startRegionName.toUpperCase()}',
              icon: Icons.straighten_rounded,
              color: AppColors.brown,
            ),
          ],

          const SizedBox(height: 18),

          // Primary action — different for every gate.
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: _primaryLabel(status, isAtStart),
              icon: _primaryIcon(status, isAtStart),
              color: isAtStart ? AppColors.teal : AppColors.brown,
              isBusy: isAtStart
                  ? state.isStartingTrip
                  : state.isResolvingLocation,
              onTap: state.isStartingTrip || state.isResolvingLocation
                  ? null
                  : () => _runPrimary(context, status, isAtStart),
            ),
          ),

          const SizedBox(height: 14),
          Text(
            'OTHER OPTIONS',
            style: AppTypography.micro(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),

          // Only a genuine wrong-city has somewhere to navigate to.
          if (isWrongCity)
            _RecoveryRow(
              label: 'Get Directions',
              icon: Icons.directions_rounded,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                _openDirections(context, trip);
              },
            ),
          _RecoveryRow(
            label: 'View Trip',
            icon: Icons.menu_book_rounded,
            onTap: () {
              NavHaptics.fire(NavHaptic.light);
              context.push('/itinerary', extra: trip);
            },
          ),
          _RecoveryRow(
            label: 'Pre-Trip Mode',
            icon: Icons.event_note_rounded,
            onTap: onEnterPreTripMode,
          ),
        ],
      ),
    );
  }

  /// The reason, in Naviigo's voice. Permission gets its own rationale rather
  /// than a permission constant.
  static String _reasonFor(StartTripStatus? status, String? gateMessage) {
    if (status == StartTripStatus.permissionDenied) {
      return 'Naviigo uses your location to make sure you are near the beginning '
          'of this journey before Live Trip starts.';
    }
    return gateMessage ?? 'Waiting for location.';
  }

  static String _primaryLabel(StartTripStatus? status, bool isAtStart) {
    if (isAtStart) return 'START JOURNEY';
    return switch (status) {
      StartTripStatus.servicesDisabled => 'OPEN LOCATION SETTINGS',
      StartTripStatus.permissionPermanentlyDenied ||
      StartTripStatus.locationRestricted => 'OPEN SETTINGS',
      StartTripStatus.permissionDenied => 'VERIFY YOUR START',
      _ => 'TRY LOCATION AGAIN',
    };
  }

  static IconData _primaryIcon(StartTripStatus? status, bool isAtStart) {
    if (isAtStart) return Icons.play_arrow_rounded;
    return switch (status) {
      StartTripStatus.servicesDisabled ||
      StartTripStatus.permissionPermanentlyDenied ||
      StartTripStatus.locationRestricted => Icons.settings_outlined,
      _ => Icons.my_location_rounded,
    };
  }

  Future<void> _runPrimary(
    BuildContext context,
    StartTripStatus? status,
    bool isAtStart,
  ) async {
    if (isAtStart) {
      NavHaptics.fire(NavHaptic.medium);
      await controller.startTrip(trip);
      return;
    }

    NavHaptics.fire(NavHaptic.light);
    switch (status) {
      case StartTripStatus.servicesDisabled:
        await _openSettings(context, deviceSettings: true);
      case StartTripStatus.permissionPermanentlyDenied:
      case StartTripStatus.locationRestricted:
        await _openSettings(context, deviceSettings: false);
      default:
        await controller.refreshLocation();
    }
  }

  /// Hand off to the OS. Only ever reached from an explicit action.
  Future<void> _openSettings(
    BuildContext context, {
    required bool deviceSettings,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = deviceSettings
        ? await controller.openLocationSettings()
        : await controller.openAppSettings();
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open settings on this device.'),
        ),
      );
    }
  }

  /// Two journeys must not run at once, and the app will not end one behind the
  /// traveller's back — they pick.
  Widget _buildConflict(BuildContext context) {
    final other = state.conflictingTrip;

    return _SectionCard(
      background: AppColors.surfaceWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            'A JOURNEY IS ALREADY UNDER WAY',
            icon: Icons.timelapse_rounded,
          ),
          const SizedBox(height: 10),
          Text(
            other == null
                ? 'You already have a journey under way.'
                : '${other.destName} is in progress. Finish or end it before '
                      'starting this one.',
            style: AppTypography.bodyMedium(
              color: AppColors.textPrimary,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Only one journey can be in motion at a time.',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'VIEW ACTIVE TRIP',
              icon: Icons.near_me_rounded,
              color: AppColors.teal,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                context.push('/live-tracking');
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'OTHER OPTIONS',
            style: AppTypography.micro(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          if (other != null)
            _RecoveryRow(
              label: 'End Current Trip',
              icon: Icons.stop_circle_outlined,
              onTap: () {
                NavHaptics.fire(NavHaptic.medium);
                controller.endTrip(other);
              },
            ),
          _RecoveryRow(
            label: 'Cancel',
            icon: Icons.close_rounded,
            onTap: () {
              NavHaptics.fire(NavHaptic.light);
              onLeavePreTripMode();
            },
          ),
        ],
      ),
    );
  }

  /// The traveller is not starting now. Show the plan and the honest state of
  /// the journey — no countdown theatre, no invented readiness.
  Widget _buildPreTripMode(BuildContext context) {
    final start = trip.parsedStartDate;
    final daysAway = start == null
        ? null
        : DateTime(start.year, start.month, start.day)
              .difference(
                DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
              )
              .inDays;

    return _SectionCard(
      background: AppColors.surfaceWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('PRE-TRIP MODE', icon: Icons.event_note_rounded),
          const SizedBox(height: 10),
          Text(
            trip.destName,
            style: AppTypography.tripTitle(color: AppColors.brown),
          ),
          const SizedBox(height: 6),
          Text(
            daysAway == null
                ? 'Departure: ${trip.startDateFormatted}'
                : daysAway > 0
                ? 'Departs in $daysAway ${daysAway == 1 ? 'day' : 'days'} · '
                      '${trip.startDateFormatted}'
                : 'Departure: ${trip.startDateFormatted}',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            '${state.totalWaypoints} waypoints · ${trip.totalDays} days',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'VIEW TRIP',
              icon: Icons.arrow_forward_rounded,
              color: AppColors.brown,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                context.push('/itinerary', extra: trip);
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: onLeavePreTripMode,
              child: Text(
                'Back to start checks',
                style: AppTypography.caption(
                  color: AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RecoveryRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isBusy;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: onTap == null ? color.withAlpha(120) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.button(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ROUTE — preview + expand to the full waypoint rail
/// ─────────────────────────────────────────────────────────────────────────────
class _RoutePreviewCard extends StatelessWidget {
  final TripItineraryModel trip;
  final LiveTripState state;

  const _RoutePreviewCard({required this.trip, required this.state});

  @override
  Widget build(BuildContext context) {
    final now = state.nowWaypoint;
    final next = state.nextWaypoint;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('ROUTE', icon: Icons.route_rounded),
              GestureDetector(
                onTap: () {
                  NavHaptics.fire(NavHaptic.light);
                  _showRouteSheet(context, state);
                },
                child: Text(
                  'EXPAND',
                  style: AppTypography.micro(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Compact rail: the real sequence of waypoints, current one marked.
          Row(
            children: [
              for (int i = 0; i < state.waypoints.length && i < 6; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: state.waypoints[i].isLogged
                          ? AppColors.teal
                          : (state.waypoints[i].key == now?.key
                                ? AppColors.primary
                                : AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            '${state.loggedCount} of ${state.totalWaypoints} waypoints logged',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          if (next != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next: ${next.activity.title}',
              style: AppTypography.caption(
                color: AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'OPEN ROUTE IN MAPS',
              icon: Icons.map_outlined,
              color: AppColors.brown,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                _openDirections(context, trip);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// NOW — the waypoint under the traveller's feet, with manual check-in
/// ─────────────────────────────────────────────────────────────────────────────
class _NowCard extends StatelessWidget {
  final LiveTripState state;
  final LiveTripController controller;

  const _NowCard({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final now = state.nowWaypoint;

    if (now == null) {
      return _SectionCard(
        background: AppColors.teal.withAlpha(14),
        borderColor: AppColors.teal.withAlpha(80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(
              'NOW',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.teal,
            ),
            const SizedBox(height: 10),
            Text(
              'Every waypoint is logged. Nothing else is scheduled.',
              style: AppTypography.bodyMedium(color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    final confidence = state.arrivalConfidence;
    final confidenceColor = confidence == ArrivalConfidence.confirmed
        ? AppColors.teal
        : confidence == ArrivalConfidence.inferred
        ? AppColors.primary
        : AppColors.textTertiary;

    return _SectionCard(
      borderColor: AppColors.primary.withAlpha(70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('NOW', icon: Icons.my_location_rounded),
              _FactChip(
                label: confidence.label.toUpperCase(),
                icon: confidence == ArrivalConfidence.confirmed
                    ? Icons.verified_rounded
                    : Icons.blur_on_rounded,
                color: confidenceColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            now.activity.title,
            style: AppTypography.tripTitle(color: AppColors.brown),
          ),
          const SizedBox(height: 6),
          Text(
            [
              'Day ${now.dayNumber}',
              if (now.activity.time != null) now.activity.time!,
              if (now.activity.location != null) now.activity.location!,
              if (now.activity.duration != null) now.activity.duration!,
            ].join(' · '),
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          if (now.activity.description != null) ...[
            const SizedBox(height: 10),
            Text(
              now.activity.description!,
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),

          // Manual check-in — the only record of what actually happened.
          Text(
            'CHECK IN',
            style: AppTypography.micro(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CheckInButton(
                  label: now.checkIn == TripCheckIn.arrived
                      ? 'HERE ✓'
                      : "I'M HERE",
                  color: AppColors.primary,
                  isActive: now.checkIn == TripCheckIn.arrived,
                  onTap: () {
                    NavHaptics.fire(NavHaptic.light);
                    controller.logCheckIn(now.key, TripCheckIn.arrived);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CheckInButton(
                  label: 'COMPLETE',
                  color: AppColors.teal,
                  isActive: now.checkIn == TripCheckIn.completed,
                  onTap: () {
                    NavHaptics.fire(NavHaptic.medium);
                    controller.logCheckIn(now.key, TripCheckIn.completed);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CheckInButton(
                  label: 'SKIP',
                  color: AppColors.textTertiary,
                  isActive: now.checkIn == TripCheckIn.skipped,
                  onTap: () {
                    NavHaptics.fire(NavHaptic.light);
                    controller.logCheckIn(now.key, TripCheckIn.skipped);
                  },
                ),
              ),
            ],
          ),
          if (now.checkIn != TripCheckIn.pending) ...[
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () {
                  NavHaptics.fire(NavHaptic.light);
                  controller.clearCheckIn(now.key);
                },
                child: Text(
                  'Undo check-in',
                  style: AppTypography.caption(
                    color: AppColors.textSecondary,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _CheckInButton({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(isActive ? 255 : 70)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.micro(
              color: isActive ? Colors.white : color,
            ).copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// NEXT
/// ─────────────────────────────────────────────────────────────────────────────
class _NextCard extends StatelessWidget {
  final LiveTripState state;

  const _NextCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final next = state.nextWaypoint;

    return _SectionCard(
      background: AppColors.surfaceWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            'NEXT',
            icon: Icons.skip_next_rounded,
            color: AppColors.teal,
          ),
          const SizedBox(height: 10),
          if (next == null)
            Text(
              'Nothing after this one.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            )
          else ...[
            Text(
              next.activity.title,
              style: AppTypography.bodyMedium(
                color: AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              [
                'Day ${next.dayNumber}',
                if (next.activity.time != null) next.activity.time!,
                if (next.activity.location != null) next.activity.location!,
              ].join(' · '),
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ROUTE RAIL — every waypoint with how it was resolved
/// ─────────────────────────────────────────────────────────────────────────────
class _RouteRailCard extends StatelessWidget {
  final LiveTripState state;

  const _RouteRailCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final waypoints = state.waypoints;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('ROUTE', icon: Icons.route_rounded),
              Text(
                '${state.loggedCount}/${state.totalWaypoints}',
                style: AppTypography.micro(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (waypoints.isEmpty)
            Text(
              'This journey has no waypoints yet.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            )
          else
            for (int i = 0; i < waypoints.length; i++)
              _RailRow(
                waypoint: waypoints[i],
                isLast: i == waypoints.length - 1,
              ),
          if (state.skippedCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '${state.skippedCount} skipped — logged as skipped, not completed.',
              style: AppTypography.micro(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  final LiveWaypoint waypoint;
  final bool isLast;

  const _RailRow({required this.waypoint, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final checkIn = waypoint.checkIn;
    final color = checkIn == TripCheckIn.completed
        ? AppColors.teal
        : checkIn == TripCheckIn.skipped
        ? AppColors.textTertiary
        : checkIn == TripCheckIn.arrived
        ? AppColors.primary
        : AppColors.border;

    final icon = checkIn == TripCheckIn.completed
        ? Icons.check_rounded
        : checkIn == TripCheckIn.skipped
        ? Icons.remove_rounded
        : checkIn == TripCheckIn.arrived
        ? Icons.my_location_rounded
        : Icons.circle_outlined;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.4),
                ),
                child: Icon(icon, size: 11, color: color),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1.4, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waypoint.activity.title,
                    style:
                        AppTypography.bodyMedium(
                          color: checkIn == TripCheckIn.skipped
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: checkIn == TripCheckIn.skipped
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Day ${waypoint.dayNumber} · ${checkIn.label}',
                    style: AppTypography.micro(color: AppColors.textTertiary),
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

/// ─────────────────────────────────────────────────────────────────────────────
/// BOOKINGS — real vouchers for this destination only
/// ─────────────────────────────────────────────────────────────────────────────
class _BookingsCard extends ConsumerWidget {
  final TripItineraryModel trip;

  const _BookingsCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsStreamProvider).value ?? const [];

    // Vouchers carry airport/station codes, so match on the curated registry's
    // identifiers as well as the destination id.
    final destination = findDestinationById(trip.destId);
    final codes = <String>{
      trip.destId.toUpperCase(),
      if (destination != null) ...[
        destination.iata.toUpperCase(),
        destination.station.toUpperCase(),
        destination.name.toUpperCase(),
      ],
    };

    final relevant = bookings
        .where(
          (b) =>
              codes.contains(b.to.toUpperCase()) ||
              codes.contains(b.from.toUpperCase()),
        )
        .toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(
                'BOOKINGS',
                icon: Icons.confirmation_number_outlined,
              ),
              Text(
                '${relevant.length}',
                style: AppTypography.micro(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (relevant.isEmpty)
            Text(
              'No vouchers for ${trip.startRegionName} yet.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            )
          else
            for (final BookingModel booking in relevant.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _bookingIcon(booking.type),
                        size: 16,
                        color: AppColors.brown,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${booking.from} → ${booking.to}',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${booking.providerName} · ${booking.date}',
                            style: AppTypography.micro(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _FactChip(
                      label: booking.status.toUpperCase(),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.teal,
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              NavHaptics.fire(NavHaptic.light);
              context.push('/bookings');
            },
            child: Text(
              'ALL BOOKINGS',
              style: AppTypography.micro(
                color: AppColors.primary,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _bookingIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'train':
        return Icons.train_rounded;
      case 'cab':
        return Icons.local_taxi_rounded;
      default:
        return Icons.confirmation_number_outlined;
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// BUDDY — honest: nobody is paired, and we say exactly that
/// ─────────────────────────────────────────────────────────────────────────────
class _BuddyCard extends StatelessWidget {
  const _BuddyCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      background: AppColors.surfaceWarm,
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
                  'BUDDY',
                  style: AppTypography.eyebrow(color: AppColors.teal),
                ),
                Text(
                  'No buddy paired. Nobody is following this journey.',
                  style: AppTypography.caption(color: AppColors.textSecondary),
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
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// LOCAL — hand-offs to the device's maps app. No invented nearby places.
/// ─────────────────────────────────────────────────────────────────────────────
class _LocalEssentialsCard extends StatelessWidget {
  final TripItineraryModel trip;

  const _LocalEssentialsCard({required this.trip});

  static const _searches = <String, IconData>{
    'Nearest hospital': Icons.local_hospital_outlined,
    'Nearest pharmacy': Icons.medical_services_outlined,
    'Nearest police station': Icons.local_police_outlined,
    'Nearest ATM': Icons.local_atm_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('LOCAL', icon: Icons.explore_outlined),
          const SizedBox(height: 6),
          Text(
            'Opens your maps app and searches near the journey region. '
            'NaviiGo does not cache or rank these places.',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          for (final entry in _searches.entries)
            _RecoveryRow(
              label: entry.key,
              icon: entry.value,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                _searchNearby(context, trip, entry.key);
              },
            ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SAFETY
/// ─────────────────────────────────────────────────────────────────────────────
class _SafetyCard extends StatelessWidget {
  final LiveTripState state;
  final bool isSosHolding;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _SafetyCard({
    required this.state,
    required this.isSosHolding,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    final region = state.trip?.startRegionName ?? 'your region';
    final fix = state.fix;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            'SAFETY',
            icon: Icons.shield_outlined,
            color: Colors.red,
          ),
          const SizedBox(height: 10),
          Text(
            'Press and hold to open your phone dialer and call emergency '
            'services. NaviiGo does not contact anyone on your behalf.',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Only shown when a real fix exists — stating position otherwise
          // would be a guess.
          if (fix != null)
            _FactChip(
              label: fix.accuracyMeters == null
                  ? 'POSITION ON FILE'
                  : 'POSITION ±${fix.accuracyMeters!.round()} M',
              icon: Icons.gps_fixed_rounded,
            )
          else
            const _FactChip(
              label: 'NO POSITION FIX',
              icon: Icons.gps_off_rounded,
              color: Colors.orange,
            ),

          const SizedBox(height: 6),
          Text(
            'Nearest emergency response: 112 (India-wide). Region: $region.',
            style: AppTypography.micro(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPressStart: (_) => onHoldStart(),
            onLongPressEnd: (_) => onHoldEnd(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isSosHolding ? 'RELEASE TO CALL 112' : 'HOLD FOR 112',
                  style: AppTypography.button(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyClosedCard extends StatelessWidget {
  final LiveTripState state;

  const _JourneyClosedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isCancelled = state.phase == LiveTripPhase.cancelled;
    return _SectionCard(
      background: AppColors.surfaceWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            isCancelled ? 'JOURNEY CANCELLED' : 'JOURNEY COMPLETE',
            icon: isCancelled
                ? Icons.cancel_outlined
                : Icons.flag_circle_outlined,
            color: isCancelled ? Colors.red : AppColors.teal,
          ),
          const SizedBox(height: 10),
          Text(
            isCancelled
                ? 'This journey was cancelled. Nothing is being tracked.'
                : '${state.completedCount} of ${state.totalWaypoints} waypoints '
                      'logged as completed.',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// HAND-OFFS
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> _openDirections(
  BuildContext context,
  TripItineraryModel trip,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final lat = trip.startLat;
  final lng = trip.startLng;
  final uri = (lat != null && lng != null)
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        )
      : Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trip.startRegionName)}',
        );

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No maps app available on this device.')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open a maps app.')),
    );
  }
}

Future<void> _searchNearby(
  BuildContext context,
  TripItineraryModel trip,
  String query,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query='
    '${Uri.encodeComponent('$query near ${trip.startRegionName}')}',
  );
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No maps app available on this device.')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open a maps app.')),
    );
  }
}

void _showRouteSheet(BuildContext context, LiveTripState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FULL ROUTE',
              style: AppTypography.eyebrow(color: AppColors.brown),
            ),
            const SizedBox(height: 4),
            Text(
              '${state.loggedCount} of ${state.totalWaypoints} waypoints logged',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  for (final waypoint in state.waypoints)
                    _RailRow(
                      waypoint: waypoint,
                      isLast: waypoint == state.waypoints.last,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
