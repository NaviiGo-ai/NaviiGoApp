import 'package:cloud_firestore/cloud_firestore.dart';

class PassportStatsModel {
  final int totalStamps;
  final int totalXP;
  final int level;
  final int streak;
  final List<String> statesVisited;
  final List<String> citiesVisited;
  final int totalActivitiesCompleted;
  final DateTime? updatedAt;

  const PassportStatsModel({
    this.totalStamps = 0,
    this.totalXP = 0,
    this.level = 1,
    this.streak = 0,
    this.statesVisited = const [],
    this.citiesVisited = const [],
    this.totalActivitiesCompleted = 0,
    this.updatedAt,
  });

  factory PassportStatsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PassportStatsModel(
      totalStamps: (data['totalStamps'] as num?)?.toInt() ?? 0,
      totalXP: (data['totalXP'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      statesVisited: _stringList(data['statesVisited']),
      citiesVisited: _stringList(data['citiesVisited']),
      totalActivitiesCompleted:
          (data['totalActivitiesCompleted'] as num?)?.toInt() ?? 0,
      updatedAt: _dateValue(data['updatedAt']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class PassportStampModel {
  final String id;
  final String name;
  final String location;
  final String state;
  final String icon;
  final String type;
  final int xpEarned;
  final DateTime? visitedDate;
  final List<String> activities;
  final String? verificationMethod;

  /// A server-backed verification marker. A stamp without this marker remains
  /// a traveller memory; it must not be presented as a verified visit.
  final bool isVerified;

  /// If verification was attempted but could not be completed, retain the
  /// reason so the UI can report an honest unavailable state.
  final String? verificationFailure;

  /// Stable award identity. In normal operation this is the same value as
  /// [id], but keeping it explicit lets callers persist a deterministic key
  /// without deriving identity from a title, venue, or list position.
  final String? awardKey;

  const PassportStampModel({
    required this.id,
    required this.name,
    required this.location,
    required this.state,
    this.icon = '🏛️',
    this.type = 'Heritage',
    this.xpEarned = 100,
    this.visitedDate,
    this.activities = const [],
    this.verificationMethod,
    this.isVerified = false,
    this.verificationFailure,
    this.awardKey,
  });

  factory PassportStampModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PassportStampModel(
      id: doc.id,
      name: (data['name'] ?? 'Expedition Stamp').toString(),
      location: (data['location'] ?? '').toString(),
      state: (data['state'] ?? '').toString(),
      icon: (data['icon'] ?? '🧭').toString(),
      type: (data['type'] ?? 'Heritage').toString(),
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 100,
      visitedDate:
          _dateValue(data['visitedDate']) ?? _dateValue(data['createdAt']),
      activities: _stringList(data['activities']),
      verificationMethod: data['verificationMethod'] as String?,
      isVerified: data['isVerified'] == true,
      verificationFailure: _optionalString(data['verificationFailure']),
      awardKey: _optionalString(data['awardKey']) ?? doc.id,
    );
  }

  /// The Firestore payload used by [PassportRepository]. Keeping serialization
  /// beside the model prevents the award writer and any future retry path from
  /// drifting on optional verification fields.
  Map<String, dynamic> toFirestore({bool serverTimestamp = false}) {
    return {
      'name': name,
      'location': location,
      'state': state,
      'icon': icon,
      'type': type,
      'xpEarned': xpEarned,
      'visitedDate': serverTimestamp
          ? FieldValue.serverTimestamp()
          : visitedDate,
      'activities': List<String>.from(activities),
      if (verificationMethod != null) 'verificationMethod': verificationMethod,
      'isVerified': isVerified,
      if (verificationFailure != null)
        'verificationFailure': verificationFailure,
      'awardKey': awardKey ?? id,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final result = value.trim();
    return result.isEmpty ? null : result;
  }
}
