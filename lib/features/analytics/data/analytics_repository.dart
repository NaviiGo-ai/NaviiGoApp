import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/api_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.read(apiClientProvider));
});

/// Event envelope accepted by Website `POST /api/analytics/track`.
///
/// The queue is deliberately client-side only. The Website derives the
/// authenticated user from the Firebase bearer token and owns all
/// personalization updates.
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

  const AnalyticsEvent({
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

  Map<String, dynamic> toJson() => {
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

/// Bounded offline analytics queue.
///
/// Events are retained when the request is offline or rejected. A successful
/// response from the Website is the only condition that removes queued data.
class AnalyticsRepository {
  static const String _boxName = 'analytics_queue';
  static const int _maxQueueLength = 200;

  final ApiClient _apiClient;
  bool _isFlushing = false;
  int _eventSequence = 0;

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
    final now = DateTime.now().toUtc();
    final event = AnalyticsEvent(
      eventId: '${eventType}_${now.microsecondsSinceEpoch}_${_eventSequence++}',
      eventType: eventType,
      occurredAt: now.toIso8601String(),
      tripId: tripId,
      dayId: dayId,
      activityId: activityId,
      placeId: placeId,
      destinationId: destinationId,
      metadata: metadata,
    );

    final box = await Hive.openBox<String>(_boxName);
    while (box.length >= _maxQueueLength) {
      await box.deleteAt(0);
    }
    await box.add(jsonEncode(event.toJson()));
    unawaited(_flushQueue());
  }

  Future<void> _flushQueue() async {
    if (_isFlushing) return;

    final box = await Hive.openBox<String>(_boxName);
    if (box.isEmpty) return;

    _isFlushing = true;
    try {
      final keys = box.keys.toList();
      final events = <Map<String, dynamic>>[];
      for (final key in keys) {
        final raw = box.get(key);
        if (raw == null) continue;
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          events.add(Map<String, dynamic>.from(decoded));
        }
      }

      if (events.isEmpty) {
        await box.deleteAll(keys);
        return;
      }

      // The /api prefix is part of the production Website contract.
      await _apiClient.post('/api/analytics/track', body: {'events': events});
      await box.deleteAll(keys);
    } on NetworkException {
      // Keep the queue for a later retry when connectivity returns.
    } catch (error) {
      debugPrint('[AnalyticsRepository] Flush deferred: $error');
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> forceFlush() => _flushQueue();
}
