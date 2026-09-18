import '../../../core/network/api_provider.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AnalyticsRepository(apiClient);
});

class AnalyticsEvent {
  final String eventId;
  final String eventType;
  final String occurredAt;
  final String? tripId;
  final String? dayId;
  final String? activityId;
  final String? placeId;
  final String? destinationId;
  final Map<String, dynamic>? metadata;

  AnalyticsEvent({
    required this.eventId,
    required this.eventType,
    required this.occurredAt,
    this.tripId,
    this.dayId,
    this.activityId,
    this.placeId,
    this.destinationId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'schemaVersion': '1.0',
      'eventType': eventType,
      'occurredAt': occurredAt,
      if (tripId != null) 'tripId': tripId,
      if (dayId != null) 'dayId': dayId,
      if (activityId != null) 'activityId': activityId,
      if (placeId != null) 'placeId': placeId,
      if (destinationId != null) 'destinationId': destinationId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventId: json['eventId'],
      eventType: json['eventType'],
      occurredAt: json['occurredAt'],
      tripId: json['tripId'],
      dayId: json['dayId'],
      activityId: json['activityId'],
      placeId: json['placeId'],
      destinationId: json['destinationId'],
      metadata: json['metadata'],
    );
  }
}

class AnalyticsRepository {
  final ApiClient _apiClient;
  static const String _boxName = 'analytics_queue';
  final _uuid = const Uuid();
  bool _isFlushing = false;

  AnalyticsRepository(this._apiClient);

  Future<void> logEvent({
    required String eventType,
    String? tripId,
    String? dayId,
    String? activityId,
    String? placeId,
    String? destinationId,
    Map<String, dynamic>? metadata,
  }) async {
    final event = AnalyticsEvent(
      eventId:
          (eventType == 'ACTIVITY_CHECKED_IN' ||
              eventType == 'ACTIVITY_COMPLETED')
          ? '${eventType}_${tripId}_${dayId}_${activityId}'
          : (eventType == 'TRIP_COMPLETED'
                ? '${eventType}_${tripId}'
                : _uuid.v4()),
      eventType: eventType,
      occurredAt: DateTime.now().toUtc().toIso8601String(),
      tripId: tripId,
      dayId: dayId,
      activityId: activityId,
      placeId: placeId,
      destinationId: destinationId,
      metadata: metadata,
    );

    // Bounded queue logic: limit offline queue to 200 items max
    final box = await Hive.openBox<String>(_boxName);
    if (box.length >= 200) {
      await box.deleteAt(0); // FIFO
    }
    await box.add(jsonEncode(event.toJson()));

    // Attempt background flush
    _flushQueue();
  }

  Future<void> _flushQueue() async {
    if (_isFlushing) return;
    final box = await Hive.openBox<String>(_boxName);
    if (box.isEmpty) return;

    _isFlushing = true;
    try {
      final keys = box.keys.toList();
      final events = keys.map((k) => jsonDecode(box.get(k)!)).toList();

      await _apiClient.post('/analytics/track', body: {'events': events});

      // On success, clear the sent events
      await box.deleteAll(keys);
    } on NetworkException {
      // Offline, silently ignore and wait for next flush
    } catch (e) {
      // Log failure but don't delete to allow retry, unless corrupted
      print('Analytics flush error: $e');
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> forceFlush() => _flushQueue();
}
