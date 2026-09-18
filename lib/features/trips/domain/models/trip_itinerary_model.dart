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
  final String? placeId;
  final bool isCompleted;

  // New rich fields from canonical backend
  final String? whyItFits;
  final String? placeId;
  final double? lat;
  final double? lng;
  final String? bookingRequirement;
  final List<String> warnings;
  final String? mealContext;
  final bool isGenericDiningFallback;
  final String? transferOrigin;
  final String? transferDestination;
  final String? transferMode;
  final String? source;

  const TripActivityModel({
    required this.title,
    this.time,
    this.description,
    this.location,
    this.category,
    this.duration,
    this.estimatedCost,
    this.placeId,
    this.isCompleted = false,
    this.whyItFits,
    this.placeId,
    this.lat,
    this.lng,
    this.bookingRequirement,
    this.warnings = const [],
    this.mealContext,
    this.isGenericDiningFallback = false,
    this.transferOrigin,
    this.transferDestination,
    this.transferMode,
    this.source,
  });

  factory TripActivityModel.fromMap(Map<String, dynamic> map) {
    final latRaw = map['lat'] ?? map['latitude'] ?? (map['coordinates'] is Map ? (map['coordinates'] as Map)['lat'] : null);
    final lngRaw = map['lng'] ?? map['longitude'] ?? (map['coordinates'] is Map ? (map['coordinates'] as Map)['lng'] : null);

    return TripActivityModel(
      title: (map['title'] ?? map['name'] ?? 'Activity').toString(),
      time: map['time']?.toString(),
      description: map['description']?.toString(),
      location: (map['location'] ?? map['address'])?.toString(),
      category: map['category']?.toString(),
      duration: map['duration']?.toString(),
      estimatedCost: (map['estimatedCost'] ?? map['cost'])?.toString(),
      placeId: map['placeId']?.toString(),
      isCompleted: map['isCompleted'] == true,
      whyItFits: map['whyItFits']?.toString(),
      placeId: (map['placeId'] ?? map['groundedPlaceId'])?.toString(),
      lat: latRaw is num ? latRaw.toDouble() : (latRaw is String ? double.tryParse(latRaw) : null),
      lng: lngRaw is num ? lngRaw.toDouble() : (lngRaw is String ? double.tryParse(lngRaw) : null),
      bookingRequirement: map['bookingRequirement']?.toString(),
      warnings: (map['warnings'] as List?)?.map((e) => e.toString()).toList() ?? [],
      mealContext: map['mealContext']?.toString(),
      isGenericDiningFallback: map['isGenericDiningFallback'] == true,
      transferOrigin: map['transferOrigin']?.toString(),
      transferDestination: map['transferDestination']?.toString(),
      transferMode: map['transferMode']?.toString(),
      source: map['source']?.toString(),
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
      if (placeId != null) 'placeId': placeId,
      'isCompleted': isCompleted,
      if (whyItFits != null) 'whyItFits': whyItFits,
      if (placeId != null) 'placeId': placeId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (bookingRequirement != null) 'bookingRequirement': bookingRequirement,
      if (warnings.isNotEmpty) 'warnings': warnings,
      if (mealContext != null) 'mealContext': mealContext,
      'isGenericDiningFallback': isGenericDiningFallback,
      if (transferOrigin != null) 'transferOrigin': transferOrigin,
      if (transferDestination != null) 'transferDestination': transferDestination,
      if (transferMode != null) 'transferMode': transferMode,
      if (source != null) 'source': source,
    };
  }

  TripActivityModel copyWith({
    String? title,
    String? time,
    String? description,
    String? location,
    String? category,
    String? duration,
    String? estimatedCost,
    bool? isCompleted,
    String? whyItFits,
    String? placeId,
    double? lat,
    double? lng,
    String? bookingRequirement,
    List<String>? warnings,
    String? mealContext,
    bool? isGenericDiningFallback,
    String? transferOrigin,
    String? transferDestination,
    String? transferMode,
    String? source,
  }) {
    return TripActivityModel(
      title: title ?? this.title,
      time: time ?? this.time,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      isCompleted: isCompleted ?? this.isCompleted,
      whyItFits: whyItFits ?? this.whyItFits,
      placeId: placeId ?? this.placeId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      bookingRequirement: bookingRequirement ?? this.bookingRequirement,
      warnings: warnings ?? this.warnings,
      mealContext: mealContext ?? this.mealContext,
      isGenericDiningFallback: isGenericDiningFallback ?? this.isGenericDiningFallback,
      transferOrigin: transferOrigin ?? this.transferOrigin,
      transferDestination: transferDestination ?? this.transferDestination,
      transferMode: transferMode ?? this.transferMode,
      source: source ?? this.source,
    );
  }
}

class TripDayPlanModel {
  final int dayNumber;
  final String? theme;
  final String? areaFocus;
  final String? weatherContext;
  final String? dateFormatted;
  final List<TripActivityModel> activities;

