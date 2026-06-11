import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/dashboard/presentation/pages/upcoming_trips_page.dart';
import '../../features/dashboard/presentation/pages/ongoing_trips_page.dart';
import '../../features/dashboard/presentation/pages/live_tracking_page.dart';
import '../../features/dashboard/presentation/pages/analytics_page.dart';
import '../../features/explore/presentation/pages/hidden_gems_page.dart';
import '../../features/explore/presentation/pages/restaurants_page.dart';
import '../../features/explore/presentation/pages/transportation_page.dart';
import '../../features/bookings/presentation/pages/saved_places_page.dart';
import '../../features/bookings/presentation/pages/payment_history_page.dart';
import '../../features/bookings/presentation/pages/digital_passport_page.dart';
import '../../features/more/presentation/pages/story_creator_page.dart';
import '../../features/more/presentation/pages/settings_page.dart';
import '../../features/more/presentation/pages/help_support_page.dart';

import '../../features/navigation/presentation/nav_hub_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
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
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/upcoming-trips',
          builder: (context, state) => const UpcomingTripsPage(),
        ),
        GoRoute(
          path: '/ongoing-trips',
          builder: (context, state) => const OngoingTripsPage(),
        ),
        GoRoute(
          path: '/live-tracking',
          builder: (context, state) => const LiveTrackingPage(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsPage(),
        ),

        // EXPLORE
        GoRoute(
          path: '/hidden-gems',
          builder: (context, state) => const HiddenGemsPage(),
        ),
        GoRoute(
          path: '/restaurants',
          builder: (context, state) => const RestaurantsPage(),
        ),
        GoRoute(
          path: '/transportation',
          builder: (context, state) => const TransportationPage(),
        ),

        // MY BOOKINGS
        GoRoute(
          path: '/saved-places',
          builder: (context, state) => const SavedPlacesPage(),
        ),
        GoRoute(
          path: '/payment-history',
          builder: (context, state) => const PaymentHistoryPage(),
        ),
        GoRoute(
          path: '/digital-passport',
          builder: (context, state) => const DigitalPassportPage(),
        ),

        // MORE
        GoRoute(
          path: '/story-creator',
          builder: (context, state) => const StoryCreatorPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/help-support',
          builder: (context, state) => const HelpSupportPage(),
        ),
      ],
    ),
  ],
);
