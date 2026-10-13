// Typed Phase 6 operation values shared by generation and replan flows.
//
// These models intentionally do not accept arbitrary maps as authority.  A
// response can be rendered only after its required operation, owner,
// itinerary, and revision identities have been checked by the repository.

String _requiredString(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or empty $key.');
  }
  return value.trim();
}

String? _optionalString(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string when supplied.');
  }
  return value.trim();
}

String _requiredStringFromAliases(
  Map<dynamic, dynamic> map,
  List<String> keys,
  String displayName,
) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  throw FormatException('Missing or empty $displayName.');
}

Map<String, dynamic> _map(dynamic value, String name) {
  if (value is! Map) throw FormatException('$name must be an object.');
  try {
    return Map<String, dynamic>.from(value);
  } catch (_) {
    throw FormatException('$name must be an object with string keys.');
  }
}

List<String> _stringList(dynamic value, String name) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('$name must be a list.');
  final values = <String>[];
  for (final item in value) {
    if (item is! String || item.trim().isEmpty) {
      throw FormatException('$name must contain non-empty strings.');
    }
    values.add(item.trim());
  }
  if (values.toSet().length != values.length) {
    throw FormatException('$name must not contain duplicate identities.');
  }
  return values;
}

/// A revision is a server-owned snapshot identity, not a client-generated
/// timestamp or a list position.
class TripRevision {
  final String revisionId;
  final String? previousRevisionId;
  final String? reason;
  final DateTime? timestamp;

  const TripRevision({
    required this.revisionId,
    this.previousRevisionId,
    this.reason,
    this.timestamp,
  }) : assert(revisionId != '');

  factory TripRevision.fromMap(Map<dynamic, dynamic> map) {
    final timestampRaw = map['timestamp'] ?? map['createdAt'];
    DateTime? timestamp;
    if (timestampRaw is DateTime) {
      timestamp = timestampRaw;
    } else if (timestampRaw is String) {
      timestamp = DateTime.tryParse(timestampRaw);
    } else if (timestampRaw is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw);
    }
    return TripRevision(
      revisionId: _requiredString(map, 'revisionId'),
      previousRevisionId: _optionalString(map, 'previousRevisionId'),
      reason: _optionalString(map, 'reason'),
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'revisionId': revisionId,
    if (previousRevisionId != null) 'previousRevisionId': previousRevisionId,
    if (reason != null) 'reason': reason,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };
}

/// The receipt that proves an operation was committed to the owner resource.
class TripOperationReceipt {
  final String ownerUid;
  final String itineraryId;
  final String operationId;
  final String revisionId;
  final String status;
  final String? proposalId;
  final String? previousRevisionId;
  final bool idempotent;

  const TripOperationReceipt({
    required this.ownerUid,
    required this.itineraryId,
    required this.operationId,
    required this.revisionId,
    required this.status,
    this.proposalId,
    this.previousRevisionId,
    this.idempotent = false,
  }) : assert(ownerUid != ''),
       assert(itineraryId != ''),
       assert(operationId != ''),
       assert(revisionId != ''),
       assert(status != '');

  factory TripOperationReceipt.fromMap(Map<dynamic, dynamic> map) {
    final status = _requiredString(map, 'status').toLowerCase();
    const allowedStatuses = {'committed', 'accepted'};
    if (!allowedStatuses.contains(status)) {
      throw FormatException('Unsupported operation receipt status: $status.');
    }
    final idempotentRaw = map['idempotent'];
    if (idempotentRaw != null && idempotentRaw is! bool) {
      throw FormatException('idempotent must be a boolean.');
    }
    return TripOperationReceipt(
      ownerUid: _requiredString(map, 'ownerUid'),
      itineraryId: _requiredString(map, 'itineraryId'),
      operationId: _requiredString(map, 'operationId'),
      revisionId: _requiredString(map, 'revisionId'),
      status: status,
      proposalId: _optionalString(map, 'proposalId'),
      previousRevisionId: _optionalString(map, 'previousRevisionId'),
      idempotent: idempotentRaw == true,
    );
  }

  static TripOperationReceipt? tryFromMap(dynamic value) {
    if (value is! Map) return null;
    try {
      return TripOperationReceipt.fromMap(value);
    } on FormatException {
      return null;
    }
  }

  bool matches({
    required String ownerUid,
    required String itineraryId,
    required String operationId,
    String? revisionId,
  }) {
    return this.ownerUid == ownerUid &&
        this.itineraryId == itineraryId &&
        this.operationId == operationId &&
        (revisionId == null || this.revisionId == revisionId);
  }

  Map<String, dynamic> toMap() => {
    'ownerUid': ownerUid,
    'itineraryId': itineraryId,
    'operationId': operationId,
    'revisionId': revisionId,
    'status': status,
    if (proposalId != null) 'proposalId': proposalId,
    if (previousRevisionId != null) 'previousRevisionId': previousRevisionId,
    'idempotent': idempotent,
  };
}

