import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/firebase_client.dart';
import '../../../core/constants/master_destinations.dart';
import '../domain/models/trip_itinerary_model.dart';

class ItineraryGenerationResponseException implements Exception {
  final String message;

  const ItineraryGenerationResponseException([
    this.message = 'The itinerary service returned malformed generation data.',
  ]);

  @override
  String toString() => message;
}

class TripRepository {
  final FirebaseFirestore _firestore;
  final ApiClient _apiClient;
  final String? Function() _currentUserUid;

  TripRepository({
    FirebaseFirestore? firestore,
    ApiClient? apiClient,
    String? Function()? currentUserUid,
  }) : _firestore = firestore ?? FirebaseClient.firestore,
       _apiClient = apiClient ?? ApiClient(),
       _currentUserUid =
           currentUserUid ?? (() => FirebaseClient.auth.currentUser?.uid);

  /// Stream user itineraries directly from users/{uid}/itineraries in naviigo-db
  Stream<List<TripItineraryModel>> getUserTripsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .snapshots()
        .map((snapshot) {
          final trips = snapshot.docs.map((doc) {
            return TripItineraryModel.fromFirestore(doc);
          }).toList();

          // Sort descending by updated / created date
          trips.sort((a, b) {
            final timeA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
            final timeB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });

          // Cache trips locally in Hive for offline access. `status` travels
          // with them: a restart with no network must still resolve the active
          // journey from its lifecycle, never from today's date.
          for (final trip in trips) {
            HiveService.cacheItinerary(trip.id, {
              'id': trip.id,
              'uuid': trip.uuid,
              'destId': trip.destId,
              'destName': trip.destName,
              'userId': trip.userId,
              'form': trip.form,
              'generatedData': trip.generatedData,
              'isActive': trip.isActive,
              if (trip.status != null) 'status': trip.status!.wireName,
              'updatedAt': trip.updatedAt?.toIso8601String(),
            });
          }

          return trips;
        });
  }

  /// Get trip by ID: checks Firestore first, falls back to Hive local cache if offline
  Future<TripItineraryModel?> getTripById(String uid, String tripId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .doc(tripId)
          .get();

      if (doc.exists) {
        return TripItineraryModel.fromFirestore(doc);
      }

      // Check root itineraries collection
      final rootDoc = await _firestore
          .collection('itineraries')
          .doc(tripId)
          .get();
      if (rootDoc.exists) {
        return TripItineraryModel.fromFirestore(rootDoc);
      }
    } catch (e) {
      debugPrint(
        '[TripRepository] Firestore fetch failed, checking offline cache: $e',
      );
    }

    // Offline cache fallback
    final cached = HiveService.getCachedItinerary(tripId);
    if (cached != null) {
      return TripItineraryModel.fromMap(tripId, cached);
    }

    return null;
  }

  /// Save or update trip - mirrors to both users/{uid}/itineraries/{id} and root itineraries/{id}
  Future<String> saveTrip(String uid, TripItineraryModel trip) async {
    final now = FieldValue.serverTimestamp();
    final dayPlansData = trip.dayPlans
        .map(
          (dp) => {
            'day': dp.dayNumber,
            'theme': dp.theme,
            'date': dp.dateFormatted,
            'activities': dp.activities.map((a) => a.toMap()).toList(),
          },
        )
        .toList();

    final Map<String, dynamic> genData = Map<String, dynamic>.from(
      trip.generatedData ?? {},
    );
    if (dayPlansData.isNotEmpty) {
      genData['dayPlans'] = dayPlansData;
    }

    final data = {
      'id': trip.id,
      'uuid': trip.uuid,
      'destId': trip.destId,
      'destName': trip.destName,
      'userId': uid,
      'form': trip.form,
      'dayPlans': dayPlansData,
      'generatedData': genData,
      'isActive': trip.isActive,
      'isPublic': trip.isPublic,
      if (trip.status != null) 'status': trip.status!.wireName,
      'updatedAt': now,
    };

    // User subcollection
    final userDocRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .doc(trip.id);

    final snap = await userDocRef.get();
    if (!snap.exists) {
      data['createdAt'] = now;
      // Increment total trips on user profile
      try {
        await _firestore.collection('users').doc(uid).update({
          'totalTrips': FieldValue.increment(1),
          'lastLogin': now,
        });
      } catch (_) {}
    }

    await userDocRef.set(data, SetOptions(merge: true));

    // Only mirror to the public root collection when the traveller has
    // explicitly shared this journey. Mirroring unconditionally made every
    // private itinerary world-readable at `itineraries/{id}`.
    if (trip.isPublic) {
      try {
        final rootData = {...data, 'userId': uid, 'isPublic': true};
        await _firestore
            .collection('itineraries')
            .doc(trip.id)
            .set(rootData, SetOptions(merge: true));
      } catch (e) {
        debugPrint(
          '[TripRepository] Non-fatal mirror to root itineraries failed: $e',
        );
      }
    } else {
      // Clear any previously public copy so un-sharing actually un-publishes.
      try {
        await _firestore.collection('itineraries').doc(trip.id).delete();
      } catch (e) {
        debugPrint('[TripRepository] Could not clear public mirror: $e');
      }
    }

    // Cache locally
    await HiveService.cacheItinerary(trip.id, {
      'id': trip.id,
      'uuid': trip.uuid,
      'destId': trip.destId,
      'destName': trip.destName,
      'userId': uid,
      'form': trip.form,
      'dayPlans': dayPlansData,
      'generatedData': genData,
      'isActive': trip.isActive,
      if (trip.status != null) 'status': trip.status!.wireName,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return trip.id;
  }

  /// Mark an itinerary as the active trip.
  ///
  /// Two journeys must never read as ACTIVE at once, so any other trip that
  /// currently claims `isActive` also has its stale `status` cleared — it then
  /// derives its lifecycle from its own dates rather than lying. Callers that
  /// deliberately intend to end another journey do that explicitly first, via
  /// [endTrip].
  Future<void> setActiveTrip(String uid, String activeTripId) async {
    final userItinCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries');
    final allDocs = await userItinCol.get();

    final batch = _firestore.batch();
    for (final doc in allDocs.docs) {
      if (doc.id == activeTripId) {
        batch.update(doc.reference, {
          'isActive': true,
          'status': TripStatus.active.wireName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (doc.data()['isActive'] == true) {
        batch.update(doc.reference, {
          'isActive': false,
          'status': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  /// End a journey the traveller chose to leave. Terminal, so it can never
  /// reappear as the active trip whatever its dates say.
  Future<void> endTrip(String uid, String tripId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .doc(tripId)
        .set({
          'isActive': false,
          'status': TripStatus.cancelled.wireName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Delete itinerary from user subcollection and root collection
  Future<void> deleteTrip(String uid, String tripId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .doc(tripId)
          .delete();
      await _firestore.collection('itineraries').doc(tripId).delete();
      await HiveService.itineraryBox.delete(tripId);
    } catch (e) {
      debugPrint('[TripRepository] deleteTrip error: $e');
    }
  }

  /// Generate itinerary from Render FastAPI backend using Gemini AI Engine & Destination Cache
  Future<TripItineraryModel> generateItineraryFromBackend({
    required String destName,
    String? destination,
    required int days,
    String purpose = 'cultural',
    String group = 'solo',
    int budget = 15000,
    String? startDate,
    String travelerType = 'comfort',
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? browsingSignals,
    String? arrivalTime,
    String? arrivalMode,
    String? departureTime,
    String? departureMode,
    String? hotelArea,
    String? originCity,
    List<Map<String, dynamic>>? mustDo,
    List<Map<String, dynamic>>? routeStops,
    required String expectedAuthUid,
  }) async {
    if (expectedAuthUid.trim().isEmpty ||
        _currentUserUid() != expectedAuthUid) {
      throw const AuthRequiredException(
        'Your account is no longer available for this request.',
      );
    }

    final trimmedDestName = destName.trim();
    if (trimmedDestName.isEmpty) {
      throw const ValidationException(
        'Choose a supported destination before generating an itinerary.',
      );
    }
    if (days < 1 || days > 14) {
      throw const ValidationException(
        'Journey duration must be between 1 and 14 days.',
      );
    }
    if (budget < 0) {
      throw const ValidationException('Journey budget cannot be negative.');
    }
    if (destination != null && destination.trim().isEmpty) {
      throw const ValidationException(
        'The destination identifier cannot be empty.',
      );
    }
    final supportedDestination = findDestinationById(destination ?? destName);
    if (supportedDestination == null) {
      throw const ValidationException(
        'Choose a destination from the supported registry.',
      );
    }
    final canonicalDestinationId = supportedDestination.id;
    if (startDate != null && startDate.trim().isEmpty) {
      throw const ValidationException('The departure date cannot be empty.');
    }
    const supportedTravelerTypes = {
      'backpacker',
      'comfort',
      'luxury',
      'family',
      'flash',
      'slow',
    };
    if (!supportedTravelerTypes.contains(travelerType)) {
      throw const ValidationException(
        'Choose a supported traveler preset before generating an itinerary.',
      );
    }
    const supportedGroups = {'solo', 'couple', 'family', 'friends', 'large'};
    if (!supportedGroups.contains(group)) {
      throw const ValidationException(
        'Choose a supported travel group before generating an itinerary.',
      );
    }

    final payload = {
      'destName': trimmedDestName,
      if (destination != null) 'destination': destination.trim(),
      'purpose': purpose,
      'group': group,
      'days': days,
      'budget': budget,
      if (startDate != null) 'startDate': startDate.trim(),
      'travelerType': travelerType,
      if (preferences != null) 'preferences': preferences,
      if (browsingSignals != null) 'browsingSignals': browsingSignals,
      if (arrivalTime != null) 'arrivalTime': arrivalTime,
      if (arrivalMode != null) 'arrivalMode': arrivalMode,
      if (departureTime != null) 'departureTime': departureTime,
      if (departureMode != null) 'departureMode': departureMode,
      if (hotelArea != null) 'hotelArea': hotelArea,
      if (originCity != null) 'originCity': originCity,
      if (mustDo != null) 'mustDo': mustDo,
      if (routeStops != null) 'routeStops': routeStops,
    };

    final response = await _apiClient.post(
      '/api/itinerary/generate',
      body: payload,
      requiresAuth: true,
      timeout: AppConfig.aiGenerationTimeout,
      expectedAuthUid: expectedAuthUid,
    );

    if (_currentUserUid() != expectedAuthUid) {
      throw const AuthRequiredException(
        'Your account changed while the itinerary was generating.',
      );
    }

    if (response is! Map || response['success'] != true) {
      throw const ItineraryGenerationResponseException(
        'The itinerary service returned an invalid generation response.',
      );
    }

    final responseUid = response['userId'];
    if (responseUid is! String || responseUid.trim() != expectedAuthUid) {
      throw const ItineraryGenerationResponseException(
        'The itinerary response owner could not be verified.',
      );
    }

    final itineraryRaw = response['itinerary'];
    if (itineraryRaw is! Map) {
      throw const ItineraryGenerationResponseException(
        'The itinerary service returned no itinerary data.',
      );
    }

    final itinData = Map<String, dynamic>.from(itineraryRaw);
    _validateGeneratedItinerary(itinData);

    final responseId = _nonEmptyString(itinData['id']);
    final responseUuid = _nonEmptyString(itinData['uuid']);
    final tripId =
        responseId ??
        responseUuid ??
        'generated_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final responseMetadata = <String, dynamic>{
      if (response['source'] is String) 'source': response['source'],
      if (response['dataSources'] is List)
        'dataSources': List<dynamic>.from(response['dataSources'] as List),
    };

    // The direct backend route has no durable ID/receipt contract. Keep this
    // result ephemeral and let the explicit result screen render it; do not
    // issue a second client-side save that could be mistaken for authoritative
    // persistence.
    return TripItineraryModel.fromMap(tripId, {
      'id': responseId ?? tripId,
      'uuid': responseUuid ?? responseId ?? tripId,
      'destId': canonicalDestinationId,
      'destName': trimmedDestName,
      'userId': expectedAuthUid,
      'form': payload,
      'generatedData': itinData,
      if (responseMetadata.isNotEmpty) 'generationMetadata': responseMetadata,
      'isActive': false,
      'isEphemeral': true,
      'createdAt': itinData['createdAt'] ?? now,
      'updatedAt': itinData['updatedAt'] ?? now,
    });
  }

  static String? _nonEmptyString(dynamic value) {
    if (value is! String) return null;
    final stringValue = value.trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  static dynamic _firstPresent(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) return data[key];
    }
    return null;
  }

  static void _validateGeneratedItinerary(Map<String, dynamic> itinerary) {
    if (itinerary.isEmpty) {
      throw const ItineraryGenerationResponseException(
        'The itinerary service returned an empty itinerary.',
      );
    }

    final rawPlans = _firstPresent(itinerary, const [
      'dayPlans',
      'days',
      'dailyPlans',
      'itinerary',
      'schedule',
      'plan',
    ]);
    if (rawPlans is! List || rawPlans.isEmpty) {
      throw const ItineraryGenerationResponseException(
        'The itinerary service returned no usable day plans.',
      );
    }

    var hasActivity = false;
    for (final rawPlan in rawPlans) {
      if (rawPlan is! Map) {
        throw const ItineraryGenerationResponseException(
          'The itinerary service returned malformed day plan data.',
        );
      }

      final plan = Map<String, dynamic>.from(rawPlan);
      final rawActivities = _firstPresent(plan, const [
        'activities',
        'items',
        'schedule',
      ]);
      if (rawActivities is! List) {
        throw const ItineraryGenerationResponseException(
          'The itinerary service returned malformed activity data.',
        );
      }

      for (final rawActivity in rawActivities) {
        if (rawActivity is! Map) {
          throw const ItineraryGenerationResponseException(
            'The itinerary service returned malformed activity data.',
          );
        }
        final activity = Map<String, dynamic>.from(rawActivity);
        final rawTitle = activity['title'] ?? activity['name'];
        if (rawTitle is! String || rawTitle.trim().isEmpty) {
          throw const ItineraryGenerationResponseException(
            'The itinerary service returned an activity without a name.',
          );
        }
        hasActivity = true;
      }
    }

    if (!hasActivity) {
      throw const ItineraryGenerationResponseException(
        'The itinerary service returned no usable activities.',
      );
    }
  }
}
