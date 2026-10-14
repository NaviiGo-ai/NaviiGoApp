import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/cache/hive_service.dart';
import '../../domain/models/trip_itinerary_model.dart';
import 'trip_provider.dart';

class RouteSample {
  final double lat, lng;
  final DateTime at;
  const RouteSample(this.lat, this.lng, this.at);
  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'at': at.toIso8601String(),
  };
}

double routeDistanceKm(List<RouteSample> points) {
  double distance = 0;
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1], b = points[i];
    // A suspended app leaves an unobserved gap, not a measured straight line.
    if (b.at.difference(a.at).inSeconds > 120) continue;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(a.lat * math.pi / 180) *
            math.cos(b.lat * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    distance += 6371 * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
  }
  return distance;
}

class RecordingState {
  final List<RouteSample> points;
  final bool recording;
  final String? error;
  const RecordingState({
    this.points = const [],
    this.recording = false,
    this.error,
  });
}

typedef RecordingKey = ({String ownerUid, String tripId});
final journeyRecordingProvider =
    StateNotifierProvider.family<JourneyRecorder, RecordingState, RecordingKey>(
      (ref, key) {
        final uid = ref.watch(currentUserIdProvider);
        bool canRecord() {
          if (ref.read(currentUserIdProvider) != key.ownerUid) return false;
          return (ref.read(userTripsStreamProvider).valueOrNull ??
                  const <TripItineraryModel>[])
              .any(
                (t) =>
                    t.id == key.tripId &&
                    t.userId == key.ownerUid &&
                    !t.isEphemeral &&
                    t.tripStatus == TripStatus.active,
              );
        }

        final recorder = JourneyRecorder(
          key,
          allowed: canRecord,
          load: uid == key.ownerUid,
        );
        ref.listen(userTripsStreamProvider, (_, __) {
          if (!canRecord()) recorder.stop();
        });
        return recorder;
      },
    );

class JourneyRecorder extends StateNotifier<RecordingState>
    with WidgetsBindingObserver {
  final RecordingKey key;
  final bool Function() allowed;
  final Future<void> Function() _locationReady;
  final Stream<Position> Function() _positions;
  StreamSubscription<Position>? _subscription;
  Future<void> _writes = Future.value();
  Future<void> get pendingWrites => _writes;
  bool _alive = true;
  bool _starting = false;
  bool _foreground = true;
  int _startGeneration = 0;
  JourneyRecorder(
    this.key, {
    required this.allowed,
    bool load = true,
    Future<void> Function()? locationReady,
    Stream<Position> Function()? positions,
  }) : _locationReady = locationReady ?? _requestLocation,
       _positions =
           positions ??
           (() => Geolocator.getPositionStream(
             locationSettings: const LocationSettings(
               accuracy: LocationAccuracy.high,
               distanceFilter: 15,
             ),
           )),
       super(const RecordingState()) {
    WidgetsBinding.instance.addObserver(this);
    if (load) {
      try {
        final raw = HiveService.itineraryBox.get(cacheKey(key));
        if (raw is Map &&
            raw['ownerUid'] == key.ownerUid &&
            raw['tripId'] == key.tripId &&
            raw['points'] is List) {
          final points = <RouteSample>[];
          for (final p in (raw['points'] as List).take(2000).whereType<Map>()) {
            final lat = p['lat'],
                lng = p['lng'],
                at = DateTime.tryParse(p['at']?.toString() ?? '');
            if (lat is num &&
                lng is num &&
                lat.isFinite &&
                lng.isFinite &&
                lat.abs() <= 90 &&
                lng.abs() <= 180 &&
                at != null) {
              points.add(RouteSample(lat.toDouble(), lng.toDouble(), at));
            }
          }
          state = RecordingState(points: List.unmodifiable(points));
        }
      } catch (_) {
        /* An unavailable local cache must not crash navigation. */
      }
    }
  }

  static String cacheKey(RecordingKey key) =>
      'journey_trace:${key.ownerUid.length}:${key.ownerUid}:${key.tripId}';

  Future<void> start() async {
    if (_starting || state.recording || !_alive || !_foreground || !allowed()) {
      return;
    }
    _starting = true;
    final generation = _startGeneration;
    try {
      await _locationReady();
      if (!_alive ||
          !_foreground ||
          generation != _startGeneration ||
          !allowed()) {
        return;
      }
      state = RecordingState(points: state.points, recording: true);
      _subscription = _positions().listen(
        addPosition,
        onError: (_) => stop(
          error: 'Location recording stopped. Check permissions and try again.',
        ),
      );
    } catch (error) {
      if (_alive) {
        state = RecordingState(
          points: state.points,
          error: error is StateError
              ? error.message.toString()
              : 'Could not start route recording.',
        );
      }
    } finally {
      _starting = false;
    }
  }

  static Future<void> _requestLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on location services to record your route.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is needed for route recording.');
    }
  }

  void addPosition(Position fix) {
    if (!_alive || !state.recording) return;
    if (!allowed()) {
      stop();
      return;
    }
    final now = DateTime.now();
    if (!fix.latitude.isFinite ||
        !fix.longitude.isFinite ||
        fix.latitude.abs() > 90 ||
        fix.longitude.abs() > 180 ||
        !fix.accuracy.isFinite ||
        fix.accuracy > 50 ||
        fix.accuracy < 0 ||
        now.difference(fix.timestamp).inSeconds.abs() > 30) {
      return;
    }
    final sample = RouteSample(fix.latitude, fix.longitude, fix.timestamp);
    if (state.points.isNotEmpty) {
      final previous = state.points.last;
      final seconds = sample.at.difference(previous.at).inSeconds;
      final distance = routeDistanceKm([previous, sample]);
      if (seconds < 10 ||
          (seconds <= 120 &&
              (distance < 0.01 || distance / (seconds / 3600) > 250))) {
        return;
      }
    }
    if (state.points.length >= 2000) {
      stop(error: 'Recording reached 2,000 points. Your route is saved.');
      return;
    }
    final points = List<RouteSample>.unmodifiable([...state.points, sample]);
    state = RecordingState(points: points, recording: true);
    _writes = _writes
        .then(
          (_) => HiveService.itineraryBox.put(cacheKey(key), {
            'ownerUid': key.ownerUid,
            'tripId': key.tripId,
            'points': points.map((p) => p.toMap()).toList(),
          }),
        )
        .catchError((Object _) {
          if (_alive) {
            stop(
              error:
                  'Local storage failed. Recording stopped to protect your route.',
            );
          }
        });
  }

  void stop({String? error}) {
    _startGeneration++;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (_alive) state = RecordingState(points: state.points, error: error);
  }

  Future<void> clear() async {
    stop();
    await _writes;
    await HiveService.itineraryBox.delete(cacheKey(key));
    if (_alive) state = const RecordingState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alive = false;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
