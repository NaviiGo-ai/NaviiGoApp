import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/bookings/domain/models/booking_model.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:naviigo_app/features/dashboard/presentation/pages/live_tracking_page.dart';
import 'package:naviigo_app/features/trips/domain/models/live_trip_state.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/providers/live_trip_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

String _todayIso() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

TripItineraryModel _trip({bool isActive = false, String? status}) {
  return TripItineraryModel.fromMap('trip_live_1', {
    'destId': 'jaipur',
    'destName': 'Jaipur Royal Tour',
    'userId': 'pilot_1',
    if (status != null) 'status': status,
    'isActive': isActive,
    'form': {'startDate': _todayIso(), 'days': 1},
    'dayPlans': [
      {
        'day': 1,
        'theme': 'Forts',
        'activities': [
          {'title': 'Amber Fort', 'time': '09:00 AM', 'location': 'Amer'},
          {'title': 'City Palace', 'time': '02:00 PM'},
        ],
      },
    ],
  });
}

LiveFix _at(double lat, double lng) =>
    LiveFix(lat: lat, lng: lng, timestamp: DateTime.now());

LiveFix _delhi() => _at(28.6139, 77.2090);
LiveFix _jaipur() => _at(26.9150, 75.7900);

Widget _harness({
  required TripItineraryModel? trip,
  LiveFix? fix,
  bool hasPermission = true,
  bool isOffline = false,
  List<BookingModel> bookings = const [],
  List<TripItineraryModel>? trips,
  TripItineraryModel? initialTrip,
}) {
  return ProviderScope(
    overrides: [
      activeTripProvider.overrideWithValue(trip),
      userTripsStreamProvider.overrideWith((ref) => Stream.value(
            trips ?? (trip == null ? <TripItineraryModel>[] : [trip]),
          )),
      bookingsStreamProvider.overrideWith((ref) => Stream.value(bookings)),
      checkInStoreProvider.overrideWithValue(InMemoryCheckInStore()),
      currentUserIdProvider.overrideWithValue('pilot_1'),
      liveTripPermissionProvider.overrideWith((ref) => hasPermission),
      liveTripFixProvider.overrideWith((ref) => fix),
      liveTripOfflineProvider.overrideWith((ref) => isOffline),
    ],
    child: MaterialApp(home: LiveTrackingPage(initialTrip: initialTrip)),
  );
}

