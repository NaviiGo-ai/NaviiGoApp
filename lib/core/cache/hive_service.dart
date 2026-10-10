import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String itineraryBoxName = 'itineraries_box';
  static const String userProfileBoxName = 'user_profile_box';
  static const String analyticsQueueBoxName = 'analytics_queue';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Open cached data boxes
    await Hive.openBox(itineraryBoxName);
    await Hive.openBox(userProfileBoxName);
  }

  static Box get itineraryBox => Hive.box(itineraryBoxName);
  static Box get userProfileBox => Hive.box(userProfileBoxName);

  // Helper methods to cache and retrieve itinerary JSON structures
  static Future<void> cacheItinerary(
    String key,
    Map<String, dynamic> data,
  ) async {
    await itineraryBox.put(key, data);
  }

  static Map<String, dynamic>? getCachedItinerary(String key) {
    final data = itineraryBox.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> clearCache({String? analyticsOwnerUid}) async {
    try {
      await itineraryBox.clear();
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