/// Names used by callers that distinguish generation receipts from replan
/// receipts.  They are the same wire contract.
typedef GenerationReceipt = TripOperationReceipt;
typedef ReplanReceipt = TripOperationReceipt;

class ReplanLocation {
  final double lat;
  final double lng;

  const ReplanLocation({required this.lat, required this.lng});

  factory ReplanLocation.fromMap(Map<dynamic, dynamic> map) {
    final lat = _number(map['lat'], 'location.lat');
    final lng = _number(map['lng'], 'location.lng');
    if (!lat.isFinite || lat < -90 || lat > 90) {
      throw FormatException('location.lat is outside -90..90.');
    }
    if (!lng.isFinite || lng < -180 || lng > 180) {
      throw FormatException('location.lng is outside -180..180.');
    }
    return ReplanLocation(lat: lat, lng: lng);
  }

  static double _number(dynamic value, String name) {
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value)
        : null;
    if (number == null) throw FormatException('$name must be numeric.');
    return number;
  }

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng};
}

class ReplanRequest {
  final String itineraryId;
  final String operationId;
  final String baseRevisionId;
  final int currentDayNumber;
  final String currentTime;
  final String reason;
  final List<String> completedActivityIds;
  final List<String> skippedActivityIds;
  final ReplanLocation? location;
  final String destinationTimezone;

