import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// NAVIIGO HAPTIC LANGUAGE (§63)
///
/// Three levels, deliberately. A haptic is a sentence, not punctuation — if
/// everything buzzes, nothing means anything.
///
///   LIGHT  — save, chip select, day select.          "noted."
///   MEDIUM — wizard waypoint, check-in, start share. "that landed."
///   STRONG — Start Trip, SOS threshold, booking confirmed. "this mattered."
///
/// STRONG is reserved. Do not spend it on a toggle.
/// ─────────────────────────────────────────────────────────────────────────────
enum NavHaptic {
  /// Selection and saving. Faint, on the edge of perception.
  light,

  /// A journey waypoint, a check-in, opening a buddy share.
  medium,

  /// Start Trip confirmation, SOS threshold, confirmed booking.
  /// Ration these — they mark moments the traveller will remember.
  strong,
}

abstract final class NavHaptics {
  const NavHaptics._();

  /// Level of haptics the traveller has asked for.
  ///
  /// Mirrors the platform setting; when haptics are off the system simply
  /// ignores the call, so this is safe to fire unconditionally.
  static Future<void> fire(NavHaptic level) async {
    switch (level) {
      case NavHaptic.light:
        await HapticFeedback.selectionClick();
      case NavHaptic.medium:
        await HapticFeedback.mediumImpact();
      case NavHaptic.strong:
        await HapticFeedback.heavyImpact();
    }
  }
}
