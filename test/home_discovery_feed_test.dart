import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_provider.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/constants/master_destinations.dart';
import 'package:naviigo_app/core/theme/app_theme.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/saved_places_provider.dart';
import 'package:naviigo_app/features/dashboard/presentation/pages/home_page.dart';
import 'package:naviigo_app/features/dashboard/presentation/providers/home_discovery_provider.dart';
import 'package:naviigo_app/features/dashboard/presentation/widgets/home_discovery_widgets.dart';
import 'package:naviigo_app/features/explore/presentation/widgets/discovery_widgets.dart';
import 'package:naviigo_app/features/places/data/places_repository.dart';
import 'package:naviigo_app/features/places/domain/models/place_model.dart';
import 'package:naviigo_app/features/places/presentation/providers/places_provider.dart';
import 'package:naviigo_app/features/profile/presentation/providers/user_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

class _User extends Fake implements User {
  @override
  final String uid;
  _User(this.uid);
}

class _Places extends Fake implements PlacesRepository {
  final Future<List<PlaceModel>> Function(double, double) reply;
  int calls = 0;
  _Places(this.reply);
  @override
  Future<List<PlaceModel>> getNearbyPlaces({
    double lat = 0,
    double lng = 0,
    String type = 'tourist_attraction',
    int radius = 5000,
  }) {
    calls++;
    return reply(lat, lng);
  }
}

final _ujjain = findDestinationById('ujjain')!;
final _varanasi = findDestinationById('varanasi')!;
final _jaipur = findDestinationById('jaipur')!;
final _goa = findDestinationById('goa')!;
PlaceModel _place(String id, MasterDestination city) => PlaceModel(
  id: id,
  name: 'Place $id',
  lat: city.lat + .001,
  lng: city.lng + .001,
  vicinity: city.name,
);

Future<ProviderContainer> _pumpHome(
  WidgetTester tester,
  HomeDiscoveryController feed, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_User('A')),
        homeDiscoveryProvider.overrideWith((_) => feed),
        userTripsStreamProvider.overrideWith((_) => Stream.value(const [])),
        savedPlacesStreamProvider.overrideWith((_) => Stream.value(const [])),
        userProfileStreamProvider.overrideWith((_) => Stream.value(null)),
        destinationPhotoProvider.overrideWith((_, _) async => {}),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(body: HomePage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(HomePage)));
}

