import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/nav_route_transition.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_wizard_page.dart';
import '../../features/auth/presentation/pages/vibe_match_page.dart';
import '../../features/explore/presentation/pages/ar_explore_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/dashboard/presentation/pages/upcoming_trips_page.dart';
import '../../features/dashboard/presentation/pages/ongoing_trips_page.dart';
import '../../features/dashboard/presentation/pages/past_trips_page.dart';
import '../../features/dashboard/presentation/pages/live_tracking_page.dart';
import '../../features/dashboard/presentation/pages/analytics_page.dart';
import '../../features/explore/presentation/pages/hidden_gems_page.dart';
import '../../features/explore/presentation/pages/trip_planner_page.dart';
import '../../features/explore/presentation/pages/explore_discover_page.dart';
import '../../features/explore/presentation/pages/map_page.dart';
import '../../features/trips/presentation/pages/generated_itinerary_page.dart';
import '../../features/trips/domain/models/trip_itinerary_model.dart';
import '../../features/explore/presentation/pages/restaurants_page.dart';
import '../../features/explore/presentation/pages/restaurant_details_page.dart';
import '../../features/explore/presentation/pages/transportation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/bookings/presentation/pages/saved_places_page.dart';
import '../../features/bookings/presentation/pages/payment_history_page.dart';
import '../../features/bookings/presentation/pages/digital_passport_page.dart';
import '../../features/bookings/presentation/pages/bookings_page.dart';
import '../../features/more/presentation/pages/story_creator_page.dart';
import '../../features/more/presentation/pages/settings_page.dart';
import '../../features/more/presentation/pages/help_support_page.dart';
import '../../features/destinations/presentation/pages/destination_details_page.dart';
import '../../features/places/domain/models/place_model.dart';
import '../../features/places/presentation/pages/place_details_page.dart';
import '../../features/explore/presentation/pages/local_guides_page.dart';

