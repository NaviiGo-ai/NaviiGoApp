import 'live_fix.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LOCATION POLICY
/// The numbers that decide whether a fix is good enough to prove where someone
/// is. They live here, in core, so the adapter's retry strategy and the start
/// gate's validation cannot drift apart.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class LocationPolicy {
  /// A fix looser than this cannot prove the traveller is in the start region.
  static const double maxAccuracyMeters = 500;

  /// How close counts as "at the start". Covers a city plus its airport.
  static const double startRegionRadiusKm = 25;

  /// A fix older than this is not evidence of where someone is *now*.
  static const Duration maxFixAge = Duration(minutes: 5);

  /// Bounded wait for one position reading.
  static const Duration fixTimeout = Duration(seconds: 20);

  /// Bounded attempts when the first reading is too coarse.
  static const int maxAccuracyAttempts = 3;

  /// Pause between accuracy attempts.
  static const Duration accuracyRetryDelay = Duration(seconds: 2);
}

/// Why a location read did not produce a usable fix. Every value maps to a
/// distinct, actionable screen state — the UI must never blur these into a
/// generic "no location".
enum LocationFailure {
  /// Declined, but the OS may still show the prompt again.
  permissionDenied,

  /// Declined for good. Only Settings can change this.
  permissionPermanentlyDenied,

  /// The OS restricts location for this app (parental controls, device policy).
  restricted,

  /// Permission may be granted, but device location is switched off. This is a
  /// separate state from a permission problem and is fixed elsewhere.
  servicesDisabled,

  /// No reading arrived inside the bounded wait.
  timeout,

  /// This build has no platform location implementation, or the platform
  /// returned something unreadable.
  unavailable,
}

/// The outcome of one location read, normalised so no plugin type escapes this
/// file.
class LocationResult {
  final LiveFix? fix;
  final LocationFailure? failure;
  final bool permissionGranted;

  const LocationResult({
    this.fix,
    this.failure,
    this.permissionGranted = false,
  });

  bool get hasFix => fix != null;

  /// Only offer Settings when the OS will not prompt again on its own.
  bool get canOpenAppSettings =>
      failure == LocationFailure.permissionPermanentlyDenied ||
      failure == LocationFailure.restricted;

  /// Turning location services back on is a different setting to app
  /// permission, so it gets its own action.
  bool get canOpenLocationSettings =>
      failure == LocationFailure.servicesDisabled;

  /// Naviigo's voice: say what happened and what it means, never a permission
  /// constant.
  String get message {
    switch (failure) {
      case LocationFailure.permissionDenied:
        return 'Naviigo needs your location to confirm you are near the start. '
            'You can allow it and try again.';
      case LocationFailure.permissionPermanentlyDenied:
        return 'Location is blocked for Naviigo. You can turn it back on in '
            'Settings.';
      case LocationFailure.restricted:
        return 'Location is restricted on this device, so the start cannot be '
            'verified here.';
      case LocationFailure.servicesDisabled:
        return 'Location is turned off. Enable it to verify your trip start.';
      case LocationFailure.timeout:
        return "Couldn't get a reliable location. Head somewhere with a clearer "
            'view of the sky and try again.';
      case LocationFailure.unavailable:
        return 'Location could not be read on this device.';
      case null:
        return 'Position updated.';
    }
  }
}

/// The one seam between Naviigo and the platform's location services. Widgets
/// and providers depend on this, never on a plugin.
abstract class LocationAdapter {
  /// Read the current position.
  ///
  /// [userInitiated] must be true only when the traveller explicitly asked —
  /// it is the only condition under which the OS permission prompt is shown,
  /// so permission is never requested repeatedly or at launch.
  Future<LocationResult> current({bool userInitiated = false});

  /// Open the OS screen for this app's permissions. Only ever called from an
  /// explicit OPEN SETTINGS action; the app never navigates there on its own.
  Future<bool> openAppSettings();

  /// Open the OS location-services switch.
  Future<bool> openLocationSettings();
}

/// Reports the gap honestly instead of returning a made-up coordinate; the
/// start gate fails closed on it like any other missing input.
class UnavailableLocationAdapter implements LocationAdapter {
  const UnavailableLocationAdapter();

  @override
  Future<LocationResult> current({bool userInitiated = false}) async =>
      const LocationResult(
        failure: LocationFailure.unavailable,
        permissionGranted: false,
      );

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<bool> openLocationSettings() async => false;
}
