import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:naviigo_app/core/cache/hive_service.dart';
import 'package:naviigo_app/features/trips/presentation/providers/journey_recording_provider.dart';
import 'package:naviigo_app/features/explore/presentation/pages/transportation_page.dart';

Position fix(DateTime at, double lat, {double accuracy = 5}) => Position(
  latitude: lat,
  longitude: 78,
  timestamp: at,
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('naviigo-route-test-');
    Hive.init(temporary.path);
    await Hive.openBox(HiveService.itineraryBoxName);
  });
  tearDownAll(() async {
    await Hive.close();
    await temporary.delete(recursive: true);
  });
  setUp(() async => HiveService.itineraryBox.clear());

  test(
    'GPS recording filters bad fixes, persists its owner and stops on account change',
    () async {
      var allowed = true;
      final stream = StreamController<Position>();
      const key = (ownerUid: 'A', tripId: 'journey');
      final recorder = JourneyRecorder(
        key,
        allowed: () => allowed,
        locationReady: () async {},
        positions: () => stream.stream,
      );
      await recorder.start();
      final now = DateTime.now();
      recorder.addPosition(fix(now.subtract(const Duration(seconds: 25)), 30));
      recorder.addPosition(
        fix(now.subtract(const Duration(seconds: 12)), 30.001),
      );
      recorder.addPosition(fix(now, 30.002, accuracy: 500));
      await recorder.pendingWrites;
      expect(recorder.state.points.length, 2);
      final restored = JourneyRecorder(key, allowed: () => false);
      final otherOwner = JourneyRecorder((
        ownerUid: 'B',
        tripId: 'journey',
      ), allowed: () => false);
      expect(restored.state.points.length, 2);
      expect(otherOwner.state.points, isEmpty);
      allowed = false;
      recorder.addPosition(fix(now, 30.002));
      expect(recorder.state.recording, false);
      expect(recorder.state.points.length, 2);
      recorder.dispose();
      restored.dispose();
      otherOwner.dispose();
      await stream.close();
    },
  );

  test(
    'background suspension stops recording and unobserved gaps add no distance',
    () async {
      final stream = StreamController<Position>();
      final recorder = JourneyRecorder(
        (ownerUid: 'A', tripId: 'journey'),
        allowed: () => true,
        locationReady: () async {},
        positions: () => stream.stream,
      );
      await recorder.start();
      recorder.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(recorder.state.recording, false);
      final now = DateTime.now();
      expect(
        routeDistanceKm([
          RouteSample(30, 78, now),
          RouteSample(31, 79, now.add(const Duration(hours: 1))),
        ]),
        0,
      );
      recorder.dispose();
      await stream.close();
    },
  );

  test('ride estimates use declared assumptions and remain ranges', () {
    expect(estimatedRideFare(5), (low: 90, high: 126));
    expect(estimatedRideFare(1, auto: true), (low: 30, high: 42));
  });

  test('a restored route resumes a new segment after a long gap', () async {
    const key = (ownerUid: 'A', tripId: 'resumed');
    final now = DateTime.now();
    await HiveService.itineraryBox.put(JourneyRecorder.cacheKey(key), {
      'ownerUid': 'A',
      'tripId': 'resumed',
      'points': [
        RouteSample(30, 78, now.subtract(const Duration(hours: 1))).toMap(),
      ],
    });
    final stream = StreamController<Position>();
    final recorder = JourneyRecorder(
      key,
      allowed: () => true,
      locationReady: () async {},
      positions: () => stream.stream,
    );
    await recorder.start();
    recorder.addPosition(fix(now, 31));
    await recorder.pendingWrites;
    expect(recorder.state.points.length, 2);
    expect(routeDistanceKm(recorder.state.points), 0);
    recorder.dispose();
    await stream.close();
  });

  test(
    'backgrounding during permission acquisition prevents recording',
    () async {
      final permission = Completer<void>();
      var subscribed = false;
      final recorder = JourneyRecorder(
        (ownerUid: 'A', tripId: 'permission'),
        allowed: () => true,
        locationReady: () => permission.future,
        positions: () {
          subscribed = true;
          return const Stream.empty();
        },
      );
      final starting = recorder.start();
      recorder.didChangeAppLifecycleState(AppLifecycleState.paused);
      permission.complete();
      await starting;
      expect(recorder.state.recording, false);
      expect(subscribed, false);
      recorder.dispose();
    },
  );
}
