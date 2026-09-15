import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

Page<dynamic> _buildFadeSlideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: ValueKey('${state.uri}_${child.runtimeType}_slide'),
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> _buildFadeThroughTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: ValueKey('${state.uri}_${child.runtimeType}_fade'),
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _buildFadeSlideTransition(state: state, child: const LoginPage()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildFadeSlideTransition(
        state: state,
        child: const OnboardingWizardPage(),
      ),
    ),
    GoRoute(
      path: '/vibe-match',
      pageBuilder: (context, state) =>
          _buildFadeSlideTransition(state: state, child: const VibeMatchPage()),
    ),
    GoRoute(
      path: '/destination/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? 'george_everest';
        return _buildFadeSlideTransition(
          state: state,
          child: DestinationDetailsPage(id: id),
        );
      },
    ),
    GoRoute(
      path: '/place-details',
      pageBuilder: (context, state) {
        final place = state.extra is PlaceModel
            ? state.extra as PlaceModel
            : const PlaceModel(id: 'place_default', name: 'Curated Place');
        return _buildFadeSlideTransition(
          state: state,
          child: PlaceDetailsPage(place: place),
        );
      },
    ),
    GoRoute(
      path: '/trip-planner',
      pageBuilder: (context, state) => _buildFadeSlideTransition(
        state: state,
        child: const TripPlannerPage(),
      ),
    ),
    GoRoute(
      path: '/restaurant/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '1';
        return _buildFadeSlideTransition(
          state: state,
          child: RestaurantDetailsPage(id: id),
        );
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return NavHubPage(child: child);
      },
      routes: <RouteBase>[
        // DASHBOARD
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) =>
              _buildFadeThroughTransition(state: state, child: const MapPage()),
        ),
        GoRoute(
          path: '/ar-explore',
          pageBuilder: (context, state) => _buildFadeSlideTransition(
            state: state,
            child: const ARExplorePage(),
          ),
        ),
        GoRoute(
          path: '/upcoming-trips',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const UpcomingTripsPage(),
          ),
        ),
        GoRoute(
          path: '/ongoing-trips',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const OngoingTripsPage(),
          ),
        ),
        GoRoute(
          path: '/live-tracking',
          pageBuilder: (context, state) => _buildFadeSlideTransition(
            state: state,
            child: const LiveTrackingPage(),
          ),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const AnalyticsPage(),
          ),
        ),
        GoRoute(
          path: '/past-trips',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const PastTripsPage(),
          ),
        ),

        // MAIN BOTTOM NAV ROUTES
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const ExploreDiscoverPage(),
          ),
        ),
        GoRoute(
          path: '/explore-discover',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const ExploreDiscoverPage(),
          ),
        ),
        GoRoute(
          path: '/places',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const ExploreDiscoverPage(),
          ),
        ),
        GoRoute(
          path: '/trips',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: GeneratedItineraryPage(
              trip: state.extra is TripItineraryModel
                  ? state.extra as TripItineraryModel
                  : null,
            ),
          ),
        ),
        GoRoute(
          path: '/itinerary',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: GeneratedItineraryPage(
              trip: state.extra is TripItineraryModel
                  ? state.extra as TripItineraryModel
                  : null,
            ),
          ),
        ),

        // EXPLORE
        GoRoute(
          path: '/hidden-gems',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const HiddenGemsPage(),
          ),
        ),
        GoRoute(
          path: '/restaurants',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const RestaurantsPage(),
          ),
        ),
        GoRoute(
          path: '/transportation',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const TransportationPage(),
          ),
        ),
        GoRoute(
          path: '/local-guides',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const LocalGuidesPage(),
          ),
        ),

        // MY BOOKINGS
        GoRoute(
          path: '/saved-places',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const SavedPlacesPage(),
          ),
        ),
        GoRoute(
          path: '/payment-history',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const PaymentHistoryPage(),
          ),
        ),
        GoRoute(
          path: '/digital-passport',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const DigitalPassportPage(),
          ),
        ),
        GoRoute(
          path: '/bookings',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const BookingsPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const ProfilePage(),
          ),
        ),

        // MORE
        GoRoute(
          path: '/story-creator',
          pageBuilder: (context, state) => _buildFadeSlideTransition(
            state: state,
            child: const StoryCreatorPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/help-support',
          pageBuilder: (context, state) => _buildFadeThroughTransition(
            state: state,
            child: const HelpSupportPage(),
          ),
        ),
      ],
    ),
  ],
);
