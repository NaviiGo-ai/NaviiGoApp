import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_provider.dart';
import 'package:naviigo_app/features/explore/presentation/pages/transportation_page.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/widgets/itinerary_overview_widgets.dart';

void main() {
  testWidgets('chapter grows around wrapping metadata at narrow widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(353, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final trip = TripItineraryModel.fromMap('test', {
      'destId': 'jaipur',
      'destName': 'Jaipur',
      'dayPlans': [
        {
          'day': 1,
          'dateFormatted': 'Wednesday, 21 October 2026',
          'theme': 'Mirza Ismail Road & Temple Trail',
          'areaFocus': 'Historic city centre and surrounding gardens',
          'activities': [
            {
              'title':
                  'A very long historical temple and architectural walking tour',
              'time': '09:00 AM',
            },
            {
              'title': 'Lunch at a local restaurant near the ancient market',
              'time': '01:00 PM',
            },
            {
              'title': 'Ram Niwas Public Gardens and surrounding heritage',
              'time': '04:00 PM',
            },
          ],
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ItineraryChapterCard(
                index: 0,
                totalCount: 1,
                dayPlan: trip.dayPlans.first,
                onExploreDay: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('VIEW DAY DETAILS'), findsOneWidget);
  });
  testWidgets(
    'flight search survives a 65 second cold start and displays the response',
    (tester) async {
      final reply = Completer<http.Response>();
      final client = ApiClient(httpClient: MockClient((_) => reply.future));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(client)],
          child: const MaterialApp(home: TransportationPage()),
        ),
      );
      await tester.tap(find.text('Flights'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search flight prices'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 65));
      expect(find.textContaining('Still searching'), findsOneWidget);
      expect(find.textContaining('unavailable right now'), findsNothing);
      reply.complete(
        http.Response(
          '{"results":[{"airline":"Test airline","price":5706,"departure":"09:00","arrival":"15:00","stops":1,"durationMinutes":360}]}',
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('5706'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
