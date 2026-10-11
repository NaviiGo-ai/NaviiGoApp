import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/features/trips/data/trip_repository.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(baseUrl: 'https://itinerary.test');

  final requests = <Map<String, dynamic>>[];
  dynamic response;
  Object? failure;
  Completer<void>? gate;

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
    String? expectedAuthUid,
  }) async {
    requests.add({
      'path': path,
      'body': body,
      'requiresAuth': requiresAuth,
      'timeout': timeout,
      'expectedAuthUid': expectedAuthUid,
    });
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    return response;
  }
}

class _UnusedFirestore extends Fake implements FirebaseFirestore {}

Map<String, dynamic> _validResponse() {
  return {
    'success': true,
    'source': 'generated',
    'userId': 'uid-a',
    'itinerary': {
      'id': 'backend-id',
      'uuid': 'backend-uuid',
      'generationMetadata': {'provider': 'gemini'},
      'warnings': ['Weather unavailable'],
      'costSummary': {'currency': 'INR'},
      'dayPlans': [
        {
          'day': 1,
          'activities': [
            {'title': 'Sunrise walk'},
          ],
        },
      ],
    },
  };
}

Map<String, dynamic> _responseWithoutOptionalIds() {
  return {
    'success': true,
    'source': 'generated',
    'dataSources': ['destination-cache'],
    'userId': 'uid-a',
    'itinerary': {
      'dayPlans': [
        {
          'day': 1,
          'activities': [
            {
              'title': 'Sunrise walk',
              'time': null,
              'duration': null,
              'location': null,
            },
          ],
        },
      ],
    },
  };
}

Future<TripRepository> _repository(
  _RecordingApiClient api, {
  String uid = 'uid-a',
  String? Function()? currentUserUid,
}) async {
  return TripRepository(
    firestore: _UnusedFirestore(),
    apiClient: api,
    currentUserUid: currentUserUid ?? (() => uid),
  );
}

void main() {
  test(
    'generation sends the exact request and initiating expectedAuthUid',
    () async {
      final api = _RecordingApiClient()..response = _validResponse();
      final repository = await _repository(api);

      final trip = await repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        destination: 'varanasi',
        days: 3,
        purpose: 'cultural',
        group: 'solo',
        budget: 25000,
        startDate: '2026-10-15',
        travelerType: 'comfort',
        expectedAuthUid: 'uid-a',
      );

      final request = api.requests.single;
      expect(request['path'], '/api/itinerary/generate');
      expect(request['requiresAuth'], isTrue);
      expect(request['expectedAuthUid'], 'uid-a');
      expect(request['body'], {
        'destName': 'Varanasi',
        'destination': 'varanasi',
        'purpose': 'cultural',
        'group': 'solo',
        'days': 3,
        'budget': 25000,
        'startDate': '2026-10-15',
        'travelerType': 'comfort',
      });
      expect(trip.id, 'backend-id');
      expect(trip.uuid, 'backend-uuid');
      expect(trip.userId, 'uid-a');
      expect(trip.isEphemeral, isTrue);
      expect(trip.dayPlans.single.activities.single.title, 'Sunrise walk');
    },
  );

  test(
    'malformed or empty day plans are rejected without inventing data',
    () async {
      final api = _RecordingApiClient()
        ..response = {
          'success': true,
          'itinerary': {'dayPlans': []},
        };
      final repository = await _repository(api);

      await expectLater(
        repository.generateItineraryFromBackend(
          destName: 'Varanasi',
          days: 1,
          expectedAuthUid: 'uid-a',
        ),
        throwsA(isA<ItineraryGenerationResponseException>()),
      );
    },
  );

  test(
    'omits missing optional request fields and preserves supported preferences',
    () async {
      final api = _RecordingApiClient()..response = _validResponse();
      final repository = await _repository(api);

      final trip = await repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        budget: 0,
        travelerType: 'flash',
        preferences: {
          'interests': ['Heritage', 'Food'],
          'dietary': 'halal',
        },
        expectedAuthUid: 'uid-a',
      );

      final body = api.requests.single['body'] as Map<String, dynamic>;
      expect(body['travelerType'], 'flash');
      expect(body['preferences'], {
        'interests': ['Heritage', 'Food'],
        'dietary': 'halal',
      });
      expect(body.containsKey('destination'), isFalse);
      expect(body.containsKey('startDate'), isFalse);
      expect(trip.destId, 'varanasi');
    },
  );

  test('rejects invalid repository inputs before making a request', () async {
    final api = _RecordingApiClient()..response = _validResponse();
    final repository = await _repository(api);

    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Unknown place',
        days: 1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        budget: -1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(api.requests, isEmpty);
  });

  test(
    'rejects nested activity names instead of stringifying arbitrary maps',
    () async {
      final api = _RecordingApiClient()
        ..response = {
          'success': true,
          'userId': 'uid-a',
          'itinerary': {
            'dayPlans': [
              {
                'activities': [
                  {'title': <String, dynamic>{}},
                ],
              },
            ],
          },
        };
      final repository = await _repository(api);

      await expectLater(
        repository.generateItineraryFromBackend(
          destName: 'Varanasi',
          days: 1,
          expectedAuthUid: 'uid-a',
        ),
        throwsA(isA<ItineraryGenerationResponseException>()),
      );
    },
  );

  test(
    'accepts nullable optional activity fields and responses without IDs',
    () async {
      final api = _RecordingApiClient()
        ..response = _responseWithoutOptionalIds();
      final repository = await _repository(api);

      final trip = await repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        expectedAuthUid: 'uid-a',
      );

      expect(trip.id, startsWith('generated_'));
      expect(trip.uuid, trip.id);
      expect(trip.generationMetadata, {
        'source': 'generated',
        'dataSources': ['destination-cache'],
      });
      expect(trip.dayPlans.single.activities.single.time, isNull);
    },
  );

  test('rejects a response owned by a different UID', () async {
    final api = _RecordingApiClient()
      ..response = {..._validResponse(), 'userId': 'uid-b'};
    final repository = await _repository(api);

    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(isA<ItineraryGenerationResponseException>()),
    );
  });

  test('network and backend errors propagate to the caller', () async {
    final api = _RecordingApiClient()..failure = const NetworkException();
    final repository = await _repository(api);

    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(isA<NetworkException>()),
    );

    api.failure = const ServerException('backend unavailable');
    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(
        predicate<Object>(
          (error) =>
              error is ServerException &&
              error.message == 'backend unavailable',
        ),
      ),
    );

    api.failure = const NetworkException(
      'Request timed out. The server may still be processing this request.',
    );
    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(isA<NetworkException>()),
    );

    api.failure = const AuthRequiredException();
    await expectLater(
      repository.generateItineraryFromBackend(
        destName: 'Varanasi',
        days: 1,
        expectedAuthUid: 'uid-a',
      ),
      throwsA(isA<AuthRequiredException>()),
    );
  });

  test('account switch during generation rejects the response', () async {
    var currentUid = 'uid-a';
    final api = _RecordingApiClient()
      ..response = _validResponse()
      ..gate = Completer<void>();
    final repository = await _repository(api, currentUserUid: () => currentUid);

    final pending = repository.generateItineraryFromBackend(
      destName: 'Varanasi',
      days: 1,
      expectedAuthUid: 'uid-a',
    );
    await Future<void>.delayed(Duration.zero);
    currentUid = 'uid-b';
    api.gate!.complete();

    await expectLater(pending, throwsA(isA<AuthRequiredException>()));
  });
}
