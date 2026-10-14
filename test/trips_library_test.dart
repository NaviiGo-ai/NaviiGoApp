import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/pages/trips_library_page.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

void main() {
  testWidgets('saved upcoming trips open and another owner is excluded', (
    tester,
  ) async {
    const trip = TripItineraryModel(
      id: 'saved',
      uuid: 'saved',
      destId: 'jaipur',
      destName: 'Jaipur',
      userId: 'A',
      status: TripStatus.upcoming,
    );
    final router = GoRouter(
      initialLocation: '/trips',
      routes: [
        GoRoute(path: '/trips', builder: (_, __) => const TripsLibraryPage()),
        GoRoute(
          path: '/itinerary',
          builder: (_, state) => Scaffold(
            body: Text('Opened ${(state.extra as TripItineraryModel).id}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('A'),
          userTripsStreamProvider.overrideWith(
            (_) => Stream.value([
              trip,
              const TripItineraryModel(
                id: 'other',
                uuid: 'other',
                destId: 'goa',
                destName: 'Other account',
                userId: 'B',
              ),
            ]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jaipur'), findsOneWidget);
    expect(find.text('Other account'), findsNothing);
    await tester.tap(find.text('Jaipur'));
    await tester.pumpAndSettle();
    expect(find.text('Opened saved'), findsOneWidget);
  });
}
