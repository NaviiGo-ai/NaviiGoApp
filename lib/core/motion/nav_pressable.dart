import 'package:flutter/material.dart';

import 'nav_haptics.dart';
import 'nav_motion.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// NAVIIGO PRESS FEEDBACK (§57)
///
/// Every important button acknowledges the finger. Scale is barely perceptible
/// (0.97) — enough that the surface feels physical, not enough to look bouncy.
/// Under reduced motion the scale is dropped and the response becomes a plain
/// opacity dip, so the affordance survives without the movement (§65).
///
/// Use this for custom-drawn surfaces (cards, tiles, pills). Material buttons
/// keep their own ink response; this is for the ones we draw ourselves.
/// ─────────────────────────────────────────────────────────────────────────────
class NavPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Fired on press-down. Omit for purely visual surfaces — see §63 on not
  /// spending haptics on everything.
  final NavHaptic? haptic;

  final double scale;
  final BorderRadius? borderRadius;

  /// When false the child renders normally and ignores taps.
  final bool enabled;

  const NavPressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic,
    this.scale = NavMotion.pressScale,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<NavPressable> createState() => _NavPressableState();
}

class _NavPressableState extends State<NavPressable> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_interactive) return widget.child;

    final bool reduced = NavReduce.of(context);

    Widget content = widget.child;
    if (!reduced) {
      content = AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: NavMotion.instant,
        curve: NavMotion.response,
        child: content,
      );
    } else {
      content = AnimatedOpacity(
        opacity: _pressed ? 0.72 : 1.0,
        duration: NavMotion.instant,
        child: content,
      );
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          if (widget.haptic != null) {
            NavHaptics.fire(widget.haptic!);
          }
          widget.onTap?.call();
        },
        child: content,
      ),
    );
  }
}
