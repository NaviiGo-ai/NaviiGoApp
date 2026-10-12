import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String itineraryBoxName = 'itineraries_box';
  static const String userProfileBoxName = 'user_profile_box';
  static const String analyticsQueueBoxName = 'analytics_queue';

  static const String _itineraryKind = 'itinerary';
  static const int _itinerarySchemaVersion = 1;
  static const String _itineraryKeyPrefix = 'itinerary:';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Open cached data boxes
    await Hive.openBox(itineraryBoxName);
    await Hive.openBox(userProfileBoxName);
  }

  static Box get itineraryBox => Hive.box(itineraryBoxName);
  static Box get userProfileBox => Hive.box(userProfileBoxName);

  /// Returns the only key accepted for an owner-scoped itinerary record.
  ///
  /// Check-ins intentionally use a different, legacy key prefix and continue
  /// to access [itineraryBox] directly.
  static String itineraryCacheKey(String ownerUid, String tripId) {
    // Length-delimit the owner so unusual IDs containing ':' cannot collide
    // with a different owner/trip pair while keeping both values inspectable.
    return '$_itineraryKeyPrefix${ownerUid.length}:$ownerUid:$tripId';
  }

  /// Writes a complete owner-scoped itinerary envelope.
  ///
  /// The cache envelope is metadata around the model payload. In particular,
  /// [cachedAt] is not part of the model and must never be used to reconstruct
  /// itinerary fields.
  static Future<void> cacheItinerary(
    String ownerUid,
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    _validateOwnerAndTrip(ownerUid, tripId);
    if (payload['isEphemeral'] == true) {
      throw ArgumentError('Ephemeral itineraries cannot be cached.');
    }
    if (!_payloadOwnerMatches(payload, ownerUid)) {
      throw ArgumentError(
        'Itinerary payload owner does not match its cache owner.',
      );
    }
    final payloadId = payload['id'];
    if (payloadId != null && (payloadId is! String || payloadId != tripId)) {
      throw ArgumentError('Itinerary payload ID does not match its cache key.');
    }

    await itineraryBox.put(itineraryCacheKey(ownerUid, tripId), {
      'kind': _itineraryKind,
      'schemaVersion': _itinerarySchemaVersion,
      'ownerUid': ownerUid,
      'tripId': tripId,
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'payload': Map<String, dynamic>.from(payload),
    });
  }

  /// Reads one itinerary for exactly [ownerUid] and [tripId].
  ///
  /// A pre-envelope flat record can only be read when it contains an explicit
  /// matching top-level `userId` or `uid`. No ownership is inferred from a
  /// cache key, the current session, or nested form data.
  static Map<String, dynamic>? getCachedItinerary(
    String ownerUid,
    String tripId,
  ) {
    if (!_validOwnerAndTrip(ownerUid, tripId)) return null;

    final scopedKey = itineraryCacheKey(ownerUid, tripId);
    final scoped = _validEnvelope(
      itineraryBox.get(scopedKey),
      scopedKey,
      ownerUid,
      tripId,
    );
    if (scoped != null) return scoped['payload'] as Map<String, dynamic>;

    // Bare keys are legacy itinerary entries. They are deliberately checked
    // only after the scoped key and only with an explicit top-level owner.
    final legacyPayload = _asMap(itineraryBox.get(tripId));
    if (legacyPayload == null ||
        !_legacyOwnerMatches(legacyPayload, ownerUid) ||
        !_legacyTripMatches(legacyPayload, tripId) ||
        legacyPayload['isEphemeral'] == true) {
      return null;
    }
    return legacyPayload;
  }

  /// Returns valid payloads belonging only to [ownerUid].
  static List<Map<String, dynamic>> getCachedItineraries(String ownerUid) {
    if (ownerUid.isEmpty) return const [];

    final byTripId = <String, Map<String, dynamic>>{};
    for (final key in itineraryBox.keys) {
      if (key is! String) continue;
      if (!key.startsWith(_itineraryKeyPrefix)) continue;
      final raw = itineraryBox.get(key);
      final envelope = _validEnvelopeForOwner(raw, key, ownerUid);
      if (envelope == null) continue;
      final tripId = envelope['tripId'];
      if (tripId is String && tripId.isNotEmpty) {
        byTripId[tripId] = envelope['payload'] as Map<String, dynamic>;
      }
    }

    // Include valid legacy records that have not yet been rewritten. A
    // scoped record wins when both forms exist for the same trip.
    for (final key in itineraryBox.keys) {
      if (key is! String) continue;
      if (key.startsWith('trip_checkins_')) continue;
      final raw = itineraryBox.get(key);
      final payload = _asMap(raw);
      if (payload == null) continue;
      if (!_legacyOwnerMatches(payload, ownerUid) ||
          payload['isEphemeral'] == true ||
          key.isEmpty ||
          !_legacyTripMatches(payload, key) ||
          byTripId.containsKey(key)) {
        continue;
      }
      byTripId[key] = payload;
    }

    return byTripId.values.toList(growable: false);
  }

  /// Deletes one owner-scoped itinerary and an attributable legacy entry.
  /// Records owned by another UID, malformed envelopes, and raw check-ins are
  /// left untouched.
  static Future<void> deleteCachedItinerary(
    String ownerUid,
    String tripId,
  ) async {
    if (!_validOwnerAndTrip(ownerUid, tripId)) return;

    final scopedKey = itineraryCacheKey(ownerUid, tripId);
    if (_validEnvelope(
          itineraryBox.get(scopedKey),
          scopedKey,
          ownerUid,
          tripId,
        ) !=
        null) {
      await itineraryBox.delete(scopedKey);
    }

    final payload = _asMap(itineraryBox.get(tripId));
    if (payload != null &&
        _legacyOwnerMatches(payload, ownerUid) &&
        _legacyTripMatches(payload, tripId)) {
      await itineraryBox.delete(tripId);
    }
  }

  /// Replaces only [ownerUid]'s valid itinerary records.
  ///
  /// This is intentionally not [Box.clear]: the box also contains check-ins
  /// and potentially another account's cache.
  static Future<void> replaceCachedItineraries(
    String ownerUid,
    Iterable<Map<String, dynamic>> payloads,
  ) async {
    if (ownerUid.isEmpty) return;

    final payloadList = payloads.toList(growable: false);
    final desiredTripIds = <String>{};
    for (final payload in payloadList) {
      final tripId = payload['id'];
      if (tripId is! String || tripId.isEmpty) continue;
      desiredTripIds.add(tripId);
    }

    final previousEntries = <dynamic, dynamic>{};
    for (final key in itineraryBox.keys) {
      if (key is String && key.startsWith(_itineraryKeyPrefix)) {
        if (_validEnvelopeForOwner(itineraryBox.get(key), key, ownerUid) !=
            null) {
          previousEntries[key] = itineraryBox.get(key);
        }
      } else if (key is String && !key.startsWith('trip_checkins_')) {
        final payload = _asMap(itineraryBox.get(key));
        if (payload != null &&
            _legacyOwnerMatches(payload, ownerUid) &&
            _legacyTripMatches(payload, key)) {
          previousEntries[key] = itineraryBox.get(key);
        }
      }
    }

    // Write the replacement set before removing stale records. If a cache
    // write fails, the previous usable owner-scoped cache remains available.
    try {
      for (final payload in payloadList) {
        final tripId = payload['id'];
        if (tripId is! String || tripId.isEmpty) continue;
        await cacheItinerary(ownerUid, tripId, payload);
      }
    } catch (_) {
      // Restore the previous owner set on a partial write. Check-ins and other
      // accounts are deliberately outside this rollback scope.
      final currentOwnerKeys = <dynamic>[];
      for (final key in itineraryBox.keys) {
        if (key is String && key.startsWith(_itineraryKeyPrefix)) {
          if (_validEnvelopeForOwner(itineraryBox.get(key), key, ownerUid) !=
              null) {
            currentOwnerKeys.add(key);
          }
        } else if (key is String && !key.startsWith('trip_checkins_')) {
          final payload = _asMap(itineraryBox.get(key));
          if (payload != null &&
              _legacyOwnerMatches(payload, ownerUid) &&
              _legacyTripMatches(payload, key)) {
            currentOwnerKeys.add(key);
          }
        }
      }
      if (currentOwnerKeys.isNotEmpty) {
        await itineraryBox.deleteAll(currentOwnerKeys);
      }
      if (previousEntries.isNotEmpty) {
        await itineraryBox.putAll(previousEntries);
      }
      rethrow;
    }

    final ownedKeys = <dynamic>[];
    for (final key in itineraryBox.keys) {
      if (key is String && key.startsWith(_itineraryKeyPrefix)) {
        final raw = itineraryBox.get(key);
        final envelope = _validEnvelopeForOwner(raw, key, ownerUid);
        if (envelope != null && !desiredTripIds.contains(envelope['tripId'])) {
          ownedKeys.add(key);
        }
      } else if (key is String && !key.startsWith('trip_checkins_')) {
        final raw = itineraryBox.get(key);
        final payload = _asMap(raw);
        if (payload != null &&
            _legacyOwnerMatches(payload, ownerUid) &&
            _legacyTripMatches(payload, key)) {
          // A successful refresh promotes attributable legacy records to the
          // scoped envelope, including the same trip ID. Remove the bare key
          // so migration completes instead of retaining duplicates.
          ownedKeys.add(key);
        }
      }
    }
    if (ownedKeys.isNotEmpty) {
      await itineraryBox.deleteAll(ownedKeys);
    }
  }

  static Future<void> clearCache({String? analyticsOwnerUid}) async {
    try {
      // The itinerary box is shared with check-ins. Only remove records that
      // can be attributed to the signed-out owner; never clear the raw box.
      if (analyticsOwnerUid != null && analyticsOwnerUid.isNotEmpty) {
        await clearItineraryCacheForUser(analyticsOwnerUid);
      }
      await userProfileBox.clear();
    } finally {
      if (analyticsOwnerUid != null) {
        try {
          await clearAnalyticsQueueForUser(analyticsOwnerUid);
        } catch (_) {
          // Analytics ownership is independently enforced at flush time.
        }
      }
    }
  }

  /// Removes only valid itinerary envelopes attributable to [ownerUid].
  static Future<void> clearItineraryCacheForUser(String ownerUid) async {
    if (ownerUid.isEmpty) return;
    final keys = <dynamic>[];
    for (final key in itineraryBox.keys) {
      if (key is! String || key.startsWith('trip_checkins_')) continue;
      if (key.startsWith(_itineraryKeyPrefix) &&
          _validEnvelopeForOwner(itineraryBox.get(key), key, ownerUid) !=
              null) {
        keys.add(key);
        continue;
      }
      final payload = _asMap(itineraryBox.get(key));
      if (payload != null &&
          _legacyOwnerMatches(payload, ownerUid) &&
          _legacyTripMatches(payload, key)) {
        keys.add(key);
      }
    }
    if (keys.isNotEmpty) await itineraryBox.deleteAll(keys);
  }

  static bool _validOwnerAndTrip(String ownerUid, String tripId) {
    return ownerUid.isNotEmpty && tripId.isNotEmpty;
  }

  static void _validateOwnerAndTrip(String ownerUid, String tripId) {
    if (!_validOwnerAndTrip(ownerUid, tripId)) {
      throw ArgumentError(
        'Owner UID and trip ID are required for itinerary cache.',
      );
    }
  }

  static Map<String, dynamic>? _validEnvelope(
    dynamic raw,
    String expectedKey,
    String expectedOwnerUid,
    String expectedTripId,
  ) {
    final envelope = _asMap(raw);
    if (envelope == null ||
        envelope['kind'] != _itineraryKind ||
        envelope['schemaVersion'] != _itinerarySchemaVersion ||
        envelope['ownerUid'] != expectedOwnerUid ||
        envelope['tripId'] != expectedTripId ||
        expectedKey != itineraryCacheKey(expectedOwnerUid, expectedTripId) ||
        !_validCachedAt(envelope['cachedAt'])) {
      return null;
    }
    final payload = _asMap(envelope['payload']);
    if (payload == null ||
        payload['isEphemeral'] == true ||
        !_payloadOwnerMatches(payload, expectedOwnerUid)) {
      return null;
    }
    final payloadId = payload['id'];
    if (payloadId != null &&
        (payloadId is! String || payloadId != expectedTripId)) {
      return null;
    }
    return {'payload': payload, 'tripId': expectedTripId};
  }

  static Map<String, dynamic>? _validEnvelopeForOwner(
    dynamic raw,
    String key,
    String ownerUid,
  ) {
    final envelope = _asMap(raw);
    final tripId = envelope?['tripId'];
    if (tripId is! String || tripId.isEmpty) return null;
    return _validEnvelope(envelope, key, ownerUid, tripId);
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }

  static bool _validCachedAt(dynamic value) {
    if (value is DateTime) return true;
    if (value is! String) return false;
    return DateTime.tryParse(value) != null;
  }

  static bool _payloadOwnerMatches(Map<String, dynamic> payload, String uid) {
    final userId = payload['userId'];
    final legacyUid = payload['uid'];
    if (userId != null && userId != uid) return false;
    if (legacyUid != null && legacyUid != uid) return false;
    return true;
  }

  static bool _legacyOwnerMatches(Map<String, dynamic> payload, String uid) {
    final userId = payload['userId'];
    final legacyUid = payload['uid'];
    if (userId == null && legacyUid == null) return false;
    return _payloadOwnerMatches(payload, uid);
  }

  static bool _legacyTripMatches(Map<String, dynamic> payload, String tripId) {
    final payloadId = payload['id'];
    return payloadId == null || (payloadId is String && payloadId == tripId);
  }

  /// Removes only locally owned analytics envelopes for [uid]. The analytics
  /// repository also enforces ownership at flush time if cleanup fails.
  static Future<void> clearAnalyticsQueueForUser(String uid) async {
    final box = Hive.isBoxOpen(analyticsQueueBoxName)
        ? Hive.box<String>(analyticsQueueBoxName)
        : await Hive.openBox<String>(analyticsQueueBoxName);
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['ownerUid'] == uid) {
          await box.delete(key);
        }
      } catch (_) {
        // Legacy/malformed entries are never attributable and are handled by
        // AnalyticsRepository's safe discard path.
      }
    }
  }
}
