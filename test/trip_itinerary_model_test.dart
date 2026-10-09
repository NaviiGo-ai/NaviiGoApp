import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/widgets/itinerary_overview_widgets.dart';

void main() {
  group('TripItineraryModel Unit Tests', () {
    test('correctly parses Firestore map matching website contracts', () {
      final firestoreData = {
        'destId': 'jaipur',
        'destName': 'Royal Jaipur Heritage',
        'uuid': 'trip-uuid-1234',
        'isActive': false,
        'form': {
          'destination': 'jaipur',
          'startDate': '2026-10-15',
          'days': 4,
          'purpose': 'Cultural exploration',
        },
        'generatedData': {
          'title': 'Royal Jaipur Heritage Expedition',
          'dayPlans': [
            {
              'day': 1,
              'theme': 'Forts and Palaces',
              'activities': [
                {
                  'title': 'Amber Fort Tour',
                  'time': '09:00 AM',
                  'location': 'Devisinghpura, Amer',
                  'category': 'Sightseeing',
                  'duration': '3 hours',
                },
                {
                  'title': 'City Palace Visit',
                  'time': '02:00 PM',
                  'location': 'Old City, Jaipur',
                  'category': 'Heritage',
                  'duration': '2 hours',
                },
              ],
            },
            {
              'day': 2,
              'theme': 'Bazaars and Gastronomy',
              'activities': [
                {
                  'title': 'Johari Bazaar Walk',
                  'time': '10:30 AM',
                  'location': 'Johari Bazaar',
                  'category': 'Shopping',
                },
              ],
            },
          ],
        },
      };

      final trip = TripItineraryModel.fromMap('trip-uuid-1234', firestoreData);

      expect(trip.id, 'trip-uuid-1234');
      expect(trip.uuid, 'trip-uuid-1234');
      expect(trip.destName, 'Royal Jaipur Heritage');
      expect(trip.totalDays, 2); // 2 day plans parsed
      expect(trip.dayPlans.length, 2);
      expect(trip.dayPlans.first.theme, 'Forts and Palaces');
      expect(trip.dayPlans.first.activities.length, 2);
      expect(trip.dayPlans.first.activities.first.title, 'Amber Fort Tour');
      expect(trip.startDateFormatted, contains('Oct 15, 2026'));
      expect(trip.isUpcoming, isTrue);
      expect(trip.isCurrentlyActive, isFalse);
      expect(trip.isPast, isFalse);
    });

    test('correctly identifies active trip when isActive is true', () {
      final data = {
        'destId': 'kerala',
        'destName': 'Kerala Backwaters',
        'uuid': 'trip-active-1',
        'isActive': true,
      };

      final trip = TripItineraryModel.fromMap('trip-active-1', data);
      expect(trip.isCurrentlyActive, isTrue);
      expect(trip.isUpcoming, isFalse);
      expect(trip.isPast, isFalse);
    });

    test('correctly identifies past trip based on dates', () {
      final data = {
        'destId': 'goa',
        'destName': 'Goa Beach Odyssey',
        'uuid': 'trip-past-1',
        'isActive': false,
        'form': {'startDate': '2022-01-10', 'days': 5},
      };

      final trip = TripItineraryModel.fromMap('trip-past-1', data);
      expect(trip.isPast, isTrue);
      expect(trip.isUpcoming, isFalse);
      expect(trip.isCurrentlyActive, isFalse);
    });

    test(
      'leaves day plans empty when the backend supplied none instead of inventing an itinerary',
      () {
        final data = {
          'destId': 'rishikesh',
          'destName': 'Rishikesh',
          'uuid': 'trip-rishikesh-1',
          'isActive': false,
          'form': {'startDate': '2026-09-21', 'days': 3},
        };

        final trip = TripItineraryModel.fromMap('trip-rishikesh-1', data);

        expect(trip.destName, 'Rishikesh');
        // Requested length is still surfaced for headings and date maths...
        expect(trip.totalDays, 3);
        // ...but no placeholder activities are fabricated to fill the gap.
        expect(trip.dayPlans, isEmpty);
      },
    );

    test('keeps real backend day plans intact', () {
      final data = {
        'destId': 'varanasi',
        'destName': 'Varanasi',
        'uuid': 'trip-real-1',
        'form': {'days': 1},
        'dayPlans': [
          {
            'day': 1,
            'theme': 'Ghats at Dawn',
            'activities': [
              {'title': 'Sunrise boat ride', 'time': '05:30 AM'},
            ],
          },
        ],
      };

      final trip = TripItineraryModel.fromMap('trip-real-1', data);

      expect(trip.dayPlans.length, 1);
      expect(trip.dayPlans.first.theme, 'Ghats at Dawn');
      expect(trip.dayPlans.first.activities.first.title, 'Sunrise boat ride');
    });

    test('defaults isPublic to false so journeys stay private', () {
      final trip = TripItineraryModel.fromMap('trip-priv-1', {
        'destName': 'Rishikesh',
        'uuid': 'trip-priv-1',
      });
      expect(trip.isPublic, isFalse);

      final shared = TripItineraryModel.fromMap('trip-pub-1', {
        'destName': 'Rishikesh',
        'uuid': 'trip-pub-1',
        'isPublic': true,
      });
      expect(shared.isPublic, isTrue);
    });

    testWidgets(
      'ItineraryStatsRow renders truthful 0 STOPS when itinerary has no activities',
      (tester) async {
        final emptyTrip = TripItineraryModel.fromMap('trip-empty-stops', {
          'destName': 'Varanasi',
          'uuid': 'trip-empty-stops',
          'form': {'days': 5, 'budget': 20000},
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ItineraryStatsRow(trip: emptyTrip)),
          ),
        );

        expect(find.text('0 STOPS'), findsOneWidget);
        expect(find.text('15 STOPS'), findsNothing);
      },
    );

    testWidgets(
      'ItineraryStatsRow calculates exact total waypoint count across days',
      (tester) async {
        final trip = TripItineraryModel.fromMap('trip-with-stops', {
          'destName': 'Jaipur',
          'uuid': 'trip-with-stops',
          'dayPlans': [
            {
              'day': 1,
              'activities': [
                {'title': 'Amber Fort'},
                {'title': 'City Palace'},
              ],
            },
            {
              'day': 2,
              'activities': [
                {'title': 'Hawa Mahal'},
              ],
            },
          ],
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ItineraryStatsRow(trip: trip)),
          ),
        );

        expect(find.text('3 STOPS'), findsOneWidget);
      },
    );
  });
}
