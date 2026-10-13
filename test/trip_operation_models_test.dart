import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_operation_models.dart';

void main() {
  group('Phase 6 operation models', () {
    test(
      'receipt requires owner, operation, itinerary and revision identity',
      () {
        final receipt = TripOperationReceipt.fromMap({
          'ownerUid': 'uid-a',
          'itineraryId': 'operation-a',
          'operationId': 'operation-a',
          'revisionId': 'rev_0',
          'status': 'committed',
        });

        expect(
          receipt.matches(
            ownerUid: 'uid-a',
            itineraryId: 'operation-a',
            operationId: 'operation-a',
            revisionId: 'rev_0',
          ),
          isTrue,
        );
        expect(
          () => TripOperationReceipt.fromMap({
            'ownerUid': 'uid-a',
            'itineraryId': 'operation-a',
            'operationId': 'operation-a',
            'revisionId': 'rev_0',
          }),
          throwsFormatException,
        );
      },
    );

    test(
      'replan requests reject unsupported reasons and overlapping progress',
      () {
        expect(
          () => ReplanRequest(
            itineraryId: 'trip-a',
            operationId: 'replan-a',
            baseRevisionId: 'rev_0',
            currentDayNumber: 2,
            currentTime: '15:00',
            reason: 'CHANGE_DESTINATION',
          ),
          throwsFormatException,
        );
        expect(
          () => ReplanRequest(
            itineraryId: 'trip-a',
            operationId: 'replan-a',
            baseRevisionId: 'rev_0',
            currentDayNumber: 2,
            currentTime: '15:00',
            completedActivityIds: const ['activity-a'],
            skippedActivityIds: const ['activity-a'],
          ),
          throwsFormatException,
        );
      },
    );

    test('legacy progress is retained only by stable activity ID', () {
      final trip = TripItineraryModel.fromMap('trip-a', {
        'userId': 'uid-a',
        'revisionId': 'rev_0',
        'dayPlans': [
          {
            'day': 9,
            'activities': [
              {'activityId': 'activity-a', 'title': 'Keep'},
              {'activityId': 'activity-b', 'title': 'Drop'},
            ],
          },
        ],
      });

      expect(trip.canReplan, isTrue);
      expect(
        trip.reconcileManualProgressByActivityId({
          'activity-a': 'completed',
          'day:0:1': 'arrived',
          'missing': 'skipped',
        }),
        {'activity-a': 'completed'},
      );
    });

    test('duplicate or missing activity IDs disable replan identity', () {
      final missing = TripItineraryModel.fromMap('trip-missing', {
        'revisionId': 'rev_0',
        'dayPlans': [
          {
            'day': 1,
            'activities': [
              {'title': 'No ID'},
            ],
          },
        ],
      });
      final duplicate = TripItineraryModel.fromMap('trip-duplicate', {
        'revisionId': 'rev_0',
        'dayPlans': [
          {
            'day': 1,
            'activities': [
              {'activityId': 'same', 'title': 'One'},
              {'activityId': 'same', 'title': 'Two'},
            ],
          },
        ],
      });

      expect(missing.canReplan, isFalse);
      expect(duplicate.canReplan, isFalse);
      expect(
        missing.reconcileManualProgressByActivityId({'0:0': 'arrived'}),
        isEmpty,
      );
    });
  });
}
