import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/home_journal_widgets.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';
import '../../../navigation/presentation/widgets/custom_drawer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Lifecycle state providers
    final activeTrip = ref.watch(activeTripProvider);
    final upcomingTrips = ref.watch(upcomingTripsProvider);
    final pastTrips = ref.watch(pastTripsProvider);

    // 2. Curated travel data
    final destinationsAsync = ref.watch(topDestinationsProvider);
    final articlesAsync = ref.watch(journalArticlesProvider);

    final destinations = destinationsAsync.valueOrNull ?? [];
    final articles = articlesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const CustomDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Minimalist Editorial Header
            const SliverToBoxAdapter(child: HomeJournalHeader()),

            // Asymmetric Editorial Masthead
            SliverToBoxAdapter(
              child: HomeEditorialMasthead(
                activeTrip: activeTrip,
                upcomingTrip: upcomingTrips.isNotEmpty
                    ? upcomingTrips.first
                    : null,
                pastTrip: pastTrips.isNotEmpty ? pastTrips.first : null,
              ),
            ),

            // Dominant Photographic Moment (Bleeds off right edge)
            SliverToBoxAdapter(
              child: HomeDominantTravelVisual(
                activeTrip: activeTrip,
                upcomingTrip: upcomingTrips.isNotEmpty
                    ? upcomingTrips.first
                    : null,
                pastTrip: pastTrips.isNotEmpty ? pastTrips.first : null,
              ),
            ),

            // Active or Upcoming Journey Secondary Strip (if trip exists)
            if (activeTrip != null || upcomingTrips.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildTripProgressStrip(
                  context,
                  activeTrip ?? upcomingTrips.first,
                  isLive: activeTrip != null,
                ),
              ),

            // Exploration Section: Typography pills & alternating editorial aspect frames
            SliverToBoxAdapter(
              child: HomeEditorialExplorationRail(destinations: destinations),
            ),

            // Single Curated Travel Journal Moment
            SliverToBoxAdapter(
              child: HomeFeaturedJournalMoment(
                article: articles.isNotEmpty ? articles.first : null,
              ),
            ),

            // Quiet Editorial Footer
            const SliverToBoxAdapter(child: HomeJournalFooter()),
          ],
        ),
      ),
    );
  }

  /// Compact, tactile strip connecting to active or scheduled journey route
  Widget _buildTripProgressStrip(
    BuildContext context,
    TripItineraryModel trip, {
    required bool isLive,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: InkWell(
        onTap: () {
          if (isLive) {
            context.push('/ongoing-trips');
          } else {
            context.push('/itinerary', extra: trip);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLive ? AppColors.teal.withAlpha(120) : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.teal.withAlpha(30)
                      : AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLive ? Icons.near_me_rounded : Icons.route_rounded,
                  size: 18,
                  color: isLive ? AppColors.teal : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive
                          ? 'ACTIVE ROUTE IN PROGRESS'
                          : 'SCHEDULED ITINERARY',
                      style: AppTypography.micro(
                        color: isLive ? AppColors.teal : AppColors.textTertiary,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${trip.destName} · ${trip.totalDays} Days',
                      style: AppTypography.plusJakartaSans.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
