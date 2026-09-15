import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';

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
      'correctly synthesizes authentic day plans for destinations like Rishikesh when missing',
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
        expect(trip.totalDays, 3);
        expect(trip.dayPlans.length, 3);
        expect(trip.dayPlans.first.activities.isNotEmpty, isTrue);
        expect(trip.dayPlans.first.theme, isNotEmpty);
        // Ensure day plans contain authentic activities
        expect(trip.dayPlans.every((dp) => dp.activities.isNotEmpty), isTrue);
      },
    );
  });
}
