import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_provider.dart';
import 'package:naviigo_app/features/explore/presentation/pages/transportation_page.dart';
import 'package:naviigo_app/features/explore/presentation/providers/explore_provider.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/widgets/itinerary_overview_widgets.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';
import 'package:naviigo_app/features/more/presentation/pages/story_creator_page.dart';
import 'package:naviigo_app/features/explore/presentation/widgets/discovery_widgets.dart';

void main() {
  testWidgets(
    'unavailable story photo stays neutral and an account change clears the preview',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final uid = StateProvider<String?>((_) => 'A');
      final pending = Completer<Map<String, dynamic>>();
      final trip = TripItineraryModel.fromMap('story-trip', {
        'userId': 'A',
        'destId': 'manali',
        'destName': 'Manali',
        'dayPlans': [
          {'day': 1, 'activities': []},
        ],
      });
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(uid)),
          userTripsStreamProvider.overrideWith((_) => Stream.value([trip])),
          destinationPhotoProvider('Manali').overrideWith((_) async => {}),
          reusableDestinationPhotoProvider(
            'Manali',
          ).overrideWith((_) => pending.future),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: StoryCreatorPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE TO TEMPLATES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GENERATE 9:16 PREVIEW'));
      await tester.pumpAndSettle();
      expect(find.text('MANALI'), findsOneWidget);
      final wrongCover = find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final image = (widget.decoration as BoxDecoration).image?.image;
        return image is AssetImage && image.assetName.contains('india-cover');
      });
      expect(wrongCover, findsNothing);
      expect(tester.takeException(), isNull);
      container.read(uid.notifier).state = 'B';
      await tester.pumpAndSettle();
      expect(find.text('MANALI'), findsNothing);
      expect(find.text('Select a Journey'), findsOneWidget);
    },
  );
  test(
    'DDN resolves locally without waiting for an unavailable provider',
    () async {
      var requests = 0;
      final client = ApiClient(
        httpClient: MockClient((_) async {
          requests++;
          return http.Response('unavailable', 503);
        }),
      );
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);
      final provider = exploreSearchProvider((query: 'DDN', ownerUid: 'A'));
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      final result = await container.read(provider.future);
      expect(result.status, ExploreSearchStatus.success);
      expect(result.destinations.single.id, 'dehradun');
      expect(requests, 0);
    },
  );
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
