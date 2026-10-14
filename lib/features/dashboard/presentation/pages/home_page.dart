import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookings/presentation/providers/saved_places_provider.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../providers/dashboard_providers.dart';
import '../providers/home_provider.dart';
import '../widgets/home_journal_widgets.dart';
import '../widgets/home_phase3_widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AdaptiveThemeExtension.of(context);
    final surface = ref.watch(homeJourneySurfaceProvider);
    final trips = ref.watch(userTripsStreamProvider);
    final activeTrip = ref.watch(activeTripProvider);
    final upcomingTrips = ref.watch(upcomingTripsProvider);
    final upcomingTrip = upcomingTrips.isEmpty ? null : upcomingTrips.first;
    final pastTrips = ref.watch(pastTripsProvider);
    final savedPlaces = ref.watch(safeSavedPlacesProvider);
    final destinations =
        ref.watch(topDestinationsProvider).valueOrNull ?? const [];

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: HomeJournalHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SearchBar(
                  hintText: 'Where do you want to go?',
                  leading: const Icon(Icons.search_rounded),
                  onTap: () => context.push('/explore-discover'),
                  onSubmitted: (query) => context.push(
                    Uri(
                      path: '/explore-discover',
                      queryParameters: {'q': query},
                    ).toString(),
                  ),
                ),
              ),
            ),
            if (trips.isLoading && activeTrip == null && upcomingTrip == null)
              const SliverToBoxAdapter(child: _HomeLoading()),
            if (trips.hasError)
              SliverToBoxAdapter(
                child: _HomeError(
                  onRetry: () => ref.invalidate(userTripsStreamProvider),
                ),
              ),
            if (surface == HomeJourneySurface.active && activeTrip != null)
              SliverToBoxAdapter(child: HomeActiveCard(trip: activeTrip))
            else if (surface == HomeJourneySurface.upcoming &&
                upcomingTrip != null)
              SliverToBoxAdapter(child: HomeUpcomingCard(trip: upcomingTrip))
            else
              SliverToBoxAdapter(
                child: HomeStateIntro(
                  kicker: 'YOUR NEXT CHAPTER',
                  title: 'Know what to do next.',
                  body:
                      'Browse grounded destinations, save places you can return to, and start a plan when the moment is right.',
                  actionLabel: 'Start exploring',
                  onAction: () => context.push('/explore'),
                  image: 'assets/brand/india-cover-soft.png',
                ),
              ),
            SliverToBoxAdapter(
              child: HomeDestinationRail(destinations: destinations),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Plan a trip'),
                      avatar: const Icon(Icons.route_rounded),
                      onPressed: () => context.push('/trip-planner'),
                    ),
                    ActionChip(
                      label: const Text('Hidden gems'),
                      avatar: const Icon(Icons.landscape_outlined),
                      onPressed: () => context.push('/hidden-gems'),
                    ),
                    ActionChip(
                      label: const Text('Transit'),
                      avatar: const Icon(Icons.train_outlined),
                      onPressed: () => context.go('/transportation'),
                    ),
                  ],
                ),
              ),
            ),
            if (savedPlaces.isNotEmpty)
              SliverToBoxAdapter(
                child: HomeSavedPlacesRail(places: savedPlaces),
              ),
            if (surface == HomeJourneySurface.discovery && pastTrips.isNotEmpty)
              SliverToBoxAdapter(
                child: HomeArchiveCard(completedCount: pastTrips.length),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 64)),
          ],
        ),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.primaryAction,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Opening your journey ledger…',
            style: AppTypography.bodySmall(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  final VoidCallback onRetry;
  const _HomeError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Your journey data is temporarily unavailable.',
              style: AppTypography.bodySmall(color: tokens.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
