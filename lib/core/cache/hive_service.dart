import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String itineraryBoxName = 'itineraries_box';
  static const String userProfileBoxName = 'user_profile_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open cached data boxes
    await Hive.openBox(itineraryBoxName);
    await Hive.openBox(userProfileBoxName);
  }

  static Box get itineraryBox => Hive.box(itineraryBoxName);
  static Box get userProfileBox => Hive.box(userProfileBoxName);

  // Helper methods to cache and retrieve itinerary JSON structures
  static Future<void> cacheItinerary(String key, Map<String, dynamic> data) async {
    await itineraryBox.put(key, data);
  }

  static Map<String, dynamic>? getCachedItinerary(String key) {
    final data = itineraryBox.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> clearCache() async {
    await itineraryBox.clear();
    await userProfileBox.clear();
  }
}