import '../../features/navigation/presentation/nav_hub_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// Shorthand so each route below declares *why* it moves, not how.
Page<void> _page(
  GoRouterState state,
  Widget child, {
  NavRouteKind kind = NavRouteKind.push,
}) {
  return NavRouteTransition.page(state: state, child: child, kind: kind);
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _page(state, const LoginPage()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          _page(state, const OnboardingWizardPage()),
    ),
    GoRoute(
      path: '/vibe-match',
      pageBuilder: (context, state) => _page(state, const VibeMatchPage()),
    ),

    // ── SHARED-ELEMENT ARRIVALS (§3, §10, §15) ──────────────────────────────
    // The tapped image becomes the destination hero. The route only fades so
    // the Hero flight is the single, legible motion on screen.
    GoRoute(
      path: '/destination/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? 'george_everest';
        return _page(
          state,
          DestinationDetailsPage(id: id),
          kind: NavRouteKind.shared,
        );
      },
    ),
    GoRoute(
      path: '/place-details',
      pageBuilder: (context, state) {
        final place = state.extra is PlaceModel
            ? state.extra as PlaceModel
            : const PlaceModel(id: 'place_default', name: 'Curated Place');
        return _page(
          state,
          PlaceDetailsPage(place: place),
          kind: NavRouteKind.shared,
        );
      },
    ),
    GoRoute(
      path: '/restaurant/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '1';
        return _page(
          state,
          RestaurantDetailsPage(id: id),
          kind: NavRouteKind.shared,
        );
      },
    ),
    GoRoute(
      path: '/trip-planner',
      pageBuilder: (context, state) => _page(state, const TripPlannerPage()),
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return NavHubPage(child: child);
      },
      routes: <RouteBase>[
        // ── TAB ROOTS (§3, §4) — peers, so no direction of travel. ──────────
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              _page(state, const HomePage(), kind: NavRouteKind.tab),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) =>
              _page(state, const ExploreDiscoverPage(), kind: NavRouteKind.tab),
        ),
        GoRoute(
          path: '/explore-discover',
          pageBuilder: (context, state) =>
              _page(state, const ExploreDiscoverPage(), kind: NavRouteKind.tab),
        ),
        GoRoute(
          path: '/places',
          pageBuilder: (context, state) =>
              _page(state, const ExploreDiscoverPage(), kind: NavRouteKind.tab),
        ),
        GoRoute(
          path: '/trips',
          pageBuilder: (context, state) => _page(
            state,
            GeneratedItineraryPage(
              trip: state.extra is TripItineraryModel
                  ? state.extra as TripItineraryModel
                  : null,
            ),
            kind: NavRouteKind.tab,
          ),
        ),
        GoRoute(
          path: '/digital-passport',
          pageBuilder: (context, state) =>
              _page(state, const DigitalPassportPage(), kind: NavRouteKind.tab),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              _page(state, const ProfilePage(), kind: NavRouteKind.tab),
        ),

        // ── JOURNEYS ───────────────────────────────────────────────────────
        // Plan → Itinerary: shares the Journey Line, so it arrives rather than
        // sliding (§3, §20).
        GoRoute(
          path: '/itinerary',
          pageBuilder: (context, state) => _page(
            state,
            GeneratedItineraryPage(
              trip: state.extra is TripItineraryModel
                  ? state.extra as TripItineraryModel
                  : null,
            ),
            kind: NavRouteKind.shared,
          ),
        ),
        GoRoute(
          path: '/upcoming-trips',
          pageBuilder: (context, state) =>
              _page(state, const UpcomingTripsPage()),
        ),
        GoRoute(
          path: '/ongoing-trips',
          pageBuilder: (context, state) =>
              _page(state, const OngoingTripsPage()),
        ),
        GoRoute(
          path: '/live-tracking',
          pageBuilder: (context, state) =>
              _page(state, const LiveTrackingPage()),
        ),
        GoRoute(
          path: '/past-trips',
          pageBuilder: (context, state) => _page(state, const PastTripsPage()),
        ),
        // Passport → past journey: a memory opening, not a lateral move (§43).
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) =>
              _page(state, const AnalyticsPage(), kind: NavRouteKind.memory),
        ),

        // ── DISCOVER ───────────────────────────────────────────────────────
        GoRoute(
          path: '/hidden-gems',
          pageBuilder: (context, state) => _page(state, const HiddenGemsPage()),
        ),
        GoRoute(
          path: '/restaurants',
          pageBuilder: (context, state) =>
              _page(state, const RestaurantsPage()),
        ),
        GoRoute(
          path: '/transportation',
          pageBuilder: (context, state) =>
              _page(state, const TransportationPage()),
        ),
        GoRoute(
          path: '/local-guides',
          pageBuilder: (context, state) =>
              _page(state, const LocalGuidesPage()),
        ),
        // Small map preview → full screen, so it expands rather than pushes
        // (§25).
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) =>
              _page(state, const MapPage(), kind: NavRouteKind.expand),
        ),
        GoRoute(
          path: '/ar-explore',
          pageBuilder: (context, state) =>
              _page(state, const ARExplorePage(), kind: NavRouteKind.expand),
        ),

        // ── TRAVEL WALLET ──────────────────────────────────────────────────
        GoRoute(
          path: '/saved-places',
          pageBuilder: (context, state) =>
              _page(state, const SavedPlacesPage()),
        ),
        GoRoute(
          path: '/payment-history',
          pageBuilder: (context, state) =>
              _page(state, const PaymentHistoryPage()),
        ),
        GoRoute(
          path: '/bookings',
          pageBuilder: (context, state) => _page(state, const BookingsPage()),
        ),

        // ── STORIES & ACCOUNT ──────────────────────────────────────────────
        // The story canvas grows out of the moments you selected (§46).
        GoRoute(
          path: '/story-creator',
          pageBuilder: (context, state) =>
              _page(state, const StoryCreatorPage(), kind: NavRouteKind.expand),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _page(state, const SettingsPage()),
        ),
        GoRoute(
          path: '/help-support',
          pageBuilder: (context, state) =>
              _page(state, const HelpSupportPage()),
        ),
      ],
    ),
  ],
);
