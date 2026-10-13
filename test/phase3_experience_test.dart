// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/adaptive/adaptive_experience_profile.dart';
import 'package:naviigo_app/core/auth/auth_repository.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/theme/app_theme.dart';
import 'package:naviigo_app/features/dashboard/presentation/pages/home_page.dart';
import 'package:naviigo_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:naviigo_app/features/dashboard/presentation/providers/home_provider.dart';
import 'package:naviigo_app/features/explore/presentation/pages/explore_discover_page.dart';
import 'package:naviigo_app/features/explore/presentation/providers/explore_provider.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/saved_places_provider.dart';
import 'package:naviigo_app/features/bookings/data/saved_places_repository.dart';
import 'package:naviigo_app/features/bookings/domain/models/saved_place_model.dart';
import 'package:naviigo_app/features/places/data/places_repository.dart';
import 'package:naviigo_app/features/places/domain/models/place_model.dart';
import 'package:naviigo_app/features/places/presentation/providers/places_provider.dart';
import 'package:naviigo_app/features/profile/presentation/providers/user_provider.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

class _User extends Fake implements User {
  @override
  final String uid;
  _User(this.uid);
}

class _AuthRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;
}

class _Places extends Fake implements PlacesRepository {
  final responses = <String, Future<AutocompleteSearchResult>>{};

  @override
  Future<AutocompleteSearchResult> searchAutocompleteResult(String query) {
    return responses[query] ??
        Future.value(const AutocompleteSearchResult(predictions: []));
  }
}

// Small Firestore boundary double for the real saved-place repository.
class _SavedFirestore extends Fake implements FirebaseFirestore {
  final document = _SavedDocument();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _SavedCollection(document, path);
}

class _SavedCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final _SavedDocument document;
  @override
  final String path;
  _SavedCollection(this.document, this.path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => document;
}

// ignore: must_be_immutable
class _SavedDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  bool exists = false;
  bool fail = false;
  Map<String, dynamic> data = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _SavedCollection(this, path);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    if (fail) throw StateError('offline');
    return _SavedSnapshot(exists, data);
  }

  @override
  Future<void> set(Map<String, dynamic> value, [SetOptions? options]) async {
    if (fail) throw StateError('offline');
    data = value;
    exists = true;
  }

  @override
  Future<void> delete() async {
    if (fail) throw StateError('offline');
    exists = false;
  }
}

class _SavedSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final bool exists;
  final Map<String, dynamic> value;
  _SavedSnapshot(this.exists, this.value);

  @override
  Map<String, dynamic>? data() => value;
}

TripItineraryModel _trip({TripStatus? status, DateTime? start}) {
  return TripItineraryModel(
    id: 'trip',
    uuid: 'trip',
    destId: 'jaipur',
    destName: 'Jaipur',
    userId: 'A',
    status: status,
    form: {if (start != null) 'startDate': start.toIso8601String()},
    dayPlans: const [
      TripDayPlanModel(
        dayNumber: 1,
        activities: [TripActivityModel(title: 'Amer Fort', time: '09:00')],
      ),
    ],
  );
}

