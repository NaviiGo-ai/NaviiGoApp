import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_operation_models.dart';
import 'package:naviigo_app/features/trips/presentation/providers/live_trip_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/replan_provider.dart';

TripItineraryModel _trip() {
  return TripItineraryModel.fromMap('trip-replan-1', {
    'destId': 'jaipur',
    'destName': 'Jaipur',
    'userId': 'owner-a',
    'status': 'active',
    'isActive': true,
    'revisionId': 'rev-4',
    'dayPlans': [
      {
        'day': 4,
        'activities': [
          {'activityId': 'activity-a', 'title': 'Amber Fort'},
          {'activityId': 'activity-b', 'title': 'City Palace'},
        ],
      },
    ],
  });
}

class _FakeReplanRepository implements ReplanRepository {
  bool available = true;
  int requestCount = 0;
  int acceptCount = 0;
  final List<ReplanRequest> requests = [];
  Object? requestError;
  Object? acceptError;
  Completer<ReplanProposal>? requestCompleter;

  @override
  bool get isAvailable => available;

  @override
  Future<ReplanProposal> requestProposal({
    required String ownerUid,
    required ReplanRequest request,
  }) async {
    requestCount++;
    requests.add(request);
    final error = requestError;
    if (error != null) throw error;
    final completer = requestCompleter;
    if (completer != null) return completer.future;
    return ReplanProposal(
      proposalId: 'proposal-1',
      itineraryId: request.itineraryId,
      operationId: request.operationId,
      baseRevisionId: request.baseRevisionId,
      reason: request.reason,
      summary: 'Keep the current day shorter.',
      actions: const [
        ReplanActionModel(
          actionType: 'REMOVE_ACTIVITY',
          activityId: 'activity-b',
          rationale: 'Reduce the remaining pace.',
        ),
      ],
    );
  }

  @override
  Future<ReplanAcceptanceResult> acceptProposal({
    required String ownerUid,
    required String itineraryId,
    required String operationId,
    required String baseRevisionId,
    required ReplanProposal proposal,
  }) async {
    acceptCount++;
    final error = acceptError;
    if (error != null) {
      acceptError = null;
      throw error;
    }
    final authoritative = _trip().copyWith(revisionId: 'rev-5');
    return ReplanAcceptanceResult(
      itinerary: authoritative,
      receipt: TripOperationReceipt(
        ownerUid: ownerUid,
        itineraryId: itineraryId,
        operationId: operationId,
        revisionId: 'rev-5',
        status: 'accepted',
      ),
    );
  }
}

void main() {
  late _FakeReplanRepository repository;
  late ProviderContainer container;
  late ReplanScope scope;

  setUp(() {
    repository = _FakeReplanRepository();
    scope = ReplanScope.fromTrip(ownerUid: 'owner-a', trip: _trip())!;
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('owner-a'),
        replanRepositoryProvider.overrideWithValue(repository),
        replanOperationIdFactoryProvider.overrideWithValue(() => 'operation-1'),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'does not expose a replan scope for legacy or ambiguous activity IDs',
    () {
      final legacy = _trip().copyWith(
        revisionId: 'rev-4',
        dayPlans: [
          const TripDayPlanModel(
            dayNumber: 4,
            activities: [TripActivityModel(title: 'Name only')],
          ),
        ],
      );
      expect(ReplanScope.fromTrip(ownerUid: 'owner-a', trip: legacy), isNull);
      expect(ReplanScope.fromTrip(ownerUid: 'owner-b', trip: _trip()), isNull);
    },
  );

  test('binds request to stable day, IDs, owner and one operation', () async {
    final completer = Completer<ReplanProposal>();
    repository.requestCompleter = completer;
    final controller = container.read(replanControllerProvider(scope).notifier);

    final first = controller.requestProposal(
      currentDayNumber: 4,
      currentTime: '2026-10-13T09:00:00Z',
      completedActivityIds: const ['activity-a'],
      skippedActivityIds: const ['activity-b'],
    );
    await Future<void>.delayed(Duration.zero);
    final second = controller.requestProposal(
      currentDayNumber: 4,
      completedActivityIds: const ['activity-a'],
      skippedActivityIds: const ['activity-b'],
    );

    expect(repository.requestCount, 1);
    expect(
      container.read(replanControllerProvider(scope)).status,
      ReplanStatus.requesting,
    );
    completer.complete(
      ReplanProposal(
        proposalId: 'proposal-1',
        itineraryId: 'trip-replan-1',
        operationId: 'operation-1',
        baseRevisionId: 'rev-4',
        reason: 'I_AM_TIRED',
        summary: 'Keep the current day shorter.',
      ),
    );
    await first;
    await second;

    final request = repository.requests.single;
    expect(request.itineraryId, 'trip-replan-1');
    expect(request.operationId, 'operation-1');
    expect(request.baseRevisionId, 'rev-4');
    expect(request.currentDayNumber, 4);
    expect(request.completedActivityIds, ['activity-a']);
    expect(request.skippedActivityIds, ['activity-b']);
    expect(
      container.read(replanControllerProvider(scope)).status,
      ReplanStatus.review,
    );
  });

  test(
    'acceptance requires authoritative itinerary and matching receipt',
    () async {
      final controller = container.read(
        replanControllerProvider(scope).notifier,
      );
      await controller.requestProposal(currentDayNumber: 4);
      final before = _trip();

      await controller.acceptProposal();

      final state = container.read(replanControllerProvider(scope));
      expect(state.status, ReplanStatus.accepted);
      expect(state.receipt?.revisionId, 'rev-5');
      expect(state.authoritativeItinerary?.revisionId, 'rev-5');
      expect(before.revisionId, 'rev-4');
      expect(repository.acceptCount, 1);
    },
  );

  test(
    'ambiguous acceptance stays unconfirmed and retries the same operation',
    () async {
      final controller = container.read(
        replanControllerProvider(scope).notifier,
      );
      await controller.requestProposal(currentDayNumber: 4);
      repository.acceptError = const ReplanAmbiguousException();

      await controller.acceptProposal();
      expect(
        container.read(replanControllerProvider(scope)).status,
        ReplanStatus.ambiguous,
      );

      await controller.retryAmbiguous();
      expect(
        container.read(replanControllerProvider(scope)).status,
        ReplanStatus.accepted,
      );
      expect(repository.acceptCount, 2);
    },
  );

  test('stale rejection never presents a proposal as reviewable', () async {
    repository.requestError = const ReplanStaleException();
    final controller = container.read(replanControllerProvider(scope).notifier);

    await controller.requestProposal(currentDayNumber: 4);

    final state = container.read(replanControllerProvider(scope));
    expect(state.status, ReplanStatus.stale);
    expect(state.proposal, isNull);
  });
}
