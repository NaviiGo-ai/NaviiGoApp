import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../bookings/presentation/providers/saved_places_provider.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../providers/home_discovery_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_discovery_widgets.dart';
import '../widgets/home_journal_widgets.dart';
import '../widgets/home_phase3_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ScrollController _scroll;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(
      initialScrollOffset: ref
          .read(homeDiscoveryProvider.notifier)
          .scrollOffset,
    );
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(homeDiscoveryProvider).entries.isEmpty) {
        unawaited(ref.read(homeDiscoveryProvider.notifier).loadNext());
      }
    });
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    ref.read(homeDiscoveryProvider.notifier).scrollOffset = _scroll.offset;
    final show = _scroll.offset > 1000;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
    final feed = ref.read(homeDiscoveryProvider);
    if (_scroll.position.extentAfter < 800 &&
        _scroll.position.userScrollDirection == ScrollDirection.reverse &&
        feed.error == null) {
      unawaited(ref.read(homeDiscoveryProvider.notifier).loadNext());
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    final surface = ref.watch(homeJourneySurfaceProvider);
    final trips = ref.watch(userTripsStreamProvider);
    final activeTrip = ref.watch(activeTripProvider);
    final upcomingTrips = ref.watch(upcomingTripsProvider);
    final upcomingTrip = upcomingTrips.isEmpty ? null : upcomingTrips.first;
    final pastTrips = ref.watch(pastTripsProvider);
    final savedPlaces = ref.watch(safeSavedPlacesProvider);
    final feed = ref.watch(homeDiscoveryProvider);
    final feedController = ref.read(homeDiscoveryProvider.notifier);
    ref.listen(currentUserProvider.select((user) => user?.uid), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scroll.hasClients) _scroll.jumpTo(0);
        unawaited(ref.read(homeDiscoveryProvider.notifier).loadNext());
      });
    });

    return ColoredBox(
      color: tokens.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RefreshIndicator.adaptive(
                onRefresh: () async {
                  ref.invalidate(userTripsStreamProvider);
                  await feedController.refresh();
                },
                child: CustomScrollView(
                  key: PageStorageKey(
                    'home-discovery-${ref.watch(currentUserProvider)?.uid ?? 'visitor'}',
                  ),
                  controller: _scroll,
                  cacheExtent: 320,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      floating: true,
                      snap: !MediaQuery.disableAnimationsOf(context),
                      toolbarHeight: 68,
                      titleSpacing: 0,
                      backgroundColor: tokens.background,
                      surfaceTintColor: Colors.transparent,
                      title: const HomeJournalHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                        child: SearchBar(
                          hintText: 'Where does your curiosity lead?',
                          leading: const Icon(Icons.search_rounded),
                          trailing: const [Icon(Icons.travel_explore_rounded)],
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
                    if (trips.isLoading &&
                        activeTrip == null &&
                        upcomingTrip == null)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Opening your journeys…'),
                        ),
                      ),
                    if (trips.hasError)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Your journey data is temporarily unavailable.',
                              ),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(userTripsStreamProvider),
                                child: const Text('Retry journeys'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (surface == HomeJourneySurface.active &&
                        activeTrip != null)
                      SliverToBoxAdapter(
                        child: HomeActiveCard(trip: activeTrip),
                      )
                    else if (surface == HomeJourneySurface.upcoming &&
                        upcomingTrip != null)
                      SliverToBoxAdapter(
                        child: HomeUpcomingCard(trip: upcomingTrip),
                      )
                    else
                      const SliverToBoxAdapter(child: HomeDiscoveryWelcome()),
                    const SliverToBoxAdapter(child: HomePilgrimageBanner()),
                    const SliverToBoxAdapter(child: HomeDiscoveryActions()),
                    if (savedPlaces.isNotEmpty)
                      SliverToBoxAdapter(
                        child: HomeSavedPlacesRail(places: savedPlaces),
                      ),
                    if (surface == HomeJourneySurface.discovery &&
                        pastTrips.isNotEmpty)
                      SliverToBoxAdapter(
                        child: HomeArchiveCard(
                          completedCount: pastTrips.length,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: HomeDiscoveryFilters(
                        selected: feed.category,
                        onChanged: (category) {
                          if (category == feed.category) return;
                          unawaited(feedController.refresh(category));
                          if (_scroll.hasClients) _scroll.jumpTo(0);
                        },
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => HomeDiscoveryCard(
                          key: ValueKey(feed.entries[index].id),
                          entry: feed.entries[index],
                        ),
                        childCount: feed.entries.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: HomeDiscoveryFooter(
                        state: feed,
                        onLoadMore: () => unawaited(feedController.loadNext()),
                        onSkip: () =>
                            unawaited(feedController.skipUnavailableCity()),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showBackToTop)
                Positioned(
                  bottom: 18,
                  right: 20,
                  child: FloatingActionButton.small(
                    heroTag: 'home-back-to-top',
                    tooltip: 'Back to top',
                    onPressed: () => _scroll.animateTo(
                      0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
