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

  bool _isCurrentUser(String uid) => uid.isNotEmpty && _currentUserUid() == uid;

  void _requireCurrentUser(String uid) {
    if (!_isCurrentUser(uid)) {
      throw const AuthRequiredException(
        'Your account is no longer available for this request.',
      );
    }
  }

  TripItineraryModel? _bindOwnedTrip(String uid, TripItineraryModel trip) {
    if (trip.userId != null && trip.userId != uid) return null;
    if (trip.isEphemeral) return null;
    // The Firestore path or cache envelope is authoritative ownership when a
    // legacy model omitted userId. Bind it before exposing the model so a
    // retained provider value cannot be mistaken for another account's trip.
    return trip.userId == uid ? trip : trip.copyWith(userId: uid);
  }

  List<TripItineraryModel> _readCachedTrips(String uid) {
    final trips = <TripItineraryModel>[];
    for (final payload in HiveService.getCachedItineraries(uid)) {
      final rawId = payload['id'];
      if (rawId is! String || rawId.isEmpty) continue;
      try {
        final trip = _bindOwnedTrip(
          uid,
          TripItineraryModel.fromMap(rawId, payload),
        );
        if (trip != null) trips.add(trip);
      } catch (_) {
        // A malformed local payload is not usable offline data.
      }
    }
    _sortTrips(trips);
    return trips;
  }

  TripItineraryModel? _readCachedTrip(String uid, String tripId) {
    final cached = HiveService.getCachedItinerary(uid, tripId);
    if (cached == null) return null;
    try {
      return _bindOwnedTrip(uid, TripItineraryModel.fromMap(tripId, cached));
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheTrip(String uid, TripItineraryModel trip) async {
    if (!_isCurrentUser(uid) || trip.isEphemeral) return;
    try {
      await HiveService.cacheItinerary(uid, trip.id, trip.toMap());
    } catch (e) {
      // Firestore remains authoritative; a local cache failure is non-fatal.
      debugPrint('[TripRepository] Could not cache itinerary ${trip.id}: $e');
    }
  }

  static void _sortTrips(List<TripItineraryModel> trips) {
    trips.sort((a, b) {
      final timeA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final timeB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return timeB.compareTo(timeA);
    });
  }

  /// Stream user itineraries directly from users/{uid}/itineraries in
  /// naviigo-db.
  /// A same-owner cache is emitted before the authoritative stream when useful.
  Stream<List<TripItineraryModel>> getUserTripsStream(String uid) {
    Stream<List<TripItineraryModel>> stream() async* {
      _requireCurrentUser(uid);

      var lastUsableTrips = _readCachedTrips(uid);
      var hasLastUsableData = lastUsableTrips.isNotEmpty;
      if (lastUsableTrips.isNotEmpty) yield lastUsableTrips;

      try {
        await for (final snapshot
            in _firestore
                .collection('users')
                .doc(uid)
                .collection('itineraries')
                .snapshots()) {
          // A late event from account A must not be exposed or cached after
          // the session has moved to account B.
          if (!_isCurrentUser(uid)) {
            yield const [];
            return;
          }

          final trips = <TripItineraryModel>[];
          for (final doc in snapshot.docs) {
            final parsed = _bindOwnedTrip(
              uid,
              TripItineraryModel.fromFirestore(doc),
            );
            if (parsed != null) trips.add(parsed);
          }
          _sortTrips(trips);

          if (!_isCurrentUser(uid)) {
            yield const [];
            return;
          }
          try {
            await HiveService.replaceCachedItineraries(
              uid,
              trips.map((trip) => trip.toMap()),
            );
          } catch (e) {
            debugPrint(
              '[TripRepository] Could not refresh itinerary cache: $e',
            );
          }
          if (!_isCurrentUser(uid)) {
            yield const [];
            return;
          }

          lastUsableTrips = trips;
          hasLastUsableData = true;
          yield trips;
        }
      } catch (error, stackTrace) {
        if (!_isCurrentUser(uid)) {
          yield const [];
          return;
        }
        if (hasLastUsableData) {
          // Keep the last verified same-user data during a transport failure.
          yield lastUsableTrips;
          return;
        }
        // Without a usable cache, preserve the existing error signal instead
        // of manufacturing an empty successful list.
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    return stream();
  }

  /// Gets an owner-bound itinerary, falling back only to that owner's cache.
  Future<TripItineraryModel?> getTripById(String uid, String tripId) async {
    _requireCurrentUser(uid);
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .doc(tripId)
          .get();
      _requireCurrentUser(uid);

      if (doc.exists) {
        final trip = _bindOwnedTrip(uid, TripItineraryModel.fromFirestore(doc));
        if (trip == null) return null;
        await _cacheTrip(uid, trip);
        _requireCurrentUser(uid);
        return trip;
      }

      // A confirmed authoritative miss means this trip is no longer present.
      // Cache fallback is reserved for transport failures, so stale deleted
      // data cannot be resurrected as a current trip.
      try {
        await HiveService.deleteCachedItinerary(uid, tripId);
      } catch (cacheError) {
        debugPrint(
          '[TripRepository] Could not clear deleted itinerary cache: $cacheError',
        );
      }
      return null;
    } catch (e) {
      if (e is AuthRequiredException) rethrow;
      debugPrint(
        '[TripRepository] Firestore fetch failed, checking offline cache: $e',
      );
      _requireCurrentUser(uid);
      return _readCachedTrip(uid, tripId);
    }
  }

  /// Saves to the authoritative owner path, then updates the local cache.
  Future<String> saveTrip(String uid, TripItineraryModel trip) async {
    _requireCurrentUser(uid);
    if (trip.id.isEmpty) {
      throw const ValidationException('An itinerary ID is required to save.');
    }
    if (trip.userId != null && trip.userId != uid) {
      throw const ForbiddenException(
        'This itinerary belongs to another account.',
      );
    }
    if (trip.isEphemeral) {
      throw const ValidationException(
        'Generated previews must be explicitly persisted before saving.',
      );
    }

    final now = FieldValue.serverTimestamp();
    final data = trip.toMap();
    data['userId'] = uid;
    data['updatedAt'] = now;

    // User subcollection
    final userDocRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .doc(trip.id);

    final snap = await userDocRef.get();
    _requireCurrentUser(uid);
    if (!snap.exists) {
      data['createdAt'] = now;
      // Increment total trips on user profile
      try {
        await _firestore.collection('users').doc(uid).update({
          'totalTrips': FieldValue.increment(1),
          'lastLogin': now,
        });
      } catch (_) {}
      _requireCurrentUser(uid);
    }

    await userDocRef.set(data, SetOptions(merge: true));
    _requireCurrentUser(uid);

    // Only mirror to the public root collection when the traveller has
    // explicitly shared this journey. Mirroring unconditionally made every
    // private itinerary world-readable at `itineraries/{id}`.
    _requireCurrentUser(uid);
    if (trip.isPublic) {
      if (await _canMutatePublicMirror(uid, trip.id)) {
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
        debugPrint(
          '[TripRepository] Skipping public mirror owned by another account.',
        );
      }
    } else {
      // Clear any previously public copy so un-sharing actually un-publishes.
      if (await _canMutatePublicMirror(uid, trip.id)) {
        try {
          await _firestore.collection('itineraries').doc(trip.id).delete();
        } catch (e) {
          debugPrint('[TripRepository] Could not clear public mirror: $e');
        }
      }
    }
    _requireCurrentUser(uid);

    // Cache locally
    await _cacheTrip(uid, trip.copyWith(userId: uid));
    _requireCurrentUser(uid);

    return trip.id;
  }

  Future<bool> _canMutatePublicMirror(String uid, String tripId) async {
    try {
      final root = await _firestore.collection('itineraries').doc(tripId).get();
      _requireCurrentUser(uid);
      if (!root.exists) return true;
      final data = root.data();
      return data?['isPublic'] == true && data?['userId'] == uid;
    } catch (error) {
      if (error is AuthRequiredException) rethrow;
      debugPrint(
        '[TripRepository] Could not verify public mirror owner: $error',
      );
      return false;
    }
  }

  /// Mark an itinerary as the active trip.
  ///
  /// Two journeys must never read as ACTIVE at once, so any other trip that
  /// currently claims `isActive` also has its stale `status` cleared — it then
  /// derives its lifecycle from its own dates rather than lying. Callers that
  /// deliberately intend to end another journey do that explicitly first, via
  /// [endTrip].
  Future<void> setActiveTrip(String uid, String activeTripId) async {
    _requireCurrentUser(uid);
    final userItinCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries');
    final allDocs = await userItinCol.get();
    _requireCurrentUser(uid);

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
    _requireCurrentUser(uid);
  }

  /// End a journey the traveller chose to leave. Terminal, so it can never
  /// reappear as the active trip whatever its dates say.
  Future<void> endTrip(String uid, String tripId) async {
    _requireCurrentUser(uid);
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
    _requireCurrentUser(uid);
  }

  /// Delete itinerary from user subcollection and root collection
  Future<void> deleteTrip(String uid, String tripId) async {
    _requireCurrentUser(uid);
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .doc(tripId)
        .delete();
    _requireCurrentUser(uid);
    try {
      if (await _canMutatePublicMirror(uid, tripId)) {
        await _firestore.collection('itineraries').doc(tripId).delete();
      }
    } catch (e) {
      // The owner document is authoritative. A stale public mirror must not
      // turn a confirmed private deletion into a client failure.
      debugPrint('[TripRepository] public itinerary delete failed: $e');
    }
    _requireCurrentUser(uid);
    try {
      await HiveService.deleteCachedItinerary(uid, tripId);
    } catch (e) {
      debugPrint('[TripRepository] local itinerary delete failed: $e');
    }
    _requireCurrentUser(uid);
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