void main() {
  group('Phase 3 lifecycle boundaries', () {
    test('home surface follows the frozen lifecycle vocabulary', () {
      expect(
        homeSurfaceForLifecycle(AdaptiveJourneyLifecycle.activeTrip),
        HomeJourneySurface.active,
      );
      expect(
        homeSurfaceForLifecycle(AdaptiveJourneyLifecycle.upcoming),
        HomeJourneySurface.upcoming,
      );
      expect(
        homeSurfaceForLifecycle(AdaptiveJourneyLifecycle.discover),
        HomeJourneySurface.discovery,
      );
      // Historical trips do not create a post-trip lifecycle on their own.
      expect(
        homeSurfaceForLifecycle(AdaptiveJourneyLifecycle.postTrip),
        HomeJourneySurface.discovery,
      );
    });

    testWidgets('home renders truthful active and upcoming actions', (
      tester,
    ) async {
      final user = _User('A');
      Future<void> pump(List<TripItineraryModel> trips) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(user),
              authRepositoryProvider.overrideWithValue(_AuthRepository()),
              userTripsStreamProvider.overrideWith((_) => Stream.value(trips)),
              topDestinationsProvider.overrideWith(
                (_) => Stream.value(const []),
              ),
              userProfileStreamProvider.overrideWith((_) => Stream.value(null)),
              savedPlacesStreamProvider.overrideWith(
                (_) => Stream.value(const []),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme(),
              home: const Scaffold(body: HomePage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump([_trip(status: TripStatus.active)]);
      expect(find.text('JOURNEY IN MOTION'), findsOneWidget);
      expect(find.text('Amer Fort'), findsOneWidget);
      expect(find.text('Open ongoing trip'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await pump([
        _trip(
          status: TripStatus.upcoming,
          start: DateTime.now().add(const Duration(days: 2)),
        ),
      ]);
      expect(find.text('YOUR NEXT JOURNEY'), findsOneWidget);
      expect(find.text('Open itinerary'), findsOneWidget);
    });
  });

  group('Explore async contracts', () {
    test('provider-keyed searches cannot replace a newer query', () async {
      final places = _Places();
      final oldResponse = Completer<AutocompleteSearchResult>();
      final newResponse = Completer<AutocompleteSearchResult>();
      places.responses['old'] = oldResponse.future;
      places.responses['new'] = newResponse.future;
      final container = ProviderContainer(
        overrides: [placesRepositoryProvider.overrideWithValue(places)],
      );
      addTearDown(container.dispose);

      final oldProvider = exploreSearchProvider((query: 'old', ownerUid: 'A'));
      final newProvider = exploreSearchProvider((query: 'new', ownerUid: 'A'));
      final oldSubscription = container.listen(oldProvider, (_, __) {});
      final newSubscription = container.listen(newProvider, (_, __) {});
      final old = container.read(oldProvider.future);
      final newer = container.read(newProvider.future);
      newResponse.complete(
        const AutocompleteSearchResult(
          predictions: [
            {'description': 'New place'},
          ],
        ),
      );
      oldResponse.complete(
        const AutocompleteSearchResult(
          predictions: [
            {'description': 'Old place'},
          ],
        ),
      );

      expect((await newer).suggestions.single['description'], 'New place');
      expect((await old).suggestions.single['description'], 'Old place');
      expect(
        container.read(newProvider),
        isNot(same(container.read(oldProvider))),
      );
      oldSubscription.close();
      newSubscription.close();
    });

    test(
      'provider unavailable is distinct from a truthful empty result',
      () async {
        final places = _Places()
          ..responses['unavailable'] = Future.value(
            const AutocompleteSearchResult(predictions: [], unavailable: true),
          )
          ..responses['empty'] = Future.value(
            const AutocompleteSearchResult(predictions: []),
          );
        final container = ProviderContainer(
          overrides: [placesRepositoryProvider.overrideWithValue(places)],
        );
        addTearDown(container.dispose);

        final unavailableProvider = exploreSearchProvider((
          query: 'unavailable',
          ownerUid: 'A',
        ));
        final emptyProvider = exploreSearchProvider((
          query: 'empty',
          ownerUid: 'A',
        ));
        final unavailableSubscription = container.listen(
          unavailableProvider,
          (_, __) {},
        );
        final emptySubscription = container.listen(emptyProvider, (_, __) {});
        final unavailable = await container.read(unavailableProvider.future);
        final empty = await container.read(emptyProvider.future);
        expect(unavailable.status, ExploreSearchStatus.unavailable);
        expect(empty.status, ExploreSearchStatus.empty);
        unavailableSubscription.close();
        emptySubscription.close();
      },
    );

    test('place map eligibility excludes missing coordinates', () {
      expect(
        const PlaceModel(
          id: 'known',
          name: 'Known',
          lat: 1,
          lng: 2,
        ).hasCoordinates,
        isTrue,
      );
      expect(
        const PlaceModel(id: 'unknown', name: 'Unknown').hasCoordinates,
        isFalse,
      );
    });

    testWidgets('explore remains usable at narrow width and reduced motion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(_User('A')),
            authRepositoryProvider.overrideWithValue(_AuthRepository()),
            placesRepositoryProvider.overrideWithValue(_Places()),
            recommendationsProvider.overrideWith((_, __) async => []),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.5),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme(),
              home: const Scaffold(body: ExploreDiscoverPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Where next?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Saved place persistence boundaries', () {
    test(
      'repository reports success and failure instead of faking persistence',
      () async {
        final firestore = _SavedFirestore();
        final repository = SavedPlacesRepository(firestore: firestore);
        const place = SavedPlaceModel(
          id: 'p1',
          name: 'Place',
          type: 'destination',
        );

        expect(await repository.toggleSavedPlace('A', place), isTrue);
        expect(firestore.document.exists, isTrue);
        firestore.document.fail = true;
        expect(await repository.toggleSavedPlace('A', place), isFalse);
      },
    );

    test('saved stream rejects retained data from another account', () async {
      final authEvents = StreamController<User?>();
      final savedEvents = StreamController<List<SavedPlaceModel>>();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((_) => authEvents.stream),
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
          savedPlacesStreamProvider.overrideWith((_) => savedEvents.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authEvents.close);
      addTearDown(savedEvents.close);
      final listener = container.listen(safeSavedPlacesProvider, (_, __) {});
      addTearDown(listener.close);

      authEvents.add(_User('A'));
      await container.read(authStateProvider.future);
      savedEvents.add([
        const SavedPlaceModel(
          id: 'a',
          name: 'A place',
          type: 'destination',
          sourceUserId: 'A',
        ),
      ]);
      await container.read(savedPlacesStreamProvider.future);
      expect(container.read(safeSavedPlacesProvider), hasLength(1));

      authEvents.add(_User('B'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(safeSavedPlacesProvider), isEmpty);
      savedEvents.add([
        const SavedPlaceModel(
          id: 'b',
          name: 'B place',
          type: 'destination',
          sourceUserId: 'B',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(safeSavedPlacesProvider).single.name, 'B place');
    });
  });
}
