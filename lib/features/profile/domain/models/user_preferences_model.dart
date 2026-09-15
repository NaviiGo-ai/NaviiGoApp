import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferencesModel {
  final String? travelStyle; // comfort, backpacker, luxury
  final String? preferredGroup; // solo, couple, family, friends
  final List<String> interests;
  final List<String> dietaryPreferences;
  final List<String> accessibilityNeeds;
  final String? homeCity;

  const UserPreferencesModel({
    this.travelStyle,
    this.preferredGroup,
    this.interests = const [],
    this.dietaryPreferences = const [],
    this.accessibilityNeeds = const [],
    this.homeCity,
  });

  UserPreferencesModel copyWith({
    String? travelStyle,
    String? preferredGroup,
    List<String>? interests,
    List<String>? dietaryPreferences,
    List<String>? accessibilityNeeds,
    String? homeCity,
  }) {
    return UserPreferencesModel(
      travelStyle: travelStyle ?? this.travelStyle,
      preferredGroup: preferredGroup ?? this.preferredGroup,
      interests: interests ?? this.interests,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      homeCity: homeCity ?? this.homeCity,
    );
  }

  factory UserPreferencesModel.fromMap(Map<String, dynamic> data) {
    return UserPreferencesModel(
      travelStyle: data['travelStyle'] as String?,
      preferredGroup: data['preferredGroup'] as String?,
      interests:
          (data['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dietaryPreferences:
          (data['dietaryPreferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      accessibilityNeeds:
          (data['accessibilityNeeds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      homeCity: data['homeCity'] as String?,
    );
  }

  factory UserPreferencesModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) return const UserPreferencesModel();
    return UserPreferencesModel.fromMap(doc.data() ?? {});
  }

  Map<String, dynamic> toMap({bool includeEmptyLists = false}) {
    return {
      if (travelStyle != null) 'travelStyle': travelStyle,
      if (preferredGroup != null) 'preferredGroup': preferredGroup,
      if (includeEmptyLists || interests.isNotEmpty) 'interests': interests,
      if (includeEmptyLists || dietaryPreferences.isNotEmpty)
        'dietaryPreferences': dietaryPreferences,
      if (includeEmptyLists || accessibilityNeeds.isNotEmpty)
        'accessibilityNeeds': accessibilityNeeds,
      if (homeCity != null) 'homeCity': homeCity,
    };
  }
}
