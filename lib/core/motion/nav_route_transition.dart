import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_motion.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// NAVIIGO ROUTE TRANSITIONS (§3)
///
/// Different relationships between screens deserve different motion. A generic
/// slide for everything is how an app ends up feeling like a stack of cards
/// instead of a continuous place.
///
///   SHARED    Explore → Destination, Search → Place.
///             The selected image IS the transition. The route must stay out of
///             its way — a fade, nothing else, so the Hero flight reads as one
///             object moving rather than two screens crossfading.
///
///   PUSH      Forward hierarchy into a child of the current surface.
///             A shallow rise, never a full carousel slide.
///
///   TAB       Peer destinations (the five bottom-nav roots).
///             No direction — these are siblings, not parent/child.
///
///   EXPAND    A surface growing out of the thing you touched — booking detail,
///             gallery viewer, full-screen map.
///
///   MEMORY    Passport → past journey. A memory opening, so it scales up from
///             the card and settles rather than travelling sideways.
/// ─────────────────────────────────────────────────────────────────────────────
enum NavRouteKind { shared, push, tab, expand, memory }

abstract final class NavRouteTransition {
  const NavRouteTransition._();

  /// Build a page whose motion matches the relationship between the screens.
  static Page<void> page({
    required GoRouterState state,
    required Widget child,
    NavRouteKind kind = NavRouteKind.push,
  }) {
    return CustomTransitionPage<void>(
      key: ValueKey('${state.uri}_${child.runtimeType}_${kind.name}'),
      child: child,
      transitionDuration: _durationFor(kind),
      reverseTransitionDuration: _reverseDurationFor(kind),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduced = NavReduce.of(context);
        return _build(
          context,
          animation,
          secondaryAnimation,
          child,
          kind,
          reduced,
        );
      },
    );
  }

  static Duration _durationFor(NavRouteKind kind) => switch (kind) {
    // Long enough for the shared image to actually travel.
    NavRouteKind.shared => NavMotion.editorial,
    NavRouteKind.push => NavMotion.standard,
    NavRouteKind.tab => NavMotion.fast,
    NavRouteKind.expand => NavMotion.editorial,
    NavRouteKind.memory => NavMotion.immersive,
  };

  static Duration _reverseDurationFor(NavRouteKind kind) => switch (kind) {
    // Returns are always allowed to be quicker than arrivals.
    NavRouteKind.shared => NavMotion.standard,
    NavRouteKind.push => NavMotion.fast,
    NavRouteKind.tab => NavMotion.fast,
    NavRouteKind.expand => NavMotion.standard,
    NavRouteKind.memory => NavMotion.editorial,
  };

  static Widget _build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    NavRouteKind kind,
    bool reduced,
  ) {
    // ── Reduced motion (§65): state changes stay legible, travel stops. ──
    if (reduced) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: NavMotion.response),
        child: child,
      );
    }

    switch (kind) {
      case NavRouteKind.shared:
        // Deliberately bare. The Hero carries the whole story; any slide or
        // scale here would compete with it and make the image look like it
        // jumps between two different animations.
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: NavMotion.movement,
          ),
          child: child,
        );

      case NavRouteKind.push:
        final curved = CurvedAnimation(
          parent: animation,
          curve: NavMotion.editorialCurve,
          reverseCurve: NavMotion.response,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: NavMotion.response,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              // Shallow: this is depth, not a deck of cards.
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );

      case NavRouteKind.tab:
        // Fade-through: the outgoing peer recedes before the incoming arrives,
        // so switching tabs reads as changing place, not stacking pages.
        final incoming = CurvedAnimation(
          parent: animation,
          curve: NavMotion.response,
        );
        final outgoing = CurvedAnimation(
          parent: secondaryAnimation,
          curve: NavMotion.response,
        );
        return FadeTransition(
          opacity: incoming,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(incoming),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(outgoing),
              child: child,
            ),
          ),
        );

      case NavRouteKind.expand:
        final curved = CurvedAnimation(
          parent: animation,
          curve: NavMotion.settle,
          reverseCurve: NavMotion.response,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: NavMotion.response,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );

      case NavRouteKind.memory:
        final curved = CurvedAnimation(
          parent: animation,
          curve: NavMotion.settle,
          reverseCurve: NavMotion.response,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: NavMotion.editorialCurve,
          ),
          child: ScaleTransition(
            // Comes forward out of the card rather than sliding in.
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
    }
  }
}