void main() {
  test('concurrent scrolling requests share a single in-flight page', () async {
    final pending = Completer<List<PlaceModel>>();
    final repo = _Places((_, _) => pending.future);
    final feed = HomeDiscoveryController(repo, catalogue: [_ujjain, _varanasi]);
    addTearDown(feed.dispose);
    final first = feed.loadNext();
    await feed.loadNext();
    expect(repo.calls, 1);
    expect(feed.state.entries.single.destination.id, 'ujjain');
    pending.complete([_place('one', _ujjain)]);
    await first;
    expect(feed.state.cursor, 1);
    expect(feed.state.entries.length, 2);
  });

  test(
    'pagination deduplicates places and rejects invalid or distant coordinates',
    () async {
      final repo = _Places((lat, _) async {
        final city = lat == _ujjain.lat ? _ujjain : _varanasi;
        return [
          _place('shared', city),
          _place('shared', city),
          const PlaceModel(id: 'remote', name: 'Wrong city', lat: 0, lng: 0),
          const PlaceModel(id: 'missing', name: 'Unknown coordinates'),
          PlaceModel(
            id: 'generic',
            name: 'religious monuments',
            lat: city.lat,
            lng: city.lng,
          ),
        ];
      });
      final feed = HomeDiscoveryController(
        repo,
        catalogue: [_ujjain, _varanasi],
      );
      addTearDown(feed.dispose);
      await feed.loadNext();
      await feed.loadNext();
      await feed.loadNext();
      expect(repo.calls, 2);
      expect(feed.state.entries.map((e) => e.id), [
        'city:ujjain',
        'place:shared',
        'city:varanasi',
      ]);
      expect(feed.state.hasMore, isFalse);
    },
  );

  test(
    'provider failures retain the page for retry without duplicating its city',
    () async {
      var fail = true;
      final repo = _Places((_, _) async {
        if (fail) throw StateError('provider error with private diagnostic');
        return [_place('one', _ujjain)];
      });
      final feed = HomeDiscoveryController(repo, catalogue: [_ujjain]);
      addTearDown(feed.dispose);
      await feed.loadNext();
      expect(feed.state.cursor, 0);
      expect(feed.state.error, contains('Ujjain'));
      expect(feed.state.error, isNot(contains('private diagnostic')));
      fail = false;
      await feed.loadNext();
      expect(feed.state.error, isNull);
      expect(feed.state.entries.map((e) => e.id).toSet().length, 2);
      expect(feed.state.hasMore, isFalse);
    },
  );

  test('readers can explicitly continue past an unavailable city', () async {
    final repo = _Places((lat, _) async {
      if (lat == _ujjain.lat) throw StateError('outage');
      return [_place('next', _varanasi)];
    });
    final feed = HomeDiscoveryController(repo, catalogue: [_ujjain, _varanasi]);
    addTearDown(feed.dispose);
    await feed.loadNext();
    await feed.skipUnavailableCity();
    expect(feed.state.entries.last.place?.id, 'next');
    expect(feed.state.hasMore, isFalse);
    expect(repo.calls, 2);
  });

  test('filter changes and refresh discard late old-page responses', () async {
    final pending = Completer<List<PlaceModel>>();
    final repo = _Places(
      (lat, _) => lat == _ujjain.lat
          ? pending.future
          : Future.value([_place('coast', _goa)]),
    );
    final feed = HomeDiscoveryController(repo, catalogue: [_ujjain, _goa]);
    addTearDown(feed.dispose);
    final old = feed.loadNext();
    await feed.refresh(HomeDiscoveryCategory.coast);
    pending.complete([_place('stale', _ujjain)]);
    await old;
    expect(feed.state.category, HomeDiscoveryCategory.coast);
    expect(
      feed.state.entries.every((entry) => entry.destination.id == 'goa'),
      isTrue,
    );
    expect(
      feed.state.entries.any((entry) => entry.place?.id == 'stale'),
      isFalse,
    );
    await feed.refresh();
    expect(feed.state.entries.length, 2);
  });

  test(
    'empty provider pages advance and terminate without repeating content',
    () async {
      final feed = HomeDiscoveryController(
        _Places((_, _) async => []),
        catalogue: [_ujjain, _varanasi],
      );
      addTearDown(feed.dispose);
      await feed.loadNext();
      await feed.loadNext();
      await feed.loadNext();
      expect(feed.state.entries.length, 2);
      expect(feed.state.hasMore, isFalse);
      await feed.refresh(HomeDiscoveryCategory.coast);
      expect(feed.state.entries, isEmpty);
      expect(feed.state.hasMore, isFalse);
    },
  );

  test(
    'account changes reset feed filters and ignore old in-flight work',
    () async {
      final user = StateProvider<User?>((_) => _User('A'));
      final pending = Completer<List<PlaceModel>>();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => ref.watch(user)),
          placesRepositoryProvider.overrideWithValue(
            _Places((_, _) => pending.future),
          ),
        ],
      );
      addTearDown(container.dispose);
      final first = container.read(homeDiscoveryProvider.notifier);
      final request = first.loadNext();
      container.read(user.notifier).state = _User('B');
      final second = container.read(homeDiscoveryProvider.notifier);
      expect(identical(first, second), isFalse);
      pending.complete([_place('old', _ujjain)]);
      await request;
      expect(second.state.entries, isEmpty);
      expect(second.scrollOffset, 0);
    },
  );

  testWidgets(
    'scrolling automatically appends real pages and eventually shows the end',
    (tester) async {
      final repo = _Places((lat, _) async {
        final city = lat == _ujjain.lat
            ? _ujjain
            : lat == _varanasi.lat
            ? _varanasi
            : _jaipur;
        return [_place(city.id, city)];
      });
      final feed = HomeDiscoveryController(
        repo,
        catalogue: [_ujjain, _varanasi, _jaipur],
      );
      await _pumpHome(tester, feed);
      expect(repo.calls, 1);
      for (
        var i = 0;
        i < 16 &&
            (feed.state.hasMore ||
                !find.text('You’re all caught up.').evaluate().isNotEmpty);
        i++
      ) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -550));
        await tester.pumpAndSettle();
      }
      expect(repo.calls, 3);
      expect(feed.state.entries.length, 6);
      await tester.scrollUntilVisible(
        find.text('You’re all caught up.'),
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      expect(find.text('You’re all caught up.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home remains usable at 320px with large text and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final feed = HomeDiscoveryController(
        _Places((_, _) async => []),
        catalogue: [_ujjain],
      );
      await _pumpHome(tester, feed, scale: 2);
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('You’re all caught up.'),
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      expect(find.text('You’re all caught up.'), findsOneWidget);
    },
  );

  testWidgets(
    'category selection and pull-to-refresh use the current category',
    (tester) async {
      final repo = _Places((_, _) async => []);
      final feed = HomeDiscoveryController(repo, catalogue: [_ujjain, _goa]);
      await _pumpHome(tester, feed);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Coast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coast'));
      await tester.pumpAndSettle();
      expect(feed.state.category, HomeDiscoveryCategory.coast);
      expect(feed.state.entries.single.destination.id, 'goa');
      final beforeRefresh = repo.calls;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(repo.calls, beforeRefresh + 1);
      expect(feed.state.category, HomeDiscoveryCategory.coast);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'photo requests bound Unicode query length and reject malformed image values',
    () async {
      String? query;
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(
              httpClient: MockClient((request) async {
                query = request.url.queryParameters['query'];
                return http.Response('{"image":123}', 200);
              }),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final metadata = await container.read(
        destinationPhotoProvider(List.filled(120, '🛕').join()).future,
      );
      expect(query?.runes.length, 100);
      expect(metadata.containsKey('image'), isFalse);
    },
  );

  testWidgets('feed cards open their actual pilot or place record', (
    tester,
  ) async {
    final venue = _place('venue', _ujjain);
    Object? received;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: HomeDiscoveryCard(entry: HomeDiscoveryEntry(_ujjain, venue)),
          ),
        ),
        GoRoute(
          path: '/place-details',
          builder: (_, state) {
            received = state.extra;
            return const Scaffold(body: Text('Place opened'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [destinationPhotoProvider.overrideWith((_, _) async => {})],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a closer look'));
    await tester.pumpAndSettle();
    expect(received, same(venue));
    expect(find.text('Place opened'), findsOneWidget);
  });

  testWidgets(
    'malformed photo metadata stays stable and Retry requests fresh metadata',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            destinationPhotoProvider.overrideWith((_, _) async {
              attempts++;
              return {'image': 123};
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const Scaffold(
              body: DiscoveryImage(image: null, label: 'Ujjain'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(attempts, 1);
      await tester.tap(find.byTooltip('Retry photo'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed network photos offer a real retry while preserving layout',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const Scaffold(
              body: DiscoveryImage(
                image: 'https://example.com/broken.jpg',
                label: 'Photo test',
                height: 150,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Retry photo'), findsOneWidget);
      final before = tester.getSize(find.byType(DiscoveryImage));
      await tester.tap(find.byTooltip('Retry photo'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DiscoveryImage)), before);
      expect(tester.takeException(), isNull);
    },
  );
}