  const TripDayPlanModel({
    required this.dayNumber,
    this.theme,
    this.areaFocus,
    this.weatherContext,
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
      areaFocus: (map['areaFocus'] ?? map['area'])?.toString(),
      weatherContext: map['weatherContext']?.toString(),
      dateFormatted: map['date']?.toString(),
      activities: parsedActs,
    );
  }

  TripDayPlanModel copyWith({
    int? dayNumber,
    String? theme,
    String? areaFocus,
    String? weatherContext,
    String? dateFormatted,
    List<TripActivityModel>? activities,
  }) {
    return TripDayPlanModel(
      dayNumber: dayNumber ?? this.dayNumber,
      theme: theme ?? this.theme,
      areaFocus: areaFocus ?? this.areaFocus,
      weatherContext: weatherContext ?? this.weatherContext,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      activities: activities ?? this.activities,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// TRIP LIFECYCLE
/// The single vocabulary every screen, controller, and server write must use.
///
///   draft ──► planned ──► upcoming ──► eligibleToStart ──► active ──► completed
///                 └──────────────► cancelled (from any non-terminal state)
///
/// `eligibleToStart` is time-derived: the traveller is inside the start window
/// but has not begun. `active` is only ever reached by an explicit start (or a
/// server-written `status`), never inferred from the clock alone — a trip whose
/// dates have arrived is `eligibleToStart`, not silently "active".
/// ─────────────────────────────────────────────────────────────────────────────
enum TripStatus {
  draft,
  planned,
  upcoming,
  eligibleToStart,
  active,
  completed,
  cancelled;

  /// Wire value persisted to Firestore (`status` field).
  String get wireName {
    switch (this) {
      case TripStatus.draft:
        return 'draft';
      case TripStatus.planned:
        return 'planned';
      case TripStatus.upcoming:
        return 'upcoming';
      case TripStatus.eligibleToStart:
        return 'eligible_to_start';
      case TripStatus.active:
        return 'active';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Human-facing label for chips, headers, and status rows.
  String get label {
    switch (this) {
      case TripStatus.draft:
        return 'Draft';
      case TripStatus.planned:
        return 'Planned';
      case TripStatus.upcoming:
        return 'Upcoming';
      case TripStatus.eligibleToStart:
        return 'Ready to Start';
      case TripStatus.active:
        return 'In Motion';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Terminal states never transition further.
  bool get isTerminal =>
      this == TripStatus.completed || this == TripStatus.cancelled;

  /// Whether this trip may still be begun by the traveller.
  bool get canStart => !isTerminal && this != TripStatus.active;

  /// Tolerant parse of whatever the backend already wrote. Historical documents
  /// carry `active` / `past` / `in_progress`; unknown values degrade to
  /// [TripStatus.planned] rather than throwing.
  static TripStatus fromString(String? raw) {
    final key = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (key) {
      case 'draft':
      case 'drafttrip':
        return TripStatus.draft;
      case 'planned':
      case 'plan':
      case 'planning':
        return TripStatus.planned;
      case 'upcoming':
        return TripStatus.upcoming;
      case 'eligibletostart':
      case 'eligible':
      case 'ready':
      case 'readytostart':
        return TripStatus.eligibleToStart;
      case 'active':
      case 'inprogress':
      case 'started':
        return TripStatus.active;
      case 'completed':
      case 'complete':
      case 'past':
      case 'done':
        return TripStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'cancel':
        return TripStatus.cancelled;
    }
    if (key.startsWith('upcoming')) return TripStatus.upcoming;
    if (key.startsWith('eligible') || key.startsWith('ready')) {
      return TripStatus.eligibleToStart;
    }
    if (key.startsWith('plan')) return TripStatus.planned;
    if (key.startsWith('cancel')) return TripStatus.cancelled;
    if (key.startsWith('complete') || key.startsWith('past')) {
      return TripStatus.completed;
    }
    if (key.startsWith('active') || key.startsWith('inprogress')) {
      return TripStatus.active;
    }
    if (key.startsWith('draft')) return TripStatus.draft;
    return TripStatus.planned;
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
  final bool isReviewed;

  /// Whether the traveller has explicitly shared this journey. Private trips
  /// never leave `users/{uid}/itineraries`.
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TripDayPlanModel> dayPlans;

  // New metadata fields
  final Map<String, dynamic>? generationMetadata;
  final List<String> warnings;
  final Map<String, dynamic>? costSummary;

  /// Owner. Null only for legacy documents written before ownership was
  /// stamped — start-trip validation treats an absent owner as unverifiable.
  final String? userId;

  /// Start-region coordinates. Explicit when the itinerary carries them,
  /// otherwise derived from the curated destination registry. Null means the
  /// traveller's position cannot be checked against anything.
  final double? startLat;
  final double? startLng;

  /// Explicit lifecycle status written by the server. Null means the status is
  /// derived from dates and [isActive] — see [tripStatus].
  final TripStatus? status;

  const TripItineraryModel({
    required this.id,
    required this.uuid,
    required this.destId,
    required this.destName,
    this.form = const {},
    this.generatedData,
    this.isActive = false,
    this.isReviewed = false,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
    this.dayPlans = const [],
    this.generationMetadata,
    this.warnings = const [],
    this.costSummary,
    this.userId,
    this.startLat,
    this.startLng,
    this.status,
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

    final meta = data['generationMetadata'] ?? genData?['generationMetadata'] ?? genData?['metadata'];
    final warningsRaw = data['warnings'] ?? genData?['warnings'];
    final costSum = data['costSummary'] ?? genData?['costSummary'];

    return TripItineraryModel(
      id: docId,
      uuid: stableId,
      destId: destinationId,
      destName: destinationName,
      form: form,
      generatedData: genData,
      isActive: data['isActive'] == true || form['isActive'] == true,
      isReviewed: data['isReviewed'] == true,
      isPublic: data['isPublic'] == true,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      dayPlans: plans,
      generationMetadata: meta is Map ? Map<String, dynamic>.from(meta) : null,
      warnings: warningsRaw is List ? (warningsRaw as List).map((e) => e.toString()).toList() : const [],
      costSummary: costSum is Map ? Map<String, dynamic>.from(costSum) : null,
      userId: _parseString(data['userId'] ?? data['uid'] ?? form['userId'] ?? form['uid']),
      startLat: _parseDouble(
            data['startLat'] ??
                data['lat'] ??
                form['startLat'] ??
                form['lat'] ??
                _coordField(data['startCoords'], 'lat') ??
                _coordField(form['startCoords'], 'lat'),
          ) ??
          _masterDestination(destinationId, destinationName)?.lat,
      startLng: _parseDouble(
            data['startLng'] ??
                data['lng'] ??
                form['startLng'] ??
                form['lng'] ??
                _coordField(data['startCoords'], 'lng') ??
                _coordField(form['startCoords'], 'lng'),
          ) ??
          _masterDestination(destinationId, destinationName)?.lng,
      // Absent `status` stays null so the lifecycle can be derived from dates
      // rather than guessed from a missing field.
      status: (data['status'] ?? form['status']) == null
          ? null
          : TripStatus.fromString((data['status'] ?? form['status']).toString()),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static dynamic _coordField(dynamic coords, String key) {
    if (coords is Map) return coords[key];
    return null;
  }

  /// Resolve a curated destination by id first, then by display name.
  static MasterDestination? _masterDestination(String destId, String destName) {
    return findDestinationById(destId) ?? findDestinationById(destName);
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

  /// Inside the start window: from the day before the scheduled departure
  /// through to the end of the journey, and not yet begun, finished, or
  /// abandoned. Late starts stay eligible — real journeys slip.
  ///
  /// Deliberately ignores [isCurrentlyActive]: arriving on the calendar is not
  /// the same as having begun, and only [isActive] (or a server-written status)
  /// may claim a journey is under way.
  bool get isEligibleToStart {
    if (status == TripStatus.eligibleToStart) return true;
    if (status != null && (status!.isTerminal || status == TripStatus.active)) {
      return false;
    }
    if (isActive) return false;
    final start = parsedStartDate;
    if (start == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final windowOpens = startDay.subtract(const Duration(days: 1));
    final journeyEnds = startDay.add(Duration(days: totalDays));
    if (today.isAfter(journeyEnds)) return false;
    return !today.isBefore(windowOpens);
  }

  /// The single lifecycle answer every screen should read. Server-written
  /// [status] always wins; otherwise it is derived, and derived `active` only
  /// ever comes from the explicit [isActive] flag — never from the clock.
  TripStatus get tripStatus {
    if (status != null) return status!;
    if (isActive) return TripStatus.active;
    if (isPast) return TripStatus.completed;
    if (isEligibleToStart) return TripStatus.eligibleToStart;
    if (isUpcoming) return TripStatus.upcoming;
    return TripStatus.planned;
  }

  /// The curated city the traveller must reach in order to begin. Falls back to
  /// the itinerary's own name when the registry does not recognise it.
  String get startRegionName =>
      _masterDestination(destId, destName)?.name ?? destName;

  TripItineraryModel copyWith({
    String? id,
    String? uuid,
    String? destId,
    String? destName,
    Map<String, dynamic>? form,
    Map<String, dynamic>? generatedData,
    bool? isActive,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TripDayPlanModel>? dayPlans,
    String? userId,
    double? startLat,
    double? startLng,
    TripStatus? status,
  }) {
    return TripItineraryModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      destId: destId ?? this.destId,
      destName: destName ?? this.destName,
      form: form ?? this.form,
      generatedData: generatedData ?? this.generatedData,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dayPlans: dayPlans ?? this.dayPlans,
      userId: userId ?? this.userId,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      status: status ?? this.status,
    );
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
