import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:naviigo_app/core/cache/hive_service.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> itineraryBox;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'naviigo-trip-cache-',
    );
    Hive.init(hiveDirectory.path);
    itineraryBox = await Hive.openBox<dynamic>(HiveService.itineraryBoxName);
  });

  setUp(() async {
    await itineraryBox.clear();
  });

  tearDownAll(() async {
    await itineraryBox.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  Map<String, dynamic> payload({
    required String id,
    String? userId,
    bool ephemeral = false,
  }) {
    return {
      'id': id,
      'uuid': id,
      'destId': 'jaipur',
      'destName': 'Jaipur',
      if (userId != null) 'userId': userId,
      if (ephemeral) 'isEphemeral': true,
      'form': {'days': 1},
      'dayPlans': [
        {
          'day': 1,
          'activities': [
            {'title': 'Amber Fort'},
          ],
        },
      ],
    };
  }

  test(
    'a cache entry is never read by another owner with the same trip ID',
    () async {
      await HiveService.cacheItinerary(
        'owner-a',
        'shared-trip',
        payload(id: 'shared-trip', userId: 'owner-a'),
      );
      expect(
        HiveService.getCachedItinerary('owner-a', 'shared-trip'),
        containsPair('userId', 'owner-a'),
      );
      expect(HiveService.getCachedItinerary('owner-b', 'shared-trip'), isNull);

      await HiveService.cacheItinerary(
        'owner-b',
        'shared-trip',
        payload(id: 'shared-trip', userId: 'owner-b'),
      );
      expect(
        HiveService.getCachedItinerary('owner-a', 'shared-trip'),
        containsPair('userId', 'owner-a'),
      );
      expect(
        HiveService.getCachedItinerary('owner-b', 'shared-trip'),
        containsPair('userId', 'owner-b'),
      );
    },
  );

  test(
    'signed-out, ownerless, mismatched, and ephemeral records fail closed',
    () async {
      await itineraryBox.put(
        'legacy-ownerless',
        payload(id: 'legacy-ownerless'),
      );
      await itineraryBox.put(
        'legacy-other-owner',
        payload(id: 'legacy-other-owner', userId: 'owner-b'),
      );
      await itineraryBox.put(
        'legacy-ephemeral',
        payload(id: 'legacy-ephemeral', userId: 'owner-a', ephemeral: true),
      );

      expect(HiveService.getCachedItinerary('', 'legacy-ownerless'), isNull);
      expect(
        HiveService.getCachedItinerary('owner-a', 'legacy-ownerless'),
        isNull,
      );
      expect(
        HiveService.getCachedItinerary('owner-a', 'legacy-other-owner'),
        isNull,
      );
      expect(
        HiveService.getCachedItinerary('owner-a', 'legacy-ephemeral'),
        isNull,
      );
      expect(HiveService.getCachedItineraries('owner-a'), isEmpty);
    },
  );

  test(
    'cache preserves the complete model payload without adding cache metadata',
    () async {
      final createdAt = DateTime(2026, 10, 1, 9, 30);
      final updatedAt = DateTime(2026, 10, 2, 10, 45);
      final trip = TripItineraryModel.fromMap('complete-trip', {
        'id': 'complete-trip',
        'uuid': 'complete-uuid',
        'destId': 'jaipur',
        'destName': 'Royal Jaipur',
        'userId': 'owner-a',
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'generationMetadata': {'model': 'gemini', 'weather': null},
        'warnings': ['Arrive early'],
        'costSummary': {'currency': 'INR', 'total': 24000},
        'status': 'planned',
        'form': {'days': 1, 'startDate': '2026-10-10', 'budget': 24000},
        'generatedData': {
          'source': 'backend',
          'raw': {'kept': true},
        },
        'dayPlans': [
          {
            'day': 7,
            'theme': 'Forts and palaces',
            'areaFocus': 'Amer',
            'weatherContext': 'Clear',
            'date': 'Oct 10, 2026',
            'activities': [
              {
                'title': 'Amber Fort',
                'time': '09:00',
                'description': 'Morning visit',
                'location': 'Devisinghpura',
                'category': 'Heritage',
                'duration': '3 hours',
                'estimatedCost': '₹1200',
                'whyItFits': 'History interest',
                'placeId': 'amber-fort',
                'lat': 26.9855,
                'lng': 75.8513,
                'bookingRequirement': 'Reserve ahead',
                'warnings': ['Wear comfortable shoes'],
                'mealContext': 'Breakfast nearby',
                'transferOrigin': 'Hotel',
                'transferDestination': 'Amber Fort',
                'transferMode': 'car',
                'source': 'grounded',
              },
            ],
          },
        ],
      });

      await HiveService.cacheItinerary('owner-a', trip.id, trip.toMap());
      final cached = HiveService.getCachedItinerary('owner-a', trip.id);
      expect(cached, isNotNull);
      expect(cached, isNot(contains('kind')));
      expect(cached, isNot(contains('cachedAt')));

      final restored = TripItineraryModel.fromMap(trip.id, cached!);
      expect(restored.toMap(), trip.toMap());
      expect(restored.dayPlans.single.dayNumber, 7);
      expect(restored.dayPlans.single.activities.single.placeId, 'amber-fort');
      expect(restored.dayPlans.single.activities.single.lat, 26.9855);
      expect(restored.dayPlans.single.activities.single.lng, 75.8513);
      expect(restored.costSummary, {'currency': 'INR', 'total': 24000});
    },
  );

  test(
    'owner cleanup leaves another account and raw check-ins untouched',
    () async {
      await HiveService.cacheItinerary(
        'owner-a',
        'a-trip',
        payload(id: 'a-trip', userId: 'owner-a'),
      );
      await HiveService.cacheItinerary(
        'owner-b',
        'b-trip',
        payload(id: 'b-trip', userId: 'owner-b'),
      );
      await itineraryBox.put('trip_checkins_b-trip', {'checkIn': true});

      await HiveService.clearItineraryCacheForUser('owner-a');

      expect(HiveService.getCachedItinerary('owner-a', 'a-trip'), isNull);
      expect(
        HiveService.getCachedItinerary('owner-b', 'b-trip'),
        containsPair('userId', 'owner-b'),
      );
      expect(itineraryBox.get('trip_checkins_b-trip'), {'checkIn': true});
    },
  );
}
