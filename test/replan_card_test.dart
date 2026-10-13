import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/live_trip_state.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_operation_models.dart';
import 'package:naviigo_app/features/trips/presentation/providers/live_trip_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/replan_provider.dart';
import 'package:naviigo_app/features/trips/presentation/widgets/replan_card.dart';

TripItineraryModel _trip({bool withRevision = true}) {
  return TripItineraryModel.fromMap('trip-card-1', {
    'destId': 'jaipur',
    'destName': 'Jaipur',
    'userId': 'owner-a',
    'status': 'active',
    'isActive': true,
    if (withRevision) 'revisionId': 'rev-1',
    'dayPlans': [
      {
        'day': 4,
        'activities': [
          {'activityId': 'a-1', 'title': 'Amber Fort'},
        ],
      },
    ],
  });
}

class _FakeRepository implements ReplanRepository {
  @override
  bool get isAvailable => true;

  @override
  Future<ReplanProposal> requestProposal({
    required String ownerUid,
    required ReplanRequest request,
  }) async {
    return ReplanProposal(
      proposalId: 'proposal-card',
      itineraryId: request.itineraryId,
      operationId: request.operationId,
      baseRevisionId: request.baseRevisionId,
      reason: request.reason,
      summary: 'A shorter remaining route is available.',
      actions: const [
        ReplanActionModel(
          actionType: 'SHORTEN_DAY',
          rationale: 'Remove one remaining stop.',
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
    return ReplanAcceptanceResult(
      itinerary: _trip().copyWith(revisionId: 'rev-2'),
      receipt: TripOperationReceipt(
        ownerUid: ownerUid,
        itineraryId: itineraryId,
        operationId: operationId,
        revisionId: 'rev-2',
        status: 'accepted',
      ),
    );
  }
}

Widget _harness(TripItineraryModel trip) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('owner-a'),
      replanRepositoryProvider.overrideWithValue(_FakeRepository()),
      replanOperationIdFactoryProvider.overrideWithValue(() => 'card-op'),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReplanCard(
            trip: trip,
            liveState: LiveTripState(trip: trip),
            dayIndex: 0,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('requests and reviews supported server differences', (
    tester,
  ) async {
    final trip = _trip();
    await tester.pumpWidget(_harness(trip));
    await tester.pumpAndSettle();

    expect(find.text('I\'M TIRED'), findsOneWidget);
    await tester.tap(find.text('REQUEST REPLAN'));
    await tester.pumpAndSettle();

    expect(find.text('REVIEW PROPOSED ADJUSTMENT'), findsOneWidget);
    expect(find.text('SUPPORTED DIFFERENCES'), findsOneWidget);
    expect(find.text('SHORTEN_DAY'), findsOneWidget);
    expect(find.text('ACCEPT PROPOSAL'), findsOneWidget);
  });

  testWidgets('legacy unrevisioned trips keep replan unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(_trip(withRevision: false)));
    await tester.pumpAndSettle();

    expect(find.text('ADJUST REMAINING PLAN'), findsOneWidget);
    expect(find.textContaining('replanning is unavailable'), findsOneWidget);
    expect(find.text('REQUEST REPLAN'), findsNothing);
  });
}
