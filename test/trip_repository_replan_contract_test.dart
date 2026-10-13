// The SDK's sealed reference types are faked only at the persistence test seam.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/features/trips/data/trip_repository.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  Map<String, dynamic> data = _owner('rev_0');
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.store);
  final _Firestore store;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(store);
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.store);
  final _Firestore store;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(store);
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(store.data);
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic> value;
  @override
  bool get exists => true;
  @override
  String get id => 'trip';
  @override
  Map<String, dynamic> data() => value;
}

class _Api extends ApiClient {
  _Api() : super(baseUrl: 'https://fixture.invalid');
  dynamic response;
  void Function()? onPost;
  Map<String, dynamic>? sent;
  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
    String? expectedAuthUid,
  }) async {
    sent = {'body': body, 'expectedAuthUid': expectedAuthUid};
    onPost?.call();
    return response;
  }
}

Map<String, dynamic> _owner(String revision, {Map<String, dynamic>? receipt}) =>
    {
      'userId': 'alice',
      'ownerUid': 'alice',
      'status': 'active',
      'revisionId': revision,
      if (receipt != null) 'acceptanceReceipts': {'accept-op': receipt},
      'generatedData': {
        'id': 'trip',
        'revisionId': revision,
        'dayPlans': [
          {
            'dayNumber': 9,
            'day': 9,
            'activities': [
              {'activityId': 'activity-a', 'name': 'Fort'},
            ],
          },
        ],
      },
    };
Map<String, dynamic> _receipt() => {
  'status': 'accepted',
  'ownerUid': 'alice',
  'itineraryId': 'trip',
  'proposalId': 'proposal',
  'operationId': 'accept-op',
  'previousRevisionId': 'rev_0',
  'revisionId': 'rev_1',
  'idempotent': false,
};
void main() {
  test(
    'generation replay confirms the saved historical receipt and retains later replans',
    () async {
      final store = _Firestore(), api = _Api();
      final receipt = {
        'status': 'committed',
        'ownerUid': 'alice',
        'itineraryId': 'trip',
        'operationId': 'trip',
        'revisionId': 'rev_0',
      };
      store.data = _owner('rev_2')..['receipt'] = receipt;
      api.response = {
        'success': true,
        'userId': 'alice',
        'receipt': receipt,
        'itinerary': {
          'id': 'trip',
          'dayPlans': [
            {
              'day': 9,
              'activities': [
                {'activityId': 'activity-a', 'name': 'Fort'},
              ],
            },
          ],
        },
      };
      final repo = TripRepository(
        firestore: store,
        apiClient: api,
        currentUserUid: () => 'alice',
      );
      final result = await repo.generateItineraryFromBackend(
        destName: 'Jaipur',
        destination: 'jaipur',
        days: 1,
        operationId: 'trip',
        expectedAuthUid: 'alice',
      );
      expect(result.revisionId, 'rev_2');
      expect(result.isEphemeral, false);
      expect(result.operationReceipt?.revisionId, 'rev_0');
    },
  );
  test(
    'production repository rejects a proposal with a foreign owner',
    () async {
      final store = _Firestore(), api = _Api();
      api.response = {
        'success': true,
        'proposal': {'ownerUid': 'bob'},
      };
      final repo = TripRepository(
        firestore: store,
        apiClient: api,
        currentUserUid: () => 'alice',
      );
      await expectLater(
        repo.requestReplan(
          uid: 'alice',
          itineraryId: 'trip',
          operationId: 'request-op',
          baseRevisionId: 'rev_0',
          currentDayNumber: 9,
          currentTime: '15:00',
        ),
        throwsA(isA<ItineraryGenerationResponseException>()),
      );
      expect(api.sent?['expectedAuthUid'], 'alice');
    },
  );
  test(
    'acceptance requires the proposal and previous revision in its receipt',
    () async {
      for (final missing in ['proposalId', 'previousRevisionId']) {
        final store = _Firestore(), api = _Api();
        final receipt = _receipt()..remove(missing);
        api.response = {'success': true, 'receipt': receipt};
        final repo = TripRepository(
          firestore: store,
          apiClient: api,
          currentUserUid: () => 'alice',
        );
        await expectLater(
          repo.acceptReplan(
            uid: 'alice',
            itineraryId: 'trip',
            proposalId: 'proposal',
            operationId: 'accept-op',
            baseRevisionId: 'rev_0',
          ),
          throwsA(isA<ItineraryGenerationResponseException>()),
        );
        expect(
          (api.sent?['body'] as Map).keys,
          unorderedEquals([
            'itineraryId',
            'proposalId',
            'baseRevisionId',
            'operationId',
          ]),
        );
      }
    },
  );
  test(
    'an accepted operation confirmed in a later revision renders the latest owner trip',
    () async {
      final store = _Firestore(), api = _Api();
      final receipt = _receipt();
      api.response = {'success': true, 'receipt': receipt};
      api.onPost = () => store.data = _owner('rev_2', receipt: receipt);
      final repo = TripRepository(
        firestore: store,
        apiClient: api,
        currentUserUid: () => 'alice',
      );
      final result = await repo.acceptReplan(
        uid: 'alice',
        itineraryId: 'trip',
        proposalId: 'proposal',
        operationId: 'accept-op',
        baseRevisionId: 'rev_0',
      );
      expect(result.idempotent, isTrue);
      expect(result.receipt.revisionId, 'rev_1');
      expect(result.itinerary.revisionId, 'rev_2');
    },
  );
  test(
    'account changes after acceptance discard the old owner response',
    () async {
      final store = _Firestore(), api = _Api();
      var uid = 'alice';
      api.response = {'success': true, 'receipt': _receipt()};
      api.onPost = () => uid = 'bob';
      final repo = TripRepository(
        firestore: store,
        apiClient: api,
        currentUserUid: () => uid,
      );
      await expectLater(
        repo.acceptReplan(
          uid: 'alice',
          itineraryId: 'trip',
          proposalId: 'proposal',
          operationId: 'accept-op',
          baseRevisionId: 'rev_0',
        ),
        throwsA(isA<AuthRequiredException>()),
      );
    },
  );
}
