import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// NAVIIGO MOTION SYSTEM
///
/// The single source of truth for how Naviigo moves. Motion here exists to
/// communicate — WHERE I CAME FROM, WHERE I AM GOING, WHAT CHANGED, WHAT IS
/// ACTIVE, WHAT IS NEXT, HOW MY JOURNEY IS PROGRESSING — never to decorate.
///
/// Rule: no `Duration(milliseconds: 317)` anywhere in a widget. Reach for a
/// token. If no token fits, the motion is probably wrong, not the token set.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class NavMotion {
  const NavMotion._();

  // ─── Duration Tokens ────────────────────────────────────────────────────────

  /// 100–140ms — press feedback, icon morphs, chip toggles.
  /// Should feel like the surface answering your finger.
  static const Duration instant = Duration(milliseconds: 120);

  /// 140–190ms — tab switches, small state changes, selection moves.
  static const Duration fast = Duration(milliseconds: 165);

  /// 220–320ms — the default. Cards resolving, sheets settling, list reflow.
  static const Duration standard = Duration(milliseconds: 270);

  /// 350–550ms — editorial reveals. Headlines, imagery, section entrances.
  static const Duration editorial = Duration(milliseconds: 450);

  /// 550–800ms — immersive moments. Home → Live, journey completion.
  /// Hard ceiling for a "signature" transition: the user must never wait.
  static const Duration immersive = Duration(milliseconds: 675);

  /// 800–1500ms — atmospheric only. Environmental theme interpolation.
  /// Never gates a primary action.
  static const Duration atmospheric = Duration(milliseconds: 1150);

  // ─── Easing ─────────────────────────────────────────────────────────────────
  // No bounce by default — Naviigo is a travel companion, not a toy.

  /// Fast response to input. Presses, toggles, immediate state.
  static const Curve response = Curves.easeOutCubic;

  /// Editorial reveals. Typography and imagery arriving with weight.
  static const Curve editorialCurve = Curves.easeOutQuart;

  /// Spatial movement — things travelling from one place to another.
  static const Curve movement = Curves.easeInOutCubic;

  /// Settling — a surface coming to rest.
  static const Curve settle = Curves.easeOutQuint;

  /// Physical sheets and drag interactions ONLY. The one place spring is allowed.
  static const Curve physical = Curves.easeOutBack;

  // ─── Stagger ────────────────────────────────────────────────────────────────
  // Stagger is for hierarchy, not spectacle. 2–3 pieces maximum (see §7).

  /// 45ms — tight pairs, e.g. icon + label.
  static const Duration staggerTight = Duration(milliseconds: 45);

  /// 80ms — the default cascade between related elements.
  static const Duration stagger = Duration(milliseconds: 80);

  /// 120ms — editorial cascades across a masthead.
  static const Duration staggerEditorial = Duration(milliseconds: 120);

  // ─── Scale ──────────────────────────────────────────────────────────────────

  /// Button press. Tactile, never toy-like (§57).
  static const double pressScale = 0.97;

  /// Bottom-nav icon morph range (§4: 4–8%, no giant jumping icons).
  static const double navIconScale = 1.06;

  // ─── Animation Handles ──────────────────────────────────────────────────────

  /// A standard curve for a token, so call sites stay symmetrical.
  static Curve curveFor(Duration token) {
    if (token <= fast) return response;
    if (token <= standard) return movement;
    if (token <= editorial) return editorialCurve;
    return settle;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// REDUCED MOTION (§65)
///
/// Respects the OS "Reduce Motion" / "Remove Animations" setting.
/// With reduced motion: hero flights become short fades/scales, parallax and
/// decorative weather stop, the Journey Line still communicates state change
/// (it just transitions instantly), and safety flows stay immediate.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class NavReduce {
  const NavReduce._();

  /// True when the traveller has asked the system to reduce motion.
  static bool of(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Collapse a duration to effectively-instant when reduced motion is on.
  ///
  /// Use for decorative motion. Do NOT use for the Journey Line's *state*
  /// — that must still visibly change, so pass it through [geometry] instead.
  static Duration duration(BuildContext context, Duration token) {
    return of(context) ? const Duration(milliseconds: 1) : token;
  }

  /// Motion that carries meaning (progress, position, geography) keeps its
  /// geometry but shortens to a quick, legible transition rather than a 1ms cut.
  static Duration geometry(BuildContext context, Duration token) {
    return of(context) ? NavMotion.instant : token;
  }

  /// Fraction of a decorative travel/parallax effect to apply. Zero when reduced.
  static double amount(BuildContext context, double value) {
    return of(context) ? 0.0 : value;
  }
}
