import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/master_destinations.dart';
import '../widgets/atlas_widgets.dart';

class ExploreDiscoverPage extends StatefulWidget {
  const ExploreDiscoverPage({super.key});

  @override
  State<ExploreDiscoverPage> createState() => _ExploreDiscoverPageState();
}

class _ExploreDiscoverPageState extends State<ExploreDiscoverPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MasterDestination> get _filteredDestinations {
    if (_searchQuery.isEmpty) return kMasterDestinations;
    final clean = _searchQuery.toLowerCase().trim();
    return kMasterDestinations.where((dest) {
      return dest.name.toLowerCase().contains(clean) ||
          dest.state.toLowerCase().contains(clean) ||
          dest.category.toLowerCase().contains(clean) ||
          dest.description.toLowerCase().contains(clean);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDestinations;
    final isSearching = _searchQuery.isNotEmpty;

    // Curate distinct sections for Mobile Travel Atlas
    final cinematicFeature = kMasterDestinations.firstWhere(
      (d) => d.id == 'udaipur',
      orElse: () => kMasterDestinations.first,
    );

    final trending = kMasterDestinations
        .where(
          (d) => ['rishikesh', 'jaipur', 'varanasi', 'kochi'].contains(d.id),
        )
        .toList();
    final hiddenGems = kMasterDestinations
        .where((d) => ['haridwar', 'madurai', 'manali'].contains(d.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Large Editorial Search: "WHERE NEXT?"
            SliverToBoxAdapter(
              child: AtlasEditorialSearch(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),

            if (!isSearching) ...[
              // 2. Cinematic Featured Destination
              SliverToBoxAdapter(
                child: AtlasCinematicFeature(destination: cinematicFeature),
              ),

              // 3. TRENDING: Large Horizontal Editorial Carousel
              SliverToBoxAdapter(
                child: AtlasTrendingCarousel(destinations: trending),
              ),

              // 4. HIDDEN GEMS: Alternating Vertical Image Compositions
              SliverToBoxAdapter(
                child: AtlasHiddenGemsComposition(gems: hiddenGems),
              ),

              // 5. TRAVEL JOURNAL: Text + Photograph
              const SliverToBoxAdapter(child: AtlasTravelJournalDispatch()),
            ] else ...[
              // Search Results Feed
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Text(
                    '${filtered.length} Destined Waypoints Found',
                    style: AppTypography.sectionTitle(
                      color: AppColors.brown,
                    ).copyWith(fontSize: 18),
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 60,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.travel_explore_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No horizons match "$_searchQuery"',
                            style: AppTypography.tripTitle(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Search for "Varanasi", "Rajasthan", or "Himalayas"',
                            style: AppTypography.caption(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final dest = filtered[index];
                      return _buildSearchResultCard(context, dest);
                    }, childCount: filtered.length),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, MasterDestination dest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => context.push('/destination/${dest.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: 110,
                height: 100,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: dest.image.startsWith('assets/')
                        ? AssetImage(dest.image)
                        : (dest.image.startsWith('http')
                                  ? NetworkImage(dest.image)
                                  : const AssetImage(
                                      'assets/brand/varanasi-dawn-hero.jpg',
                                    ))
                              as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dest.category.toUpperCase(),
                            style: AppTypography.micro(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: AppColors.yellow,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                dest.rating.toStringAsFixed(1),
                                style: AppTypography.micro(
                                  color: AppColors.textPrimary,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dest.name,
                        style: AppTypography.epilogue.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown,
                        ),
                      ),
                      Text(
                        dest.state,
                        style: AppTypography.plusJakartaSans.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
