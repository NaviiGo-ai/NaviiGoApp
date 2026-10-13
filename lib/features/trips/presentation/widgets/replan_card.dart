import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../domain/models/live_trip_state.dart';
import '../../domain/models/trip_operation_models.dart';
import '../providers/live_trip_provider.dart';
import '../providers/replan_provider.dart';
import '../providers/trip_provider.dart';

/// Live Journey's Phase 6 replan surface.
///
/// This widget intentionally renders a proposal review rather than a locally
/// edited itinerary. The owner stream and the acceptance receipt remain the
/// authority; until they are present, the visible current plan is unchanged.
class ReplanCard extends ConsumerWidget {
  final TripItineraryModel trip;
  final LiveTripState liveState;
  final int dayIndex;

  const ReplanCard({
    super.key,
    required this.trip,
    required this.liveState,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerUid = ref.watch(currentUserIdProvider);
    final scope = ReplanScope.fromTrip(ownerUid: ownerUid, trip: trip);
    if (scope == null) {
      return const ReplanUnavailableCard(
        message:
            'Contextual replanning is unavailable for this saved itinerary. '
            'A verified owner and authoritative revision are required. Your current plan remains unchanged.',
      );
    }

    final state = ref.watch(replanControllerProvider(scope));
    final controller = ref.read(replanControllerProvider(scope).notifier);
    final dayNumber = dayIndex >= 0 && dayIndex < trip.dayPlans.length
        ? trip.dayPlans[dayIndex].dayNumber
        : null;
    return _ReplanStateCard(
      state: state,
      controller: controller,
      requestDayNumber: dayNumber,
      liveState: liveState,
      trip: trip,
    );
  }
}

/// Public so another mobile surface can retain the same honest unavailable
/// wording while the repository seam is being integrated.
class ReplanUnavailableCard extends StatelessWidget {
  final String message;

