import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/cache/hive_service.dart';
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

/// Local-only ownership wrapper. `ownerUid` is never included in the API
/// event body; Firebase bearer authentication remains the backend identity.
class _QueuedAnalyticsEvent {
  final String ownerUid;
  final Map<String, dynamic> event;

  const _QueuedAnalyticsEvent({required this.ownerUid, required this.event});

  String encode() => jsonEncode({'ownerUid': ownerUid, 'event': event});

  static _QueuedAnalyticsEvent? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['ownerUid'] is! String) return null;
      final ownerUid = decoded['ownerUid'] as String;
      final event = decoded['event'];
      if (ownerUid.isEmpty || event is! Map) return null;
      return _QueuedAnalyticsEvent(
        ownerUid: ownerUid,
        event: Map<String, dynamic>.from(event),
      );
    } catch (_) {
      return null;
    }
  }
}

class _AnalyticsQueueMutex {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    final previous = _tail;
    final current = Completer<void>();
    _tail = current.future;

    unawaited(() async {
      try {
        await previous;
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        current.complete();
      }
    }());
    return result.future;
  }
}

/// Bounded, account-owned offline analytics queue.
///
/// Events are retained when the request is offline or rejected. A successful
/// response from the Website is the only condition that removes queued data.
/// Legacy unowned entries are discarded and are never submitted.
class AnalyticsRepository {
  static const int maxQueueLength = 200;

  final ApiClient _apiClient;
  final String _queueBoxName;
  final String? Function() _currentUid;
  final bool _flushOnLog;
  final _AnalyticsQueueMutex _queueMutex = _AnalyticsQueueMutex();
  bool _isFlushing = false;
  bool _flushRequested = false;
  int _eventSequence = 0;

  AnalyticsRepository(
    this._apiClient, {
    String? Function()? currentUid,
    String queueBoxName = HiveService.analyticsQueueBoxName,
    bool flushOnLog = true,
  }) : _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _queueBoxName = queueBoxName,
       _flushOnLog = flushOnLog;

  Future<Box<String>> _openQueue() => Hive.openBox<String>(_queueBoxName);

  Future<void> logEvent({
    required String eventType,
    String? tripId,
    String? dayId,
    String? activityId,
    String? placeId,
    String? destinationId,
    Map<String, dynamic>? metadata,
  }) async {
    final ownerUid = _currentUid();
    if (ownerUid == null || ownerUid.isEmpty) return;

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

    await _queueMutex.run<void>(() async {
      final box = await _openQueue();
      // Do not attribute an event to an account if auth changed while the
      // local write was waiting for Hive.
      if (_currentUid() != ownerUid) return;

      final ownedKeys = await _ownedKeys(box, ownerUid);
      while (ownedKeys.length >= maxQueueLength) {
        await box.delete(ownedKeys.removeAt(0));
      }
      await box.add(
        _QueuedAnalyticsEvent(
          ownerUid: ownerUid,
          event: event.toJson(),
        ).encode(),
      );
    });
    if (_flushOnLog) unawaited(_flushQueue());
  }

  Future<List<dynamic>> _ownedKeys(Box<String> box, String ownerUid) async {
    final ownedKeys = <dynamic>[];
    for (final key in box.keys.toList()) {
      final queued = _decode(box.get(key));
      if (queued == null) {
        // Raw events from the old global queue have no trustworthy owner.
        // Discard them rather than guessing which Firebase account created
        // them.
        await box.delete(key);
      } else if (queued.ownerUid == ownerUid) {
        ownedKeys.add(key);
      }
    }
    return ownedKeys;
  }

  _QueuedAnalyticsEvent? _decode(String? raw) {
    if (raw == null) return null;
    return _QueuedAnalyticsEvent.decode(raw);
  }

  Future<void> _flushQueue() async {
    if (_isFlushing) {
      _flushRequested = true;
      return;
    }
    _isFlushing = true;
    try {
      await _queueMutex.run<void>(() async {
        final box = await _openQueue();
        final ownerUid = _currentUid();
        // Safe cleanup is allowed while signed out, but no event can be sent
        // without an authenticated owner.
        if (ownerUid == null || ownerUid.isEmpty) {
          for (final key in box.keys.toList()) {
            if (_decode(box.get(key)) == null) await box.delete(key);
          }
          return;
        }

        final keys = <dynamic>[];
        final events = <Map<String, dynamic>>[];
        for (final key in box.keys.toList()) {
          final queued = _decode(box.get(key));
          if (queued == null) {
            await box.delete(key);
            continue;
          }
          if (queued.ownerUid != ownerUid) continue;
          keys.add(key);
          events.add(queued.event);
        }

        if (events.isEmpty || _currentUid() != ownerUid) return;

        // Keep queue mutation behind the mutex until the request completes.
        // A concurrent log must not trim an in-flight event before a failed
        // request has a chance to retry it.
        await _apiClient.post(
          '/api/analytics/track',
          body: {'events': events},
          expectedAuthUid: ownerUid,
        );
        await box.deleteAll(keys);
      });
    } on NetworkException {
      // Keep this user's queue for a later retry when connectivity returns.
    } on AuthRequiredException {
      // Auth changed or disappeared; leave the owned events queued.
    } catch (error) {
      debugPrint('[AnalyticsRepository] Flush deferred: $error');
    } finally {
      _isFlushing = false;
      if (_flushRequested) {
        _flushRequested = false;
        unawaited(_flushQueue());
      }
    }
  }

  Future<void> forceFlush() => _flushQueue();
}
