// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:naviigo_app/core/cache/hive_service.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/features/trips/data/trip_repository.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';

class _FirestoreBoundary extends Fake implements FirebaseFirestore {
  final _ItineraryDocument document = _ItineraryDocument();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _ItineraryCollection(document);
  }
}

class _ItineraryCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final _ItineraryDocument document;

  _ItineraryCollection(this.document);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => document;
}

class _ItineraryDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  bool failSet = false;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _ItineraryCollection(this);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return _EmptyDocumentSnapshot();
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (failSet) throw StateError('authority unavailable');
  }
}

class _EmptyDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => false;

  @override
  Map<String, dynamic>? data() => null;
}

TripItineraryModel _trip({String? userId, bool isEphemeral = false}) {
  return TripItineraryModel.fromMap('trip-1', {
    'id': 'trip-1',
    'uuid': 'trip-1',
    'destId': 'jaipur',
    'destName': 'Jaipur',
    if (userId != null) 'userId': userId,
    'isEphemeral': isEphemeral,
    'form': {'days': 1},
    'dayPlans': [
      {
        'day': 1,
        'activities': [
          {'title': 'Amber Fort'},
        ],
      },
    ],
  });
}

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> itineraryBox;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'naviigo-trip-repository-',
    );
    Hive.init(hiveDirectory.path);
    itineraryBox = await Hive.openBox<dynamic>(HiveService.itineraryBoxName);
  });

  setUp(() async {
    await itineraryBox.clear();
  });

  tearDownAll(() async {
    await itineraryBox.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'saveTrip rejects ephemeral and foreign itineraries before writing',
    () async {
      final repository = TripRepository(
        firestore: _FirestoreBoundary(),
        currentUserUid: () => 'owner-a',
      );

      await expectLater(
        repository.saveTrip('owner-a', _trip(isEphemeral: true)),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repository.saveTrip('owner-a', _trip(userId: 'owner-b')),
        throwsA(isA<ForbiddenException>()),
      );
      expect(HiveService.getCachedItinerary('owner-a', 'trip-1'), isNull);
    },
  );

  test('authority failure does not populate the local cache', () async {
    final firestore = _FirestoreBoundary()..document.failSet = true;
    final repository = TripRepository(
      firestore: firestore,
      currentUserUid: () => 'owner-a',
    );

    await expectLater(
      repository.saveTrip('owner-a', _trip(userId: 'owner-a')),
      throwsA(isA<StateError>()),
    );
    expect(HiveService.getCachedItinerary('owner-a', 'trip-1'), isNull);
  });
}
