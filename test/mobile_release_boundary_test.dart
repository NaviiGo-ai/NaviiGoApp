import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/features/bookings/data/passport_repository.dart';
import 'package:naviigo_app/features/bookings/domain/models/passport_model.dart';
import 'package:naviigo_app/features/bookings/presentation/pages/digital_passport_page.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/passport_provider.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/saved_places_provider.dart';
import 'package:naviigo_app/features/dashboard/presentation/pages/ongoing_trips_page.dart';
import 'package:naviigo_app/features/trips/domain/models/live_trip_state.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/providers/live_trip_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _DelayedFailingStore extends InMemoryCheckInStore {
  final started = Completer<void>();
  final release = Completer<void>();
  int writes = 0;
  @override
  Future<void> writeForOwner(
    String ownerUid,
    String tripId,
    Map<String, TripCheckIn> checkIns,
  ) async {
    if (++writes == 1) {
      started.complete();
      await release.future;
      return super.writeForOwner(ownerUid, tripId, checkIns);
    }
    throw StateError('local persistence unavailable');
  }
}

class _Passport extends Fake implements PassportRepository {
  final streams = <String, StreamController<List<PassportStampModel>>>{};
  int writes = 0;
  @override
  Stream<PassportStatsModel> getPassportStatsStream(String uid) =>
      Stream.value(const PassportStatsModel());
  @override
  Stream<List<PassportStampModel>> getPassportStampsStream(String uid) =>
      (streams[uid] ??= StreamController.broadcast()).stream;
  @override
  Future<PassportAwardResult> addPassportStamp(
    String uid,
    PassportStampModel stamp,
  ) async {
    writes++;
    return PassportAwardResult.awarded;
  }

  Future<void> dispose() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

TripItineraryModel _trip(
  String revision,
  List<String> ids, {
  bool legacy = false,
}) => TripItineraryModel.fromMap('trip', {
  'userId': 'alice',
  'status': 'active',
  'revisionId': revision,
  'destName': 'Test Journey',
  'destId': 'jaipur',
  'dayPlans': [
    {
      'day': 1,
      'activities': [
        for (final id in ids) {'title': id, if (!legacy) 'activityId': id},
      ],
    },
  ],
});

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Widget _app(ProviderContainer container, Widget page) =>
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(home: page),
      ),
    );