  ReplanRequest({
    required this.itineraryId,
    required this.operationId,
    required this.baseRevisionId,
    required this.currentDayNumber,
    required this.currentTime,
    this.reason = 'I_AM_TIRED',
    this.completedActivityIds = const [],
    this.skippedActivityIds = const [],
    this.location,
    this.destinationTimezone = 'UTC',
  }) {
    if (itineraryId.trim().isEmpty ||
        operationId.trim().isEmpty ||
        baseRevisionId.trim().isEmpty ||
        currentTime.trim().isEmpty ||
        destinationTimezone.trim().isEmpty) {
      throw FormatException('Replan identity and time fields are required.');
    }
    if (currentDayNumber < 1) {
      throw FormatException('currentDayNumber must be positive.');
    }
    if (reason != 'I_AM_TIRED') {
      throw FormatException('Only I_AM_TIRED replan requests are supported.');
    }
    final overlap = completedActivityIds.toSet().intersection(
      skippedActivityIds.toSet(),
    );
    if (overlap.isNotEmpty) {
      throw FormatException(
        'An activity cannot be both completed and skipped: ${overlap.first}.',
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'itineraryId': itineraryId.trim(),
    'operationId': operationId.trim(),
    'baseRevisionId': baseRevisionId.trim(),
    'currentDayNumber': currentDayNumber,
    'currentTime': currentTime.trim(),
    'reason': reason,
    'completedActivityIds': List<String>.from(completedActivityIds),
    'skippedActivityIds': List<String>.from(skippedActivityIds),
    if (location != null) 'location': location!.toMap(),
    'destinationTimezone': destinationTimezone.trim(),
  };

  factory ReplanRequest.fromMap(Map<dynamic, dynamic> map) {
    final locationRaw = map['location'];
    final dayRaw = map['currentDayNumber'];
    if (dayRaw is! num) {
      throw FormatException('currentDayNumber must be numeric.');
    }
    return ReplanRequest(
      itineraryId: _requiredString(map, 'itineraryId'),
      operationId: _requiredString(map, 'operationId'),
      baseRevisionId: _requiredString(map, 'baseRevisionId'),
      currentDayNumber: dayRaw.toInt(),
      currentTime: _requiredString(map, 'currentTime'),
      reason: _requiredString(map, 'reason'),
      completedActivityIds: _stringList(
        map['completedActivityIds'],
        'completedActivityIds',
      ),
      skippedActivityIds: _stringList(
        map['skippedActivityIds'],
        'skippedActivityIds',
      ),
      location: locationRaw == null
          ? null
          : ReplanLocation.fromMap(_map(locationRaw, 'location')),
      destinationTimezone: _optionalString(map, 'destinationTimezone') ?? 'UTC',
    );
  }
}

class ReplanActionModel {
  final String actionType;
  final String? activityId;
  final String rationale;
  final Map<String, dynamic>? replacementActivity;
  final String? targetDate;

  const ReplanActionModel({
    required this.actionType,
    required this.rationale,
    this.activityId,
    this.replacementActivity,
    this.targetDate,
  });

  factory ReplanActionModel.fromMap(Map<dynamic, dynamic> map) {
    final replacement = map['replacementActivity'];
    final actionType = _requiredString(map, 'actionType');
    const supportedActions = {
      'KEEP',
      'REMOVE',
      'MOVE_TO_LATER_DAY',
      'SAVE_FOR_LATER',
      'REPLACE',
      'END_DAY_EARLY',
    };
    if (!supportedActions.contains(actionType)) {
      throw FormatException('Unsupported replan action: $actionType.');
    }
    if (actionType != 'END_DAY_EARLY' &&
        _optionalString(map, 'activityId') == null) {
      throw FormatException('$actionType requires activityId.');
    }
    final replacementMap = replacement == null
        ? null
        : _map(replacement, 'replacementActivity');
    if (actionType == 'REPLACE' &&
        _optionalString(replacementMap ?? const {}, 'activityId') == null &&
        _optionalString(replacementMap ?? const {}, 'id') == null) {
      throw FormatException(
        'REPLACE requires a stable replacement activity ID.',
      );
    }
    return ReplanActionModel(
      actionType: actionType,
      activityId: _optionalString(map, 'activityId'),
      rationale: _requiredString(map, 'rationale'),
      replacementActivity: replacementMap,
      targetDate: _optionalString(map, 'targetDate'),
    );
  }

  Map<String, dynamic> toMap() => {
    'actionType': actionType,
    if (activityId != null) 'activityId': activityId,
    'rationale': rationale,
    if (replacementActivity != null)
      'replacementActivity': Map<String, dynamic>.from(replacementActivity!),
    if (targetDate != null) 'targetDate': targetDate,
  };
}

typedef ReplanAction = ReplanActionModel;

class ReplanProposal {
  final String proposalId;
  final String itineraryId;
  final String operationId;
  final String baseRevisionId;
  final String reason;
  final String? affectedDate;
  final String summary;
  final List<ReplanActionModel> actions;
  final List<Map<String, dynamic>> updatedTimeline;
  final List<Map<String, dynamic>> updatedTransfers;
  final List<String> preservedBookings;
  final List<String> warnings;
  final Map<String, dynamic> impact;
  final Map<String, dynamic> generationMetadata;

  const ReplanProposal({
    required this.proposalId,
    required this.itineraryId,
    required this.operationId,
    required this.baseRevisionId,
    required this.reason,
    this.affectedDate,
    required this.summary,
    this.actions = const [],
    this.updatedTimeline = const [],
    this.updatedTransfers = const [],
    this.preservedBookings = const [],
    this.warnings = const [],
    this.impact = const {},
    this.generationMetadata = const {},
  });

  factory ReplanProposal.fromMap(Map<dynamic, dynamic> map) {
    final rawActions = map['actions'] ?? const [];
    if (rawActions is! List) throw FormatException('actions must be a list.');
    final actions = rawActions
        .map((value) {
          return ReplanActionModel.fromMap(_map(value, 'action'));
        })
        .toList(growable: false);

    List<Map<String, dynamic>> mapList(dynamic value, String name) {
      if (value == null) return const [];
      if (value is! List) throw FormatException('$name must be a list.');
      return value.map((entry) => _map(entry, name)).toList(growable: false);
    }

    return ReplanProposal(
      proposalId: _requiredString(map, 'proposalId'),
      itineraryId: _requiredStringFromAliases(map, const [
        'itineraryId',
        'tripId',
      ], 'itineraryId'),
      operationId: _requiredString(map, 'operationId'),
      baseRevisionId: _requiredString(map, 'baseRevisionId'),
      reason: _requiredString(map, 'reason'),
      affectedDate: _optionalString(map, 'affectedDate'),
      summary: _requiredString(map, 'summary'),
      actions: actions,
      updatedTimeline: mapList(map['updatedTimeline'], 'updatedTimeline'),
      updatedTransfers: mapList(map['updatedTransfers'], 'updatedTransfers'),
      preservedBookings: _stringList(
        map['preservedBookings'],
        'preservedBookings',
      ),
      warnings: _stringList(map['warnings'], 'warnings'),
      impact: map['impact'] == null ? const {} : _map(map['impact'], 'impact'),
      generationMetadata: map['generationMetadata'] == null
          ? const {}
          : _map(map['generationMetadata'], 'generationMetadata'),
    );
  }

  Map<String, dynamic> toMap() => {
    'proposalId': proposalId,
    'itineraryId': itineraryId,
    'operationId': operationId,
    'baseRevisionId': baseRevisionId,
    'reason': reason,
    if (affectedDate != null) 'affectedDate': affectedDate,
    'summary': summary,
    'actions': actions.map((action) => action.toMap()).toList(),
    'updatedTimeline': updatedTimeline
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(),
    'updatedTransfers': updatedTransfers
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(),
    'preservedBookings': List<String>.from(preservedBookings),
    'warnings': List<String>.from(warnings),
    'impact': Map<String, dynamic>.from(impact),
    'generationMetadata': Map<String, dynamic>.from(generationMetadata),
  };
}

class ReplanAcceptanceResult {
  final ReplanProposal? proposal;
  final TripOperationReceipt receipt;
  final bool idempotent;

  /// The authoritative itinerary is filled by the repository after the owner
  /// document is read and verified.  Keeping it required prevents callers from
  /// accidentally treating an acknowledgement as a durable update.
  final dynamic itinerary;

  const ReplanAcceptanceResult({
    required this.receipt,
    required this.itinerary,
    this.proposal,
    this.idempotent = false,
  });
}

typedef ReplanResult = ReplanAcceptanceResult;
