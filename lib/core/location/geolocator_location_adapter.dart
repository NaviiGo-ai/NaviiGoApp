import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'live_fix.dart';
import 'location_adapter.dart';

/// The platform implementation of [LocationAdapter], backed by `geolocator`.
///
/// This is the only file in the app that knows the plugin exists. Everything
/// else sees [LocationResult] and [LiveFix]. It reads *foreground* position
/// only — the app never starts a position stream, never tracks in the
/// background, and never writes a coordinate anywhere.
class GeolocatorLocationAdapter implements LocationAdapter {
  const GeolocatorLocationAdapter();

  @override
  Future<LocationResult> current({bool userInitiated = false}) async {
    try {
      final permission = await _resolvePermission(userInitiated);
      if (permission != null) return permission;

      // Permission granted is not the same as location switched on. The OS
      // toggle lives in a different setting, so it gets a different state.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(
          permissionGranted: true,
          failure: LocationFailure.servicesDisabled,
        );
      }

      return LocationResult(
        fix: await _acquireFix(),
        permissionGranted: true,
      );
    } on TimeoutException {
      return const LocationResult(
        permissionGranted: true,
        failure: LocationFailure.timeout,
      );
    } on PermissionDeniedException {
      return const LocationResult(
        failure: LocationFailure.permissionDenied,
      );
    } on LocationServiceDisabledException {
      return const LocationResult(
        permissionGranted: true,
        failure: LocationFailure.servicesDisabled,
      );
    } catch (_) {
      // Anything else is not something the traveller can act on, so it is
      // reported as an unreadable position rather than guessed at.
      return const LocationResult(
        permissionGranted: true,
        failure: LocationFailure.unavailable,
      );
    }
  }

  /// Returns a terminal result when the permission state blocks a reading, or
  /// null when the app may proceed.
  Future<LocationResult?> _resolvePermission(bool userInitiated) async {
    var permission = await Geolocator.checkPermission();

    // The prompt is shown only when the traveller asked for a reading. Never at
    // launch, never on a rebuild, never in a loop.
    if (permission == LocationPermission.denied && userInitiated) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.deniedForever:
        return const LocationResult(
          failure: LocationFailure.permissionPermanentlyDenied,
        );
      case LocationPermission.denied:
        return const LocationResult(failure: LocationFailure.permissionDenied);
      case LocationPermission.unableToDetermine:
        return const LocationResult(failure: LocationFailure.restricted);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return null;
    }
  }

  /// One bounded sequence of readings, stopping early once the fix is good
  /// enough to prove proximity. A coarse fix is still *returned* rather than
  /// discarded — the start gate owns the accuracy rule and names the failure,
  /// so there is exactly one authoritative place that decides "not good
  /// enough".
  Future<LiveFix> _acquireFix() async {
    LiveFix? best;
    for (var attempt = 0; attempt < LocationPolicy.maxAccuracyAttempts; attempt++) {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: LocationPolicy.fixTimeout,
        ),
      );
      final fix = LiveFix(
        lat: position.latitude,
        lng: position.longitude,
        accuracyMeters: position.hasAccuracy ? position.accuracy : null,
        timestamp: position.timestamp,
      );
      if (best == null || _isSharper(fix, best)) best = fix;
      if ((fix.accuracyMeters ?? double.infinity) <=
          LocationPolicy.maxAccuracyMeters) {
        break;
      }
      if (attempt < LocationPolicy.maxAccuracyAttempts - 1) {
        await Future<void>.delayed(LocationPolicy.accuracyRetryDelay);
      }
    }
    return best!;
  }

  static bool _isSharper(LiveFix candidate, LiveFix incumbent) =>
      (candidate.accuracyMeters ?? double.infinity) <
      (incumbent.accuracyMeters ?? double.infinity);

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