void main() {
  test(
    'late check-in acknowledgment cannot restore pruned legacy rollback data',
    () async {
      final stream = StreamController<List<TripItineraryModel>>();
      final store = _DelayedFailingStore();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('alice'),
          checkInStoreProvider.overrideWithValue(store),
          userTripsStreamProvider.overrideWith((ref) => stream.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await stream.close();
      });
      final controller = container.read(
        liveTripControllerProvider('trip').notifier,
      );
      stream.add([
        _trip('r0', ['fort', 'market'], legacy: true),
      ]);
      await _flush();
      final write = controller.logCheckIn('0:0', TripCheckIn.completed);
      await store.started.future;
      stream.add([
        _trip('r1', ['market', 'fort'], legacy: true),
      ]);
      await _flush();
      store.release.complete();
      await write;
      await _flush();
      // Both the prune write and this later check-in fail. The rollback snapshot
      // must still exclude the record acknowledged for the old activity order.
      await controller.logCheckIn('0:1', TripCheckIn.completed);
      expect(container.read(liveTripControllerProvider('trip')), isEmpty);
      expect(container.read(liveTripCommandProvider).error, isNotNull);
    },
  );

  test(
    'owner refresh prunes removed IDs in both live state and persistence',
    () async {
      final stream = StreamController<List<TripItineraryModel>>();
      final store = InMemoryCheckInStore();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('alice'),
          checkInStoreProvider.overrideWithValue(store),
          userTripsStreamProvider.overrideWith((ref) => stream.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await stream.close();
      });
      final controller = container.read(
        liveTripControllerProvider('trip').notifier,
      );
      final original = _trip('r0', ['a', 'b']);
      stream.add([original]);
      await _flush();
      await controller.logCheckIn('a', TripCheckIn.arrived);
      await controller.logCheckIn('b', TripCheckIn.skipped);
      final refreshed = _trip('r1', ['c', 'a']);
      stream.add([refreshed]);
      await _flush();
      expect(container.read(liveTripControllerProvider('trip')), {
        'a': TripCheckIn.arrived,
      });
      expect(store.readForOwner('alice', 'trip'), {'a': TripCheckIn.arrived});
      final live = container.read(liveTripStateProvider(refreshed));
      expect(live.waypoints.first.checkIn, TripCheckIn.pending);
      expect(live.waypoints.last.checkIn, TripCheckIn.arrived);
      stream.add([
        _trip('r2', ['b', 'a']),
      ]);
      await _flush();
      expect(
        container
            .read(liveTripStateProvider(_trip('r2', ['b', 'a'])))
            .waypoints
            .first
            .checkIn,
        TripCheckIn.pending,
      );
    },
  );

  test(
    'legacy refresh never transfers positional check-ins to replacement activities',
    () async {
      final stream = StreamController<List<TripItineraryModel>>();
      final store = InMemoryCheckInStore();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('alice'),
          checkInStoreProvider.overrideWithValue(store),
          userTripsStreamProvider.overrideWith((ref) => stream.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await stream.close();
      });
      final controller = container.read(
        liveTripControllerProvider('trip').notifier,
      );
      stream.add([
        _trip('r0', ['fort', 'market'], legacy: true),
      ]);
      await _flush();
      await controller.logCheckIn('0:0', TripCheckIn.completed);
      final refreshed = _trip('r1', ['market', 'fort'], legacy: true);
      stream.add([refreshed]);
      await _flush();
      expect(container.read(liveTripControllerProvider('trip')), isEmpty);
      expect(store.readForOwner('alice', 'trip'), isEmpty);
      expect(
        container.read(liveTripStateProvider(refreshed)).completedCount,
        0,
      );
    },
  );

  testWidgets('Passport hides account A moments while account B stream waits', (
    tester,
  ) async {
    final owner = StateProvider<String?>((ref) => 'alice');
    final repository = _Passport();
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => ref.watch(owner)),
        passportRepositoryProvider.overrideWithValue(repository),
        userTripsStreamProvider.overrideWith((ref) => Stream.value([])),
        safeSavedPlacesProvider.overrideWithValue([]),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });
    await tester.pumpWidget(_app(container, const DigitalPassportPage()));
    await tester.pump();
    repository.streams['alice']!.add([
      const PassportStampModel(
        id: 'a',
        name: 'Alice memory',
        location: 'Alice private note',
        state: 'A state',
        activities: ['Alice private note'],
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Alice private note'), findsOneWidget);
    container.read(owner.notifier).state = 'bob';
    await tester.pump();
    await tester.pump();
    expect(find.text('Alice private note'), findsNothing);
    expect(container.read(passportStampsStreamProvider('bob')).hasValue, false);
    repository.streams['bob']!.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Alice private note'), findsNothing);
  });

  testWidgets('retained account A journey dialog cannot save into account B', (
    tester,
  ) async {
    final user = StateProvider<User?>((ref) => _User('alice'));
    final repository = _Passport();
    final trip = _trip('r0', ['fort']);
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => ref.watch(user)),
        currentUserIdProvider.overrideWith((ref) => ref.watch(user)?.uid),
        passportRepositoryProvider.overrideWithValue(repository),
        userTripsStreamProvider.overrideWith((ref) => Stream.value([trip])),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });
    await tester.pumpWidget(_app(container, const OngoingTripsPage()));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('ADD MOMENT'));
    await tester.tap(find.text('ADD MOMENT'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'private note');
    container.read(user.notifier).state = _User('bob');
    await tester.pump();
    await tester.tap(find.text('Save Moment'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.writes, 0);
    expect(find.text('Sign in again before saving a moment.'), findsOneWidget);
  });
}
