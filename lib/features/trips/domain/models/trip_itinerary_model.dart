import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/master_destinations.dart';

class TripActivityModel {
  final String title;
  final String? time;
  final String? description;
  final String? location;
  final String? category;
  final String? duration;
  final String? estimatedCost;
  final bool isCompleted;

  const TripActivityModel({
    required this.title,
    this.time,
    this.description,
    this.location,
    this.category,
    this.duration,
    this.estimatedCost,
    this.isCompleted = false,
  });

  factory TripActivityModel.fromMap(Map<String, dynamic> map) {
    return TripActivityModel(
      title: (map['title'] ?? map['name'] ?? 'Activity').toString(),
      time: map['time']?.toString(),
      description: map['description']?.toString(),
      location: (map['location'] ?? map['address'])?.toString(),
      category: map['category']?.toString(),
      duration: map['duration']?.toString(),
      estimatedCost: (map['estimatedCost'] ?? map['cost'])?.toString(),
      isCompleted: map['isCompleted'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (time != null) 'time': time,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (category != null) 'category': category,
      if (duration != null) 'duration': duration,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
      'isCompleted': isCompleted,
    };
  }
}

class TripDayPlanModel {
  final int dayNumber;
  final String? theme;
  final String? dateFormatted;
  final List<TripActivityModel> activities;

  const TripDayPlanModel({
    required this.dayNumber,
    this.theme,
    this.dateFormatted,
    this.activities = const [],
  });

  factory TripDayPlanModel.fromMap(Map<String, dynamic> map, int index) {
    final rawDay = map['day'] ?? map['dayNumber'] ?? (index + 1);
    final dayNum = rawDay is num
        ? rawDay.toInt()
        : (int.tryParse(rawDay.toString()) ?? (index + 1));
    final rawActs = map['activities'] ?? map['items'] ?? map['schedule'] ?? [];

    List<TripActivityModel> parsedActs = [];
    if (rawActs is List) {
      parsedActs = rawActs.map((act) {
        if (act is Map<String, dynamic>) {
          return TripActivityModel.fromMap(act);
        } else if (act is Map) {
          return TripActivityModel.fromMap(Map<String, dynamic>.from(act));
        }
        return TripActivityModel(title: act.toString());
      }).toList();
    }

    return TripDayPlanModel(
      dayNumber: dayNum,
      theme: (map['theme'] ?? map['title'])?.toString(),
      dateFormatted: map['date']?.toString(),
      activities: parsedActs,
    );
  }
}

class TripItineraryModel {
  final String id;
  final String uuid;
  final String destId;
  final String destName;
  final Map<String, dynamic> form;
  final Map<String, dynamic>? generatedData;
  final bool isActive;

  /// Whether the traveller has explicitly shared this journey. Private trips
  /// never leave `users/{uid}/itineraries`.
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TripDayPlanModel> dayPlans;

  const TripItineraryModel({
    required this.id,
    required this.uuid,
    required this.destId,
    required this.destName,
    this.form = const {},
    this.generatedData,
    this.isActive = false,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
    this.dayPlans = const [],
  });

  factory TripItineraryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return TripItineraryModel.fromMap(doc.id, data);
  }

