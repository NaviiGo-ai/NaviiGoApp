/// Where a fix came from. `device` is a platform reading; `manual` is a value
/// the traveller or a test supplied. The live layer never invents either.
enum LiveFixSource { device, manual }

/// A single position fix. This is always an *input* to the live layer — the
/// app never fabricates a coordinate, and nothing here is persisted to
/// Firestore.
class LiveFix {
  final double lat;
  final double lng;

  /// Horizontal accuracy in metres as reported by the platform. Null means the
  /// platform did not supply one, not that the fix is perfect.
  final double? accuracyMeters;

  /// When the platform took the reading. Used to reject stale fixes.
  final DateTime timestamp;

  final LiveFixSource source;

  const LiveFix({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.accuracyMeters,
    this.source = LiveFixSource.device,
  });

  /// How old this reading is at [now].
  Duration ageAt(DateTime now) => now.difference(timestamp);
}
