import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naviigo_app/core/location/geolocator_location_adapter.dart';
import 'package:naviigo_app/core/location/live_fix.dart';
import 'package:naviigo_app/core/location/location_adapter.dart';

/// On-device proof that the real platform adapter is wired to the real plugin.
///
/// This runs against the actual Android geolocator, so it fails if the plugin
/// registration, the manifest permissions, or the platform channel is broken —
/// which a unit test with a fake adapter can never catch.
/// Real plugin calls use `runAsync` so the driver harness does not leave their
/// platform replies waiting behind its simulated widget-test clock.
///
/// Prepare the device first:
///   adb emu geo fix 75.7900 26.9150   # longitude first, then latitude
///   adb shell pm grant com.naviigo.naviigo_app \
///     android.permission.ACCESS_FINE_LOCATION
///   flutter test integration_test/location_adapter_device_test.dart \
///     -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const adapter = GeolocatorLocationAdapter();

  // Jaipur, matching the value pushed with `adb emu geo fix`.
  const expectedLat = 26.9150;
  const expectedLng = 75.7900;

  /// A read that never raises the permission prompt. Used as a gate so a
  /// missing grant fails immediately and legibly instead of blocking on a
  /// system dialog nobody is there to answer.
  Future<void> requireGrantedPermission() async {
    final probe = await adapter.current();
    expect(
      probe.permissionGranted,
      isTrue,
      reason:
          'Grant the permission before running this test — see the file '
          'header. Got failure: ${probe.failure}',
    );
  }

  testWidgets(
    'returns a real fix from the platform, not a fabricated one',
    (tester) async {
      await tester.runAsync(() async {
        await requireGrantedPermission();

        final result = await adapter.current(userInitiated: true);

        final fix = result.fix;
        // ignore: avoid_print
        print(
          'DEVICE PROBE: failure=${result.failure} granted=${result.permissionGranted} '
          'lat=${fix?.lat} lng=${fix?.lng} accuracy=${fix?.accuracyMeters} '
          'source=${fix?.source}',
        );

        expect(
          result.failure,
          isNull,
          reason:
              'expected location services on and a readable position; '
              'got ${result.failure}',
        );
        expect(result.permissionGranted, isTrue);
        expect(result.hasFix, isTrue);

        // Loosely bounded: the emulator honours geo fix, but the assertion is
        // about a genuine platform reading rather than an exact coordinate.
        expect(fix!.lat, closeTo(expectedLat, 0.5));
        expect(fix.lng, closeTo(expectedLng, 0.5));
        expect(fix.source, LiveFixSource.device);
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'a real fix is fresh enough for the start gate',
    (tester) async {
      await tester.runAsync(() async {
        await requireGrantedPermission();

        final result = await adapter.current(userInitiated: true);
        expect(result.hasFix, isTrue);

        final age = DateTime.now().difference(result.fix!.timestamp);
        expect(
          age,
          lessThan(LocationPolicy.maxFixAge),
          reason: 'a platform reading must be current, not a cached coordinate',
        );
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'a read the traveller did not ask for never raises a prompt',
    (tester) async {
      await tester.runAsync(() async {
        await requireGrantedPermission();

        // With the permission already held this returns a fix. The property under
        // test is that the call completes without the OS ever prompting, which is
        // what keeps the app from asking for location at launch.
        final result = await adapter.current();
        expect(result.permissionGranted, isTrue);
        expect(result.failure, isNull);
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