  factory TripItineraryModel.fromMap(String docId, Map<String, dynamic> data) {
    final form =
        (data['form'] as Map<String, dynamic>?) ??
        (data['form'] is Map
            ? Map<String, dynamic>.from(data['form'] as Map)
            : {});
    final genData =
        (data['generatedData'] as Map<String, dynamic>?) ??
        (data['generatedData'] is Map
            ? Map<String, dynamic>.from(data['generatedData'] as Map)
            : null);

    final stableId =
        (data['uuid'] ?? data['id'] ?? form['uuid'] ?? form['_uuid'] ?? docId)
            .toString();
    final destinationId =
        (data['destId'] ?? form['destination'] ?? form['destId'] ?? 'india')
            .toString();
    final destinationName =
        (data['destName'] ??
                form['destName'] ??
                form['destinationName'] ??
                'India Expedition')
            .toString();

    // Parse Day Plans from all possible root, generatedData, and form fields
    List<TripDayPlanModel> plans = [];
    final rawPlans =
        data['dayPlans'] ??
        data['days'] ??
        data['dailyPlans'] ??
        data['itinerary'] ??
        data['schedule'] ??
        genData?['dayPlans'] ??
        genData?['days'] ??
        genData?['dailyPlans'] ??
        genData?['itinerary'] ??
        genData?['schedule'] ??
        genData?['plan'] ??
        form['dayPlans'] ??
        form['days'];

    if (rawPlans is List && rawPlans.isNotEmpty) {
      for (int i = 0; i < rawPlans.length; i++) {
        final item = rawPlans[i];
        if (item is Map<String, dynamic>) {
          plans.add(TripDayPlanModel.fromMap(item, i));
        } else if (item is Map) {
          plans.add(
            TripDayPlanModel.fromMap(Map<String, dynamic>.from(item), i),
          );
        }
      }
    }

    return TripItineraryModel(
      id: docId,
      uuid: stableId,
      destId: destinationId,
      destName: destinationName,
      form: form,
      generatedData: genData,
      isActive: data['isActive'] == true || form['isActive'] == true,
      isPublic: data['isPublic'] == true,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      dayPlans: plans,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  int get totalDays {
    if (dayPlans.isNotEmpty) return dayPlans.length;
    final formDays = form['days'];
    if (formDays is num) return formDays.toInt();
    if (formDays is String) return int.tryParse(formDays) ?? 3;
    return 3;
  }

  String get startDateFormatted {
    final raw = form['startDate']?.toString();
    if (raw != null && raw.isNotEmpty) {
      try {
        final parsed = DateTime.parse(raw);
        return '${_monthName(parsed.month)} ${parsed.day}, ${parsed.year}';
      } catch (_) {
        return raw;
      }
    }
    if (createdAt != null) {
      return '${_monthName(createdAt!.month)} ${createdAt!.day}, ${createdAt!.year}';
    }
    return 'Flexible Dates';
  }

  DateTime? get parsedStartDate {
    final raw = form['startDate']?.toString();
    if (raw != null && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return createdAt;
  }

  bool get isCurrentlyActive {
    if (isActive) return true;
    final start = parsedStartDate;
    if (start != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tripStart = DateTime(start.year, start.month, start.day);
      final tripEnd = tripStart.add(Duration(days: totalDays));
      return (today.isAfter(tripStart) || today.isAtSameMomentAs(tripStart)) &&
          (today.isBefore(tripEnd) || today.isAtSameMomentAs(tripEnd));
    }
    return false;
  }

  bool get isUpcoming {
    if (isCurrentlyActive) return false;
    final start = parsedStartDate;
    if (start != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tripStart = DateTime(start.year, start.month, start.day);
      return tripStart.isAfter(today);
    }
    return false;
  }

  bool get isPast {
    if (isCurrentlyActive) return false;
    final start = parsedStartDate;
    if (start != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tripStart = DateTime(start.year, start.month, start.day);
      final tripEnd = tripStart.add(Duration(days: totalDays));
      return tripEnd.isBefore(today);
    }
    return false;
  }

  String get heroImage {
    final customImg =
        generatedData?['image'] ?? form['image'] ?? form['heroImage'];
    if (customImg is String && customImg.isNotEmpty) return customImg;

    // Resolve matching image from master destinations registry
    final lower = destName.toLowerCase();
    for (final dest in kMasterDestinations) {
      if (dest.id == destId ||
          dest.name.toLowerCase() == lower ||
          lower.contains(dest.name.toLowerCase())) {
        return dest.image;
      }
    }
    return kMasterDestinations.first.image;
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
