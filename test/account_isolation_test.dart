import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:naviigo_app/core/cache/hive_service.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';
import 'package:naviigo_app/features/analytics/data/analytics_repository.dart';
import 'package:naviigo_app/features/profile/domain/models/user_preferences_model.dart';
import 'package:naviigo_app/features/profile/presentation/providers/user_provider.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/auth/auth_repository.dart';

class _User extends Fake implements User {
  @override
  final String uid;
  _User(this.uid);
}

class _AuthRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
}

class _RecordingApiClient extends ApiClient {
  final requests = <Map<String, dynamic>>[];
  Object? failure;
  Completer<void>? postStarted;
  Completer<void>? postGate;

  _RecordingApiClient() : super(baseUrl: 'https://analytics.test');

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Duration? timeout,
    String? expectedAuthUid,
  }) async {
    if (failure != null) throw failure!;
    requests.add({
      'path': path,
      'body': body,
      'expectedAuthUid': expectedAuthUid,
    });
    postStarted?.complete();
    if (postGate != null) await postGate!.future;
    return const <String, dynamic>{'ok': true};
  }
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  var boxSequence = 0;
  late Directory hiveDirectory;
  final openedBoxes = <String>{};

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'naviigo-account-isolation-',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    for (final name in openedBoxes.toList()) {
      if (Hive.isBoxOpen(name)) await Hive.box<String>(name).close();
    }
    openedBoxes.clear();
  });

  tearDownAll(() async {
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  String nextBox() {
    final name = 'analytics_test_${boxSequence++}';
    openedBoxes.add(name);
    return name;
  }

  group('offline analytics account ownership', () {
    test('expected token claims must identify the queued owner', () {
      expect(
        tokenBelongsToUid(
          token: 'token-a',
          claims: {'sub': 'A', 'user_id': 'A'},
          expectedUid: 'A',
        ),
        isTrue,
      );
      expect(
        tokenBelongsToUid(
          token: 'token-b',
          claims: {'sub': 'B'},
          expectedUid: 'A',
        ),
        isFalse,
      );
      expect(
        tokenBelongsToUid(
          token: 'token-a',
          claims: {'user_id': 'A'},
          expectedUid: 'A',
        ),
        isTrue,
      );
      expect(
        tokenBelongsToUid(
          token: 'token-a',
          claims: {'sub': 'A', 'user_id': 'B'},
          expectedUid: 'A',
        ),
        isFalse,
      );
      expect(
        tokenBelongsToUid(token: 'token-a', claims: const {}, expectedUid: 'A'),
        isFalse,
      );
    });

    test(
      'User A queue never flushes under User B, while B can flush own events',
      () async {
        var currentUid = 'A';
        final api = _RecordingApiClient();
        final boxName = nextBox();
        final repository = AnalyticsRepository(
          api,
          currentUid: () => currentUid,
          queueBoxName: boxName,
          flushOnLog: false,
        );

        await repository.logEvent(eventType: 'a_event');
        currentUid = 'B';
        await repository.forceFlush();
        expect(api.requests, isEmpty);

        await repository.logEvent(eventType: 'b_event');
        await repository.forceFlush();

        expect(api.requests, hasLength(1));
        expect(api.requests.single['path'], '/api/analytics/track');
        expect(api.requests.single['expectedAuthUid'], 'B');
        final body = api.requests.single['body'] as Map<String, dynamic>;
        final events = body['events'] as List<dynamic>;
        expect(events, hasLength(1));
        expect(events.single['eventType'], 'b_event');
        expect(events.single, isNot(contains('ownerUid')));

        final box = await Hive.openBox<String>(boxName);
        expect(box.values.map(jsonDecode), hasLength(1));
        expect(
          (jsonDecode(box.values.single) as Map<String, dynamic>)['ownerUid'],
          'A',
        );
      },
    );

    test('legacy unowned entries are discarded and never submitted', () async {
      var currentUid = 'B';
      final api = _RecordingApiClient();
      final boxName = nextBox();
      final box = await Hive.openBox<String>(boxName);
      await box.add(jsonEncode({'eventType': 'legacy_event'}));

      final repository = AnalyticsRepository(
        api,
        currentUid: () => currentUid,
        queueBoxName: boxName,
        flushOnLog: false,
      );
      await repository.forceFlush();

      expect(api.requests, isEmpty);
      expect(box, isEmpty);
      currentUid = 'A';
    });

    test('events are not created without an authenticated UID', () async {
      final api = _RecordingApiClient();
      final boxName = nextBox();
      final repository = AnalyticsRepository(
        api,
        currentUid: () => null,
        queueBoxName: boxName,
        flushOnLog: false,
      );

      await repository.logEvent(eventType: 'anonymous_event');

      final box = await Hive.openBox<String>(boxName);
      expect(box, isEmpty);
      expect(api.requests, isEmpty);
    });

    test('network failure retains the correct user queue for retry', () async {
      final api = _RecordingApiClient()..failure = const NetworkException();
      final boxName = nextBox();
      final repository = AnalyticsRepository(
        api,
        currentUid: () => 'A',
        queueBoxName: boxName,
        flushOnLog: false,
      );

      await repository.logEvent(eventType: 'retry_event');
      await repository.forceFlush();
      final box = await Hive.openBox<String>(boxName);
      expect(box.length, 1);

      api.failure = null;
      await repository.forceFlush();
      expect(api.requests, hasLength(1));
      expect(box, isEmpty);
    });

    test('concurrent flushes submit once', () async {
      final api = _RecordingApiClient()
        ..postStarted = Completer<void>()
        ..postGate = Completer<void>();
      final boxName = nextBox();
      final repository = AnalyticsRepository(
        api,
        currentUid: () => 'A',
        queueBoxName: boxName,
        flushOnLog: false,
      );

      await repository.logEvent(eventType: 'before_flush');
      final first = repository.forceFlush();
      await api.postStarted!.future;
      final second = repository.forceFlush();
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, hasLength(1));

      api.postGate!.complete();
      await Future.wait([first, second]);
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, hasLength(1));
    });

    test(
      'events queued during a request are not deleted with its batch',
      () async {
        final api = _RecordingApiClient()
          ..postStarted = Completer<void>()
          ..postGate = Completer<void>();
        final boxName = nextBox();
        final repository = AnalyticsRepository(
          api,
          currentUid: () => 'A',
          queueBoxName: boxName,
          flushOnLog: false,
        );

        await repository.logEvent(eventType: 'before_flush');
        final first = repository.forceFlush();
        await api.postStarted!.future;
        var logFinished = false;
        final during = repository.logEvent(eventType: 'during_flush').then((_) {
          logFinished = true;
        });
        await Future<void>.delayed(Duration.zero);
        expect(logFinished, isFalse);
        api.postGate!.complete();
        await first;
        await during;

        final box = await Hive.openBox<String>(boxName);
        expect(box, hasLength(1));
        expect(
          (jsonDecode(box.values.single)
              as Map<String, dynamic>)['event']['eventType'],
          'during_flush',
        );
      },
    );

    test('concurrent logging preserves the 200-entry per-user bound', () async {
      final api = _RecordingApiClient();
      final boxName = nextBox();
      final repository = AnalyticsRepository(
        api,
        currentUid: () => 'A',
        queueBoxName: boxName,
        flushOnLog: false,
      );

      for (var i = 0; i < AnalyticsRepository.maxQueueLength; i++) {
        await repository.logEvent(eventType: 'existing_$i');
      }
      await Future.wait([
        repository.logEvent(eventType: 'concurrent_1'),
        repository.logEvent(eventType: 'concurrent_2'),
      ]);

      final box = await Hive.openBox<String>(boxName);
      expect(box.length, AnalyticsRepository.maxQueueLength);
    });

    test(
      'successful flush removes only owned events and each owner is capped at 200',
      () async {
        var currentUid = 'A';
        final api = _RecordingApiClient();
        final boxName = nextBox();
        final repository = AnalyticsRepository(
          api,
          currentUid: () => currentUid,
          queueBoxName: boxName,
          flushOnLog: false,
        );

        for (var i = 0; i < AnalyticsRepository.maxQueueLength + 1; i++) {
          await repository.logEvent(eventType: 'a_$i');
        }
        currentUid = 'B';
        for (var i = 0; i < AnalyticsRepository.maxQueueLength + 1; i++) {
          await repository.logEvent(eventType: 'b_$i');
        }
        final box = await Hive.openBox<String>(boxName);
        expect(box.length, AnalyticsRepository.maxQueueLength * 2);

        await repository.forceFlush();
        expect(api.requests.single['expectedAuthUid'], 'B');
        final sent = (api.requests.single['body'] as Map)['events'] as List;
        expect(sent, hasLength(AnalyticsRepository.maxQueueLength));
        expect(
          sent.every((event) => event['eventType'].toString().startsWith('b_')),
          isTrue,
        );
        expect(box.length, AnalyticsRepository.maxQueueLength);
      },
    );

    test('logout cleanup purges only the signed-out owner queue', () async {
      var currentUid = 'A';
      final api = _RecordingApiClient();
      final boxName = HiveService.analyticsQueueBoxName;
      openedBoxes.add(boxName);
      final repository = AnalyticsRepository(
        api,
        currentUid: () => currentUid,
        queueBoxName: boxName,
        flushOnLog: false,
      );

      await repository.logEvent(eventType: 'a_event');
      currentUid = 'B';
      await repository.logEvent(eventType: 'b_event');
      await HiveService.clearAnalyticsQueueForUser('A');

      final box = await Hive.openBox<String>(boxName);
      expect(box, hasLength(1));
      expect(
        (jsonDecode(box.values.single) as Map<String, dynamic>)['ownerUid'],
        'B',
      );
    });
  });

  group('adaptive preference account ownership', () {
    test(
      'different UID retained data falls back until the new snapshot arrives',
      () async {
        final authEvents = StreamController<User?>();
        final preferenceEvents = StreamController<UserPreferencesModel>();
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => authEvents.stream),
            authRepositoryProvider.overrideWithValue(_AuthRepository()),
            userPreferencesStreamProvider.overrideWith(
              (_) => preferenceEvents.stream,
            ),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(authEvents.close);
        addTearDown(preferenceEvents.close);
        final subscription = container.listen(
          safeAdaptivePreferencesProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        authEvents.add(_User('A'));
        await container.read(authStateProvider.future);
        preferenceEvents.add(
          const UserPreferencesModel(
            travelStyle: 'luxury',
            preferredGroup: 'friends',
            interests: ['culture'],
            accessibilityNeeds: ['step-free'],
            adaptiveAppearanceEnabled: false,
            sourceUserId: 'A',
          ),
        );
        await container.read(userPreferencesStreamProvider.future);
        expect(
          container.read(safeAdaptivePreferencesProvider).travelStyle,
          'luxury',
        );

        authEvents.add(_User('B'));
        await _flushMicrotasks();
        final duringSwitch = container.read(safeAdaptivePreferencesProvider);
        expect(duringSwitch, const UserPreferencesModel());

        preferenceEvents.add(
          const UserPreferencesModel(
            travelStyle: 'budget',
            preferredGroup: 'solo',
            interests: ['nature'],
            accessibilityNeeds: ['wheelchair'],
            adaptiveAppearanceEnabled: true,
            sourceUserId: 'B',
          ),
        );
        await _flushMicrotasks();
        expect(
          container.read(safeAdaptivePreferencesProvider),
          const UserPreferencesModel(
            travelStyle: 'budget',
            preferredGroup: 'solo',
            interests: ['nature'],
            accessibilityNeeds: ['wheelchair'],
            adaptiveAppearanceEnabled: true,
            sourceUserId: 'B',
          ),
        );

        authEvents.add(null);
        await _flushMicrotasks();
        expect(
          container.read(safeAdaptivePreferencesProvider),
          const UserPreferencesModel(),
        );
      },
    );

    test(
      'same UID retained data remains usable during a preference reload error',
      () async {
        final preferenceEvents = StreamController<UserPreferencesModel>();
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => Stream.value(_User('A'))),
            authRepositoryProvider.overrideWithValue(_AuthRepository()),
            userPreferencesStreamProvider.overrideWith(
              (_) => preferenceEvents.stream,
            ),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(preferenceEvents.close);
        final subscription = container.listen(
          safeAdaptivePreferencesProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        await container.read(authStateProvider.future);
        preferenceEvents.add(
          const UserPreferencesModel(travelStyle: 'luxury', sourceUserId: 'A'),
        );
        await container.read(userPreferencesStreamProvider.future);
        preferenceEvents.addError(Exception('offline'));
        await _flushMicrotasks();

        expect(
          container.read(safeAdaptivePreferencesProvider).travelStyle,
          'luxury',
        );
      },
    );
  });
}