void main() {
  group('LiveTrackingPage — no journey', () {
    testWidgets('idles honestly when there is nothing to track', (tester) async {
      await tester.pumpWidget(_harness(trip: null));
      await tester.pumpAndSettle();

      expect(find.text('Tracking Idle'), findsOneWidget);
      expect(find.text('LIVE JOURNEY'), findsOneWidget);
    });

    testWidgets('judges the journey it was opened for, not the list head',
        (tester) async {
      // Another, unrelated journey the traveller is not about to start. It comes
      // first in the stream, which is exactly the trip a positional fallback
      // would have wrongly judged.
      final unrelated = TripItineraryModel.fromMap('trip_other', {
        'destId': 'udaipur',
        'destName': 'Udaipur Lakes',
        'userId': 'pilot_1',
        'isActive': false,
        'form': {'startDate': _todayIso(), 'days': 1},
        'dayPlans': [
          {
            'day': 1,
            'activities': [
              {'title': 'Lake Pichola'},
            ],
          },
        ],
      });
      final tapped = _trip();

      await tester.pumpWidget(_harness(
        trip: null,
        trips: [unrelated, tapped],
        initialTrip: tapped,
        fix: _jaipur(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('START JOURNEY'), findsOneWidget);
      expect(find.textContaining('Jaipur'), findsWidgets);
      expect(find.textContaining('Udaipur'), findsNothing);
    });
  });

  group('LiveTrackingPage — start gate', () {
    testWidgets('at the start region the journey can be begun', (tester) async {
      await tester.pumpWidget(_harness(trip: _trip(), fix: _jaipur()));
      await tester.pumpAndSettle();

      expect(find.text('START JOURNEY'), findsOneWidget);
      expect(find.textContaining('Jaipur'), findsWidgets);
    });

    testWidgets('wrong city renders distance and every recovery action',
        (tester) async {
      await tester.pumpWidget(_harness(trip: _trip(), fix: _delhi()));
      await tester.pumpAndSettle();

      expect(find.text('NOT AT THE START YET'), findsOneWidget);
      expect(find.text('This journey begins in Jaipur.'), findsOneWidget);
      expect(find.textContaining('FROM JAIPUR'), findsOneWidget);

      // All four documented recovery options.
      expect(find.text('TRY LOCATION AGAIN'), findsOneWidget);
      expect(find.text('Get Directions'), findsOneWidget);
      expect(find.text('View Trip'), findsOneWidget);
      expect(find.text('Pre-Trip Mode'), findsOneWidget);
    });

    testWidgets('a denied permission is named, not glossed over',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(), hasPermission: false, fix: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOCATION NOT VERIFIED'), findsOneWidget);
      expect(find.text('VERIFY YOUR START'), findsOneWidget);
      // Naviigo's own words, not a permission constant.
      expect(
        find.textContaining('Naviigo uses your location'),
        findsOneWidget,
      );
    });

    testWidgets('pre-trip mode drops the start offer and shows the plan',
        (tester) async {
      await tester.pumpWidget(_harness(trip: _trip(), fix: _delhi()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Pre-Trip Mode'));
      await tester.tap(find.text('Pre-Trip Mode'));
      await tester.pumpAndSettle();

      expect(find.text('PRE-TRIP MODE'), findsOneWidget);
      expect(find.text('VIEW TRIP'), findsOneWidget);
      expect(find.text('TRY LOCATION AGAIN'), findsNothing);
      expect(find.text('START JOURNEY'), findsNothing);
    });
  });

  group('LiveTrackingPage — in motion', () {
    testWidgets('shows the NOW / NEXT / ROUTE hierarchy from real state',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(isActive: true, status: 'active'), fix: _jaipur()),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      // ROUTE appears on both the preview card and the full rail.
      expect(find.text('ROUTE'), findsNWidgets(2));

      // NOW is the first unlogged waypoint, NEXT the one after it.
      expect(find.text('Amber Fort'), findsWidgets);
      expect(find.text('City Palace'), findsWidgets);
      expect(find.text('0 of 2 waypoints logged'), findsOneWidget);

      // Manual check-in is offered, and nothing is auto-completed.
      expect(find.text("I'M HERE"), findsOneWidget);
      expect(find.text('COMPLETE'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
    });

    testWidgets('COMPLETE advances the rail and says what is left',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(isActive: true, status: 'active'), fix: _jaipur()),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('COMPLETE'));
      await tester.tap(find.text('COMPLETE'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 waypoints logged'), findsOneWidget);
      expect(find.text('0 of 2 waypoints logged'), findsNothing);
    });

    testWidgets('SKIP is recorded as skipped, not as completed',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(isActive: true, status: 'active'), fix: _jaipur()),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SKIP'));
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 waypoints logged'), findsOneWidget);
      expect(
        find.textContaining('logged as skipped, not completed'),
        findsOneWidget,
      );
    });

    testWidgets('no fabricated buddy, telemetry or progress is rendered',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(isActive: true, status: 'active'), fix: _jaipur()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No buddy paired. Nobody is following this journey.'),
        findsOneWidget,
      );
      // No invented speed, ETA or battery figures anywhere on screen.
      expect(find.textContaining('km/h'), findsNothing);
      expect(find.textContaining('ETA'), findsNothing);
      expect(find.textContaining('battery'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('offline is shown only with a real last-updated label',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          trip: _trip(isActive: true, status: 'active'),
          fix: _jaipur(),
          isOffline: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('NOT YET SYNCED'), findsOneWidget);
    });

    testWidgets('route deviation states a measurement, not an alarm',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(isActive: true, status: 'active'), fix: _delhi()),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFF THE PLANNED REGION'), findsOneWidget);
      expect(find.textContaining('from Jaipur'), findsOneWidget);
      expect(
        find.textContaining('nothing is shared automatically'),
        findsOneWidget,
      );
    });

    testWidgets('safety reports a missing fix rather than inventing one',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(isActive: true, status: 'active'), fix: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('NO POSITION FIX'), findsOneWidget);
      expect(find.text('HOLD FOR 112'), findsOneWidget);
    });

    testWidgets('real vouchers for the destination are listed, others are not',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          trip: _trip(isActive: true, status: 'active'),
          fix: _jaipur(),
          bookings: const [
            BookingModel(
              id: 'b1',
              type: 'flight',
              status: 'confirmed',
              from: 'DEL',
              to: 'JAI',
              date: '2026-11-20',
              providerName: 'IndiGo',
              pnr: '6E-4521',
              totalPrice: 4200,
            ),
            BookingModel(
              id: 'b2',
              type: 'train',
              status: 'confirmed',
              from: 'MAS',
              to: 'COK',
              date: '2026-11-22',
              providerName: 'IRCTC',
              pnr: '12345',
              totalPrice: 900,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEL → JAI'), findsOneWidget);
      expect(find.text('MAS → COK'), findsNothing);
    });
  });

  group('LiveTrackingPage — closed journeys', () {
    testWidgets('a completed journey stops offering check-ins', (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(status: 'completed'), fix: _jaipur()),
      );
      await tester.pumpAndSettle();

      expect(find.text('JOURNEY COMPLETE'), findsOneWidget);
      expect(find.text('COMPLETE'), findsNothing);
      expect(find.text('START JOURNEY'), findsNothing);
    });

    testWidgets('a cancelled journey claims nothing is being tracked',
        (tester) async {
      await tester.pumpWidget(
        _harness(trip: _trip(status: 'cancelled'), fix: _jaipur()),
      );
      await tester.pumpAndSettle();

      expect(find.text('JOURNEY CANCELLED'), findsOneWidget);
      expect(
        find.text('This journey was cancelled. Nothing is being tracked.'),
        findsOneWidget,
      );
      expect(find.text('START JOURNEY'), findsNothing);
    });
  });
}
