import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/trip_itinerary_model.dart';

class TripRepository {
  final FirebaseFirestore _firestore;
  final ApiClient _apiClient;

  TripRepository({FirebaseFirestore? firestore, ApiClient? apiClient})
    : _firestore = firestore ?? FirebaseClient.firestore,
      _apiClient = apiClient ?? ApiClient();

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
  }) async {
    final payload = {
      'destName': destName,
      'destination': destination ?? destName.toLowerCase().replaceAll(' ', ''),
      'purpose': purpose,
      'group': group,
      'days': days,
      'budget': budget,
      'startDate':
          startDate ??
          DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String()
              .split('T')[0],
      'travelerType': travelerType,
    };

    final response = await _apiClient.post(
      '/api/itinerary/generate',
      body: payload,
      requiresAuth: true,
      timeout: AppConfig.aiGenerationTimeout,
    );

    if (response is Map && response['itinerary'] != null) {
      final itinData = response['itinerary'] as Map<String, dynamic>;
      final tripId =
          (itinData['id'] ?? 'trip_${DateTime.now().millisecondsSinceEpoch}')
              .toString();

      // The owner is stamped at creation. Start-trip validation treats an
      // owner-less journey as unverifiable and refuses to begin it, so a trip
      // that never carried one would be unstartable.
      final uid = FirebaseClient.auth.currentUser?.uid;

      final tripModel = TripItineraryModel.fromMap(tripId, {
        'id': tripId,
        'uuid': tripId,
        'destId': payload['destination'],
        'destName': destName,
        if (uid != null) 'userId': uid,
        'form': payload,
        'generatedData': itinData,
        'isActive': false,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      // Save to Firebase & local cache
      if (uid != null) {
        await saveTrip(uid, tripModel);
      }
      return tripModel;
    }

    throw const ServerException(
      'Invalid response received from itinerary generation engine.',
    );
  }
}
