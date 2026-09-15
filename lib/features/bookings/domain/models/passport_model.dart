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
      statesVisited: List<String>.from(data['statesVisited'] ?? []),
      citiesVisited: List<String>.from(data['citiesVisited'] ?? []),
      totalActivitiesCompleted:
          (data['totalActivitiesCompleted'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
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
          (data['visitedDate'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate(),
      activities: List<String>.from(data['activities'] ?? []),
      verificationMethod: data['verificationMethod'] as String?,
    );
  }
}