  const ReplanUnavailableCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return _ReplanContainer(
      child: Semantics(
        container: true,
        label: 'Adjust remaining plan. $message',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.tune_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ReplanLabel(
                    'ADJUST REMAINING PLAN',
                    icon: Icons.tune_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplanStateCard extends StatelessWidget {
  final ReplanState state;
  final ReplanController controller;
  final int? requestDayNumber;
  final LiveTripState liveState;
  final TripItineraryModel trip;

  const _ReplanStateCard({
    required this.state,
    required this.controller,
    required this.requestDayNumber,
    required this.liveState,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ReplanStatus.unavailable => ReplanUnavailableCard(
        message:
            state.message ??
            'Contextual replanning is unavailable for this saved itinerary. '
                'Your current plan remains unchanged.',
      ),
      ReplanStatus.idle || ReplanStatus.failed => _RequestCard(
        state: state,
        controller: controller,
        requestDayNumber: requestDayNumber,
        liveState: liveState,
        trip: trip,
      ),
      ReplanStatus.requesting => const _ProgressCard(
        title: 'REQUESTING SERVER OPTIONS',
        message:
            'The server is preparing supported differences. Your current itinerary remains unchanged.',
      ),
      ReplanStatus.review => _ReviewCard(state: state, controller: controller),
      ReplanStatus.accepting => const _ProgressCard(
        title: 'CONFIRMING PLAN UPDATE',
        message:
            'Waiting for an authoritative itinerary and revision receipt. Nothing is rewritten optimistically.',
      ),
      ReplanStatus.accepted => _AcceptedCard(state: state),
      ReplanStatus.stale => _StaleCard(state: state),
      ReplanStatus.ambiguous => _AmbiguousCard(
        state: state,
        controller: controller,
      ),
    };
  }
}

class _RequestCard extends StatelessWidget {
  final ReplanState state;
  final ReplanController controller;
  final int? requestDayNumber;
  final LiveTripState liveState;
  final TripItineraryModel trip;

  const _RequestCard({
    required this.state,
    required this.controller,
    required this.requestDayNumber,
    required this.liveState,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = state.status == ReplanStatus.failed;
    return _ReplanContainer(
      background: hasError
          ? Colors.orange.withAlpha(12)
          : AppColors.surfaceWarm,
      borderColor: hasError ? Colors.orange.withAlpha(75) : AppColors.border,
      child: Semantics(
        container: true,
        label: hasError
            ? 'Adjust remaining plan. ${state.message ?? 'Request failed.'}'
            : 'Adjust remaining plan. Replanning is available only for I am tired.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ReplanLabel(
              'ADJUST REMAINING PLAN',
              icon: Icons.tune_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              'I\'M TIRED',
              style: AppTypography.tripTitle(color: AppColors.brown),
            ),
            const SizedBox(height: 6),
            Text(
              hasError
                  ? state.message ??
                        'Could not request a replan. Your current plan remains unchanged.'
                  : 'Request server-owned options for the remaining journey. '
                        'Review the supported differences before anything is accepted.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.requestProposal(
                  currentDayNumber: requestDayNumber,
                  completedActivityIds: _activityIdsFor(
                    liveState,
                    TripCheckIn.completed,
                  ),
                  skippedActivityIds: _activityIdsFor(
                    liveState,
                    TripCheckIn.skipped,
                  ),
                  location: _locationFor(liveState),
                  destinationTimezone: _destinationTimezoneFor(trip),
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('REQUEST REPLAN'),
                style: _replanButtonStyle(AppColors.brown),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String message;

  const _ProgressCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return _ReplanContainer(
      background: AppColors.surfaceWarm,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: '$title. $message',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReplanLabel(title, icon: Icons.sync_rounded),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReplanState state;
  final ReplanController controller;

  const _ReviewCard({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final proposal = state.proposal;
    if (proposal == null) {
      return const ReplanUnavailableCard(
        message:
            'The proposal could not be reviewed safely. Your current plan remains unchanged.',
      );
    }

    return _ReplanContainer(
      background: AppColors.surfaceWarm,
      borderColor: AppColors.teal.withAlpha(80),
      child: Semantics(
        container: true,
        label:
            'Review proposed remaining plan changes. The current itinerary is unchanged.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ReplanLabel(
              'REVIEW PROPOSED ADJUSTMENT',
              icon: Icons.fact_check_outlined,
              color: AppColors.teal,
            ),
            const SizedBox(height: 8),
            Text(
              'SUPPORTED DIFFERENCES',
              style: AppTypography.micro(
                color: AppColors.textSecondary,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (proposal.actions.isEmpty)
              Text(
                proposal.summary,
                style: AppTypography.caption(color: AppColors.textSecondary),
              )
            else
              ...proposal.actions.map(_ActionRow.new),
            if (proposal.warnings.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'SERVER WARNINGS',
                style: AppTypography.micro(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 4),
              ...proposal.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    warning,
                    style: AppTypography.micro(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'The current itinerary remains unchanged until you accept this server-owned proposal.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.acceptProposal,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('ACCEPT PROPOSAL'),
                style: _replanButtonStyle(AppColors.teal),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: controller.keepCurrentPlan,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('KEEP CURRENT PLAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final ReplanActionModel action;

  const _ActionRow(this.action);

  @override
  Widget build(BuildContext context) {
    final activity = action.activityId?.trim();
    final replacement = action.replacementActivity;
    final replacementTitle = replacement?['title'] ?? replacement?['name'];
    final values = [
      if (activity != null && activity.isNotEmpty) 'Activity $activity',
      if (action.targetDate != null) 'Target ${action.targetDate}',
      if (replacementTitle is String && replacementTitle.trim().isNotEmpty)
        'Replacement ${replacementTitle.trim()}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        label:
            '${action.actionType}. ${values.isEmpty ? action.rationale : values}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.teal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.actionType,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (values.isNotEmpty)
                    Text(
                      values,
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    action.rationale,
                    style: AppTypography.micro(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedCard extends StatelessWidget {
  final ReplanState state;

  const _AcceptedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final revision = state.receipt?.revisionId;
    return _ReplanContainer(
      background: AppColors.teal.withAlpha(12),
      borderColor: AppColors.teal.withAlpha(90),
      child: Semantics(
        container: true,
        liveRegion: true,
        label:
            'Plan update confirmed by the server. An authoritative itinerary was received and the live journey is refreshing.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ReplanLabel(
              'PLAN UPDATE CONFIRMED',
              icon: Icons.verified_outlined,
              color: AppColors.teal,
            ),
            const SizedBox(height: 8),
            Text(
              'The authoritative itinerary was accepted. The owner stream is being refreshed; no optimistic rewrite was applied.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            if (revision != null) ...[
              const SizedBox(height: 8),
              Text(
                'AUTHORITATIVE REVISION · $revision',
                style: AppTypography.micro(color: AppColors.teal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaleCard extends StatelessWidget {
  final ReplanState state;

  const _StaleCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _ReplanNoticeCard(
      title: 'PLAN CHANGED ELSEWHERE',
      icon: Icons.history_toggle_off_rounded,
      message:
          state.message ??
          'This itinerary changed before the proposal could be applied. Refresh the live journey before trying again.',
    );
  }
}

class _AmbiguousCard extends StatelessWidget {
  final ReplanState state;
  final ReplanController controller;

  const _AmbiguousCard({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _ReplanContainer(
      background: Colors.orange.withAlpha(14),
      borderColor: Colors.orange.withAlpha(75),
      child: Semantics(
        container: true,
        liveRegion: true,
        label:
            'Replan result unconfirmed. The current itinerary remains unchanged until the same operation is reconciled.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ReplanLabel(
              'RESULT UNCONFIRMED',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              state.message ??
                  'The replan result is unconfirmed. Retry the same operation to reconcile it.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.retryAmbiguous,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RETRY SAME OPERATION'),
                style: _replanButtonStyle(AppColors.brown),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplanNoticeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _ReplanNoticeCard({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _ReplanContainer(
      background: AppColors.surfaceWarm,
      child: Semantics(
        container: true,
        label: '$title. $message',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brown, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReplanLabel(title, icon: icon),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplanContainer extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Color? borderColor;

  const _ReplanContainer({
    required this.child,
    this.background,
    this.borderColor,
  });

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

class _ReplanLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _ReplanLabel(this.label, {this.icon, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
        ],
        Text(label, style: AppTypography.eyebrow(color: color)),
      ],
    );
  }
}

List<String> _activityIdsFor(LiveTripState state, TripCheckIn checkIn) {
  final ids = <String>[];
  final seen = <String>{};
  for (final waypoint in state.waypoints) {
    if (waypoint.checkIn != checkIn) continue;
    final id = waypoint.activity.activityId?.trim();
    if (id != null && id.isNotEmpty && seen.add(id)) ids.add(id);
  }
  return List<String>.unmodifiable(ids);
}

ReplanLocation? _locationFor(LiveTripState state) {
  final fix = state.fix;
  if (fix == null ||
      !fix.lat.isFinite ||
      !fix.lng.isFinite ||
      fix.lat < -90 ||
      fix.lat > 90 ||
      fix.lng < -180 ||
      fix.lng > 180) {
    return null;
  }
  return ReplanLocation(lat: fix.lat, lng: fix.lng);
}

String _destinationTimezoneFor(TripItineraryModel trip) {
  for (final source in [trip.form, trip.generatedData]) {
    for (final key in const ['destinationTimezone', 'timezone']) {
      final value = source?[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
  }
  // ReplanRequest's shared model uses UTC as its explicit, deterministic
  // fallback when the itinerary carries no destination timezone.
  return 'UTC';
}

ButtonStyle _replanButtonStyle(Color color) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    minimumSize: const Size(48, 48),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
