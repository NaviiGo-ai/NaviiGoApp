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

    // If day plans are still empty, synthesize authentic curated chapters for the destination
    if (plans.isEmpty) {
      int totalDaysCount = 3;
      final formDays = form['days'] ?? data['days'] ?? data['totalDays'];
      if (formDays is num) {
        totalDaysCount = formDays.toInt();
      } else if (formDays is String) {
        totalDaysCount = int.tryParse(formDays) ?? 3;
      }
      plans = _generateCuratedDayPlans(destinationName, totalDaysCount);
    }

    return TripItineraryModel(
      id: docId,
      uuid: stableId,
      destId: destinationId,
      destName: destinationName,
      form: form,
      generatedData: genData,
      isActive: data['isActive'] == true || form['isActive'] == true,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      dayPlans: plans,
    );
  }

  static List<TripDayPlanModel> _generateCuratedDayPlans(
    String dest,
    int days,
  ) {
    final List<TripDayPlanModel> generated = [];
    final dName = dest.replaceAll(' Expedition', '').trim();

    for (int day = 1; day <= days; day++) {
      if (day == 1) {
        generated.add(
          TripDayPlanModel(
            dayNumber: 1,
            theme: 'Arrival & Historic Old Quarter',
            dateFormatted: 'Day 01',
            activities: [
              TripActivityModel(
                title: '$dName Orientation & Heritage Walk',
                time: '09:00 AM',
                category: 'Heritage',
                description:
                    'Check-in, morning stroll along the iconic ancient quarter, and local street orientation.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Central Landmark Exploration',
                time: '02:30 PM',
                category: 'Sightseeing',
                description:
                    'Explore the central palace courtyards, architecture, and sacred ghats/monuments.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Twilight Tea & Regional Dinner',
                time: '06:30 PM',
                category: 'Dining',
                description:
                    'Sunset riverside views followed by traditional thali and spiced chai.',
                location: dName,
              ),
            ],
          ),
        );
      } else if (day == 2) {
        generated.add(
          TripDayPlanModel(
            dayNumber: 2,
            theme: 'Sacred Temples & Local Artisans',
            dateFormatted: 'Day 02',
            activities: [
              TripActivityModel(
                title: 'Sunrise Chants & River Ghats',
                time: '06:30 AM',
                category: 'Spiritual',
                description:
                    'Witness the dawn aarti and sacred river chants along the ancient stone steps.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Handicraft & Textile Bazaar',
                time: '11:00 AM',
                category: 'Culture',
                description:
                    'Interact with multigenerational master weavers, block printers, and brass artisans.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Sunset Panorama Lookout',
                time: '05:30 PM',
                category: 'Nature',
                description:
                    'Climb to the scenic viewpoint overlooking the valley and evening skyline.',
                location: dName,
              ),
            ],
          ),
        );
      } else if (day == 3) {
        generated.add(
          TripDayPlanModel(
            dayNumber: 3,
            theme: 'Hidden Sanctuaries & River Solitude',
            dateFormatted: 'Day 03',
            activities: [
              TripActivityModel(
                title: 'Morning Nature & Forest Trail',
                time: '08:00 AM',
                category: 'Outdoors',
                description:
                    'Gentle morning trek across secluded pine paths and tranquil waterfalls.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Artisan Cafe & Journaling',
                time: '01:00 PM',
                category: 'Leisure',
                description:
                    'Relax at a scenic riverside cafe with regional coffees and traveler tales.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Evening Sacred Chants & Farewell Aarti',
                time: '06:00 PM',
                category: 'Spiritual',
                description:
                    'Final twilight gathering with floating oil lamps and musical hymns.',
                location: dName,
              ),
            ],
          ),
        );
      } else {
        generated.add(
          TripDayPlanModel(
            dayNumber: day,
            theme: 'Day $day · Offbeat Expedition',
            dateFormatted: 'Day 0$day',
            activities: [
              TripActivityModel(
                title: '$dName Countryside Excursion',
                time: '09:30 AM',
                category: 'Adventure',
                description:
                    'Explore neighboring rural hamlets, ancient stepwells, and terraced fields.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Authentic Village Lunch',
                time: '01:30 PM',
                category: 'Dining',
                description:
                    'Wood-fired organic lunch prepared with local herbs and farm produce.',
                location: dName,
              ),
              TripActivityModel(
                title: 'Stargazing & Campfire Gathering',
                time: '07:30 PM',
                category: 'Leisure',
                description:
                    'Clear Himalayan night sky observations with fellow travelers.',
                location: dName,
              ),
            ],
          ),
        );
      }
    }
    return generated;
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

  static TripItineraryModel sampleVaranasiTrip() {
    return TripItineraryModel(
      id: 'sample_varanasi_flagship',
      uuid: 'sample_varanasi_flagship',
      destId: 'varanasi',
      destName: 'Varanasi',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      form: {
        'destination': 'Varanasi',
        'destName': 'Varanasi',
        'days': 3,
        'startDate': DateTime.now()
            .add(const Duration(days: 2))
            .toIso8601String(),
        'group': 'Duo Exploration',
        'purpose': 'Heritage & Spiritual',
        'pace': 'Balanced Expedition',
        'budget': 18500,
        'heroImage': 'assets/brand/varanasi-dawn-hero.jpg',
      },
      dayPlans: _generateCuratedDayPlans('Varanasi', 3),
    );
  }
}
