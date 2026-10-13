import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/firebase_client.dart';
import '../../../core/constants/master_destinations.dart';
import '../domain/models/trip_itinerary_model.dart';
import '../domain/models/trip_operation_models.dart';

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

  DocumentReference<Map<String, dynamic>> _ownerItineraryRef(
    String uid,
    String itineraryId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .doc(itineraryId);
  }

  /// Reads only the canonical owner document.  This helper is deliberately
  /// separate from [getTripById], whose legacy cache fallback is appropriate
  /// for display but never for a Phase 6 mutation or receipt.
  Future<TripItineraryModel> _readVerifiedOwnerTrip(
    String uid,
    String itineraryId, {
    String? expectedRevisionId,
    bool requireStableActivityIdentity = false,
  }) async {
    _requireCurrentUser(uid);
    if (itineraryId.trim().isEmpty) {
      throw const ValidationException('An itinerary ID is required.');
    }
    final doc = await _ownerItineraryRef(uid, itineraryId).get();
    _requireCurrentUser(uid);
    if (!doc.exists) {
      throw const NotFoundException('The owner itinerary was not found.');
    }

    final parsed = _bindOwnedTrip(uid, TripItineraryModel.fromFirestore(doc));
    if (parsed == null) {
      throw const ForbiddenException(
        'This itinerary is not owned by the signed-in account.',
      );
    }
    if (parsed.id != itineraryId) {
      throw const ItineraryGenerationResponseException(
        'The owner itinerary identity could not be verified.',
      );
    }
    if (expectedRevisionId != null && parsed.revisionId != expectedRevisionId) {
      throw ConflictException(
        'The itinerary changed before this operation could be applied.',
        conflictCode: 'STALE_PROPOSAL',
        details: {
          'itineraryId': itineraryId,
          'baseRevisionId': expectedRevisionId,
          'currentRevisionId': parsed.revisionId,
        },
      );
    }
    if (requireStableActivityIdentity) {
      parsed.requireStableActivityIdentity();
      if (parsed.revisionId == null || parsed.revisionId!.isEmpty) {
        throw const TripActivityIdentityException(
          'A server revision is required before an itinerary can be replanned.',
        );
      }
    }
    return parsed;
  }

  Future<TripItineraryModel?> _tryReconcileOperation(
    String uid,
    String itineraryId, {
    TripOperationReceipt? expectedReceipt,
    bool requireStableActivityIdentity = true,
  }) async {
    try {
      final doc = await _ownerItineraryRef(uid, itineraryId).get();
      _requireCurrentUser(uid);
      if (!doc.exists) return null;
      final parsed = _bindOwnedTrip(uid, TripItineraryModel.fromFirestore(doc));
      if (parsed == null) return null;
      TripOperationReceipt? receipt;
      for (final candidate in parsed.operationReceipts) {
        if (expectedReceipt != null) {
          if (candidate.status == expectedReceipt.status &&
              candidate.matches(
                ownerUid: expectedReceipt.ownerUid,
                itineraryId: expectedReceipt.itineraryId,
                operationId: expectedReceipt.operationId,
                revisionId: expectedReceipt.revisionId,
              )) {
            receipt = candidate;
            break;
          }
        } else if (candidate.status == 'committed' &&
            candidate.matches(
              ownerUid: uid,
              itineraryId: itineraryId,
              operationId: itineraryId,
            )) {
          receipt = candidate;
          break;
        }
      }
      // A historical receipt confirms an operation without rolling back the
      // owner's newer accepted itinerary. Without a stored receipt, only an
      // exact response/owner revision match is usable for compatibility.
      if (parsed.id != itineraryId || parsed.revisionId == null) return null;
      if (receipt == null &&
          (expectedReceipt == null ||
              parsed.revisionId != expectedReceipt.revisionId)) {
        return null;
      }
      if (requireStableActivityIdentity) {
        parsed.requireStableActivityIdentity();
      }
      return parsed.copyWith(operationReceipt: receipt ?? expectedReceipt);
    } on AuthRequiredException {
      rethrow;
    } on TripActivityIdentityException {
      return null;
    } catch (_) {
      // Reconciliation is best effort after an ambiguous network result.  The
      // original request error remains the caller-visible failure when no
      // verified owner document can be found.
      return null;
    }
  }

  Future<TripItineraryModel> _cacheVerifiedTrip(
    String uid,
    TripItineraryModel trip,
  ) async {
    if (trip.isEphemeral || trip.userId != uid) {
      throw const ItineraryGenerationResponseException(
        'Only a verified durable owner itinerary can be cached.',
      );
    }
    await _cacheTrip(uid, trip);
    _requireCurrentUser(uid);
    return trip;
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

    /// Optional for backwards compatibility with the Phase 4 direct-preview
    /// caller.  Supplying it opts into the Phase 6 durable receipt contract.
    String? operationId,
    required String expectedAuthUid,
  }) async {
    if (expectedAuthUid.trim().isEmpty ||
        _currentUserUid() != expectedAuthUid) {
      throw const AuthRequiredException(
        'Your account is no longer available for this request.',
      );
    }
    final normalizedOperationId = operationId?.trim();
    if (operationId != null && normalizedOperationId!.isEmpty) {
      throw const ValidationException(
        'A non-empty operation ID is required for durable generation.',
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
      if (normalizedOperationId != null) 'operationId': normalizedOperationId,
    };

    dynamic response;
    try {
      response = await _apiClient.post(
        '/api/itinerary/generate',
        body: payload,
        requiresAuth: true,
        timeout: AppConfig.aiGenerationTimeout,
        expectedAuthUid: expectedAuthUid,
      );
    } catch (error) {
      if (normalizedOperationId != null && error is! AuthRequiredException) {
        final reconciled = await _tryReconcileOperation(
          expectedAuthUid,
          normalizedOperationId,
        );
        if (reconciled != null) {
          return await _cacheVerifiedTrip(expectedAuthUid, reconciled);
        }
      }
      rethrow;
    }

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
    final receipt = TripOperationReceipt.tryFromMap(response['receipt']);
    _validateGeneratedItinerary(
      itinData,
      // A preview without a receipt remains compatible with the legacy direct
      // generation response.  Stable IDs become mandatory once the server
      // claims that the operation was durably committed.
      requireStableActivityIdentity:
          normalizedOperationId != null && receipt != null,
    );

    if (normalizedOperationId != null && receipt != null) {
      final responseItineraryId =
          _nonEmptyString(itinData['id']) ?? _nonEmptyString(itinData['uuid']);
      if (receipt.status != 'committed' ||
          receipt.itineraryId != normalizedOperationId ||
          !receipt.matches(
            ownerUid: expectedAuthUid,
            itineraryId: responseItineraryId ?? receipt.itineraryId,
            operationId: normalizedOperationId,
          )) {
        throw const ItineraryGenerationResponseException(
          'The generation receipt did not match the initiating operation.',
        );
      }
      final reconciled = await _tryReconcileOperation(
        expectedAuthUid,
        receipt.itineraryId,
        expectedReceipt: receipt,
      );
      if (reconciled == null) {
        throw const ItineraryGenerationResponseException(
          'Generation was acknowledged but its owner receipt could not be verified.',
        );
      }
      return await _cacheVerifiedTrip(
        expectedAuthUid,
        reconciled.copyWith(operationReceipt: receipt),
      );
    }

    // A response without a receipt is not durable.  An ambiguous response can
    // still be reconciled by the operation ID, but only an owner document with
    // its own matching receipt is allowed to clear the ephemeral boundary.
    if (normalizedOperationId != null) {
      final reconciled = await _tryReconcileOperation(
        expectedAuthUid,
        normalizedOperationId,
      );
      if (reconciled != null) {
        return await _cacheVerifiedTrip(expectedAuthUid, reconciled);
      }
    }

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
      if (receipt != null) 'receipt': receipt.toMap(),
    });
  }

  /// Requests a server-owned replan proposal.  The owner document is read
  /// first so an old local revision or a legacy/name-only activity set can
  /// never reach the mutation endpoint.
  Future<ReplanProposal> requestReplan({
    required String uid,
    required String itineraryId,
    required String operationId,
    required String baseRevisionId,
    required int currentDayNumber,
    required String currentTime,
    String reason = 'I_AM_TIRED',
    List<String> completedActivityIds = const [],
    List<String> skippedActivityIds = const [],
    Object? location,
    String destinationTimezone = 'UTC',
  }) async {
    final request = ReplanRequest(
      itineraryId: itineraryId,
      operationId: operationId,
      baseRevisionId: baseRevisionId,
      currentDayNumber: currentDayNumber,
      currentTime: currentTime,
      reason: reason,
      completedActivityIds: completedActivityIds,
      skippedActivityIds: skippedActivityIds,
      location: _parseReplanLocation(location),
      destinationTimezone: destinationTimezone,
    );
    return requestReplanForRequest(uid: uid, request: request);
  }

  /// Object-based variant keeps the domain request reusable by callers that
  /// already validated the values at a boundary.
  Future<ReplanProposal> requestReplanForRequest({
    required String uid,
    required ReplanRequest request,
  }) async {
    _requireCurrentUser(uid);
    if (request.itineraryId.isEmpty || request.operationId.isEmpty) {
      throw const ValidationException(
        'Itinerary and replan operation IDs are required.',
      );
    }
    final trip = await _readReplanBase(
      uid: uid,
      itineraryId: request.itineraryId,
      baseRevisionId: request.baseRevisionId,
    );
    _validateProgressIds(trip, request);

    final response = await _apiClient.post(
      '/api/itinerary/replan',
      body: request.toMap(),
      requiresAuth: true,
      expectedAuthUid: uid,
    );
    _requireCurrentUser(uid);
    if (response is! Map || response['success'] != true) {
      throw const ItineraryGenerationResponseException(
        'The replan service returned an invalid proposal response.',
      );
    }
    final rawProposal = response['proposal'];
    if (rawProposal is! Map || rawProposal['ownerUid'] != uid) {
      throw const ItineraryGenerationResponseException(
        'The replan service returned no proposal.',
      );
    }
    final proposal = ReplanProposal.fromMap(rawProposal);
    if (proposal.itineraryId != request.itineraryId ||
        proposal.baseRevisionId != request.baseRevisionId ||
        proposal.operationId != request.operationId) {
      throw const ItineraryGenerationResponseException(
        'The replan proposal did not match the requested owner revision.',
      );
    }
    if (proposal.reason != request.reason) {
      throw const ItineraryGenerationResponseException(
        'The replan proposal reason did not match the request.',
      );
    }
    return proposal;
  }

  /// Accepts a server-owned proposal and returns the owner document after its
  /// revision-bound receipt has been verified.  Client proposal data is never
  /// sent and therefore cannot become mutation authority.
  Future<ReplanAcceptanceResult> acceptReplan({
    required String uid,
    required String itineraryId,
    required String proposalId,
    required String operationId,
    required String baseRevisionId,
  }) async {
    _requireCurrentUser(uid);
    if (proposalId.trim().isEmpty || operationId.trim().isEmpty) {
      throw const ValidationException(
        'Proposal and acceptance operation IDs are required.',
      );
    }

    // Reconcile first. A retried operation can already be accepted while the
    // owner document has advanced to a newer revision; checking the submitted
    // base revision before this lookup would incorrectly turn an idempotent
    // replay into a stale-proposal failure.
    final alreadyAccepted = await _tryReconcileAcceptedOperation(
      uid: uid,
      itineraryId: itineraryId,
      proposalId: proposalId,
      operationId: operationId,
      baseRevisionId: baseRevisionId,
    );
    if (alreadyAccepted != null) return alreadyAccepted;

    await _readReplanBase(
      uid: uid,
      itineraryId: itineraryId,
      baseRevisionId: baseRevisionId,
    );

    dynamic response;
    try {
      response = await _apiClient.post(
        '/api/itinerary/replan/accept',
        body: {
          'itineraryId': itineraryId,
          'proposalId': proposalId,
          'baseRevisionId': baseRevisionId,
          'operationId': operationId,
        },
        requiresAuth: true,
        expectedAuthUid: uid,
      );
    } catch (error) {
      if (error is! AuthRequiredException) {
        final reconciled = await _tryReconcileAcceptedOperation(
          uid: uid,
          itineraryId: itineraryId,
          proposalId: proposalId,
          operationId: operationId,
          baseRevisionId: baseRevisionId,
        );
        if (reconciled != null) return reconciled;
      }
      rethrow;
    }
    _requireCurrentUser(uid);
    if (response is! Map || response['success'] != true) {
      throw const ItineraryGenerationResponseException(
        'The replan acceptance response was invalid.',
      );
    }
    final receipt = TripOperationReceipt.tryFromMap(response['receipt']);
    if (receipt == null ||
        receipt.status != 'accepted' ||
        !receipt.matches(
          ownerUid: uid,
          itineraryId: itineraryId,
          operationId: operationId,
        ) ||
        receipt.proposalId != proposalId ||
        receipt.previousRevisionId != baseRevisionId) {
      throw const ItineraryGenerationResponseException(
        'The replan acceptance receipt could not be verified.',
      );
    }

    // A first acceptance must return the revision it committed. On an
    // idempotent replay, however, the owner document may have advanced after
    // that historical receipt; the current owner snapshot is still the only
    // itinerary safe to render.
    final authoritative = await _readVerifiedOwnerTrip(
      uid,
      itineraryId,
      requireStableActivityIdentity: true,
    );
    var verifiedReplay = receipt.idempotent;
    if (authoritative.revisionId != receipt.revisionId) {
      final historicalReceipt = _receiptForAcceptedOperation(
        authoritative,
        uid: uid,
        itineraryId: itineraryId,
        proposalId: proposalId,
        operationId: operationId,
        baseRevisionId: baseRevisionId,
      );
      if (historicalReceipt == null ||
          historicalReceipt.revisionId != receipt.revisionId ||
          historicalReceipt.previousRevisionId != receipt.previousRevisionId) {
        throw const ItineraryGenerationResponseException(
          'The accepted replan receipt did not match the current owner revision.',
        );
      }
      verifiedReplay = true;
    }
    final verified = await _cacheVerifiedTrip(
      uid,
      authoritative.copyWith(operationReceipt: receipt),
    );
    return ReplanAcceptanceResult(
      receipt: receipt,
      itinerary: verified,
      idempotent: verifiedReplay,
    );
  }

  Future<ReplanAcceptanceResult?> _tryReconcileAcceptedOperation({
    required String uid,
    required String itineraryId,
    required String proposalId,
    required String operationId,
    required String baseRevisionId,
  }) async {
    try {
      final doc = await _ownerItineraryRef(uid, itineraryId).get();
      _requireCurrentUser(uid);
      if (!doc.exists) return null;
      final trip = _bindOwnedTrip(uid, TripItineraryModel.fromFirestore(doc));
      final receipt = trip == null
          ? null
          : _receiptForAcceptedOperation(
              trip,
              uid: uid,
              itineraryId: itineraryId,
              proposalId: proposalId,
              operationId: operationId,
              baseRevisionId: baseRevisionId,
            );
      if (trip == null ||
          receipt == null ||
          receipt.status != 'accepted' ||
          trip.id != itineraryId ||
          trip.userId != uid ||
          trip.revisionId == null ||
          trip.revisionId!.isEmpty) {
        return null;
      }
      trip.requireStableActivityIdentity();
      final verified = await _cacheVerifiedTrip(uid, trip);
      return ReplanAcceptanceResult(
        receipt: receipt,
        itinerary: verified,
        // This path is reached by a retry/reconciliation, regardless of
        // whether the original receipt explicitly carried an idempotent bit.
        idempotent: true,
      );
    } on AuthRequiredException {
      rethrow;
    } on TripActivityIdentityException {
      return null;
    } on ItineraryGenerationResponseException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  static TripOperationReceipt? _receiptForAcceptedOperation(
    TripItineraryModel trip, {
    required String uid,
    required String itineraryId,
    required String proposalId,
    required String operationId,
    required String baseRevisionId,
  }) {
    for (final receipt in [
      if (trip.operationReceipt != null) trip.operationReceipt!,
      ...trip.operationReceipts,
    ]) {
      if (receipt.status == 'accepted' &&
          receipt.matches(
            ownerUid: uid,
            itineraryId: itineraryId,
            operationId: operationId,
          ) &&
          receipt.proposalId == proposalId) {
        if (receipt.previousRevisionId != baseRevisionId) {
          throw const ItineraryGenerationResponseException(
            'The saved acceptance receipt did not match the previous revision.',
          );
        }
        return receipt;
      }
    }
    return null;
  }

  static ReplanLocation? _parseReplanLocation(Object? location) {
    if (location == null) return null;
    if (location is ReplanLocation) return location;
    if (location is Map) return ReplanLocation.fromMap(location);
    throw const ValidationException(
      'Replan location must be a coordinate map.',
    );
  }

  Future<TripItineraryModel> _readReplanBase({
    required String uid,
    required String itineraryId,
    required String baseRevisionId,
  }) async {
    try {
      return await _readVerifiedOwnerTrip(
        uid,
        itineraryId,
        expectedRevisionId: baseRevisionId,
        requireStableActivityIdentity: true,
      );
    } on TripActivityIdentityException catch (error) {
      throw ConflictException(
        error.message,
        conflictCode: 'ACTIVITY_IDENTITY_AMBIGUOUS',
        details: {'itineraryId': itineraryId, 'baseRevisionId': baseRevisionId},
      );
    }
  }

  static void _validateProgressIds(
    TripItineraryModel trip,
    ReplanRequest request,
  ) {
    final ids = trip.stableActivityIds.toSet();
    for (final id in [
      ...request.completedActivityIds,
      ...request.skippedActivityIds,
    ]) {
      if (!ids.contains(id)) {
        throw ConflictException(
          'Manual progress references an activity absent from the authoritative itinerary.',
          conflictCode: 'ACTIVITY_IDENTITY_AMBIGUOUS',
          details: {'activityId': id},
        );
      }
    }
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

  static void _validateGeneratedItinerary(
    Map<String, dynamic> itinerary, {
    bool requireStableActivityIdentity = false,
  }) {
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
        if (requireStableActivityIdentity) {
          final activityId = activity['activityId'] ?? activity['id'];
          if (activityId is! String || activityId.trim().isEmpty) {
            throw const ItineraryGenerationResponseException(
              'The durable itinerary returned an activity without a stable activityId.',
            );
          }
        }
        hasActivity = true;
      }
    }

    if (requireStableActivityIdentity) {
      final ids = <String>{};
      for (final rawPlan in rawPlans) {
        final plan = Map<String, dynamic>.from(rawPlan as Map);
        final rawActivities =
            _firstPresent(plan, const ['activities', 'items', 'schedule'])
                as List;
        for (final rawActivity in rawActivities) {
          final activity = Map<String, dynamic>.from(rawActivity as Map);
          final id = (activity['activityId'] ?? activity['id'])
              .toString()
              .trim();
          if (!ids.add(id)) {
            throw const ItineraryGenerationResponseException(
              'The durable itinerary returned duplicate activity identities.',
            );
          }
        }
      }
    }

    if (!hasActivity) {
      throw const ItineraryGenerationResponseException(
        'The itinerary service returned no usable activities.',
      );
    }
  }
}
