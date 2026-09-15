import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/destination_model.dart';
import '../../domain/models/journal_article_model.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';

/// ─────────────────────────────────────────────────────────
/// 1. MINIMALIST EDITORIAL HEADER
/// ─────────────────────────────────────────────────────────
class HomeJournalHeader extends ConsumerWidget {
  const HomeJournalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileStreamProvider);
    final String initial =
        (userAsync.valueOrNull?.displayName?.isNotEmpty ?? false)
        ? userAsync.valueOrNull!.displayName![0].toUpperCase()
        : 'N';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Brand mark + Editorial wordmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/naviigo-mark-primary.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 26),
              ),
              const SizedBox(width: 8),
              Text(
                'NAVIIGO',
                style: AppTypography.epilogue.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  color: AppColors.brown,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'JOURNAL',
                  style: AppTypography.plusJakartaSans.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.brown,
                  ),
                ),
              ),
            ],
          ),

          // Right: Action controls (Search, Saved, Profile avatar)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Search destinations',
                visualDensity: VisualDensity.compact,
                onPressed: () => context.push('/explore-discover'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Saved places',
                visualDensity: VisualDensity.compact,
                onPressed: () => context.push('/saved-places'),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: AppTypography.plusJakartaSans.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 2. ASYMMETRIC EDITORIAL MASTHEAD
/// ─────────────────────────────────────────────────────────
class HomeEditorialMasthead extends StatelessWidget {
  final TripItineraryModel? activeTrip;
  final TripItineraryModel? upcomingTrip;
  final TripItineraryModel? pastTrip;

  const HomeEditorialMasthead({
    super.key,
    this.activeTrip,
    this.upcomingTrip,
    this.pastTrip,
  });

  @override
  Widget build(BuildContext context) {
    String kicker = 'ISSUE N° 04 · DISCOVERY';
    String headline = 'WHERE ARE\nYOU HEADED\nNEXT?';

    if (activeTrip != null) {
      kicker = 'LIVE ONGOING EXPEDITION';
      headline = 'DAY 01 IN\n${activeTrip!.destName.toUpperCase()}';
    } else if (upcomingTrip != null) {
      final start = upcomingTrip!.parsedStartDate;
      final days = start != null ? start.difference(DateTime.now()).inDays : 0;
      kicker = days <= 0 ? 'DEPARTING TODAY' : 'DEPARTURE IN $days DAYS';
      headline = '${upcomingTrip!.destName.toUpperCase()}\nAWAITS YOU';
    } else if (pastTrip != null) {
      kicker = 'TRAVEL ARCHIVE';
      headline = 'MEMORIES OF\n${pastTrip!.destName.toUpperCase()}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kicker,
                style: AppTypography.eyebrow(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: AppTypography.epilogue.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.06,
              letterSpacing: -1.2,
              color: AppColors.brown,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 3. DOMINANT TRAVEL IMAGE (INTERACTS WITH VIEWPORT EDGE)
/// ─────────────────────────────────────────────────────────
class HomeDominantTravelVisual extends StatelessWidget {
  final TripItineraryModel? activeTrip;
  final TripItineraryModel? upcomingTrip;
  final TripItineraryModel? pastTrip;

  const HomeDominantTravelVisual({
    super.key,
    this.activeTrip,
    this.upcomingTrip,
    this.pastTrip,
  });

  @override
  Widget build(BuildContext context) {
    // Determine image, title, subline, and CTA based on lifecycle state
    String metaKicker = '25.3176° N · EXPEDITION 01';
    String metaTitle = 'Varanasi Ghats at Dawn';
    String ctaLabel = 'PLAN A JOURNEY →';
    VoidCallback onCtaTap = () => context.push('/trip-planner');
    String? networkImage;

    if (activeTrip != null) {
      metaKicker = 'ACTIVE COMPANION · DAY 01';
      metaTitle = activeTrip!.destName;
      ctaLabel = 'OPEN LIVE COMPANION →';
      onCtaTap = () => context.push('/ongoing-trips');
      networkImage = activeTrip!.heroImage.isNotEmpty
          ? activeTrip!.heroImage
          : null;
    } else if (upcomingTrip != null) {
      metaKicker = '${upcomingTrip!.totalDays} DAYS SCHEDULED';
      metaTitle = upcomingTrip!.destName;
      ctaLabel = 'VIEW ITINERARY ROUTE →';
      onCtaTap = () => context.push('/itinerary', extra: upcomingTrip);
      networkImage = upcomingTrip!.heroImage.isNotEmpty
          ? upcomingTrip!.heroImage
          : null;
    } else if (pastTrip != null) {
      metaKicker = 'COMPLETED EXPEDITION';
      metaTitle = pastTrip!.destName;
      ctaLabel = 'VIEW PASSPORT RECORD →';
      onCtaTap = () => context.push('/digital-passport');
      networkImage = pastTrip!.heroImage.isNotEmpty
          ? pastTrip!.heroImage
          : null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dominant visual: Begins offset from left (~44px) and bleeds off the right edge (0px)
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: Container(
              height: 290,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(28),
                    blurRadius: 24,
                    offset: const Offset(-4, 10),
                  ),
                ],
                image: DecorationImage(
                  image:
                      (networkImage != null && networkImage.startsWith('http'))
                      ? NetworkImage(networkImage)
                      : ((networkImage != null &&
                                networkImage.startsWith('assets/'))
                            ? AssetImage(networkImage)
                            : const AssetImage(
                                'assets/brand/varanasi-dawn-hero.jpg',
                              )),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.black.withAlpha(25),
                      Colors.black.withAlpha(70),
                      AppColors.brown.withAlpha(225),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(22, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top tag inside visual
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(225),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metaKicker,
                        style: AppTypography.plusJakartaSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.brown,
                        ),
                      ),
                    ),

                    // Bottom metadata inside visual
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metaTitle,
                          style: AppTypography.epilogue.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Handcrafted trail through authentic landmarks',
                          style: AppTypography.plusJakartaSans.copyWith(
                            fontSize: 12,
                            color: AppColors.cream,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action Button
                        InkWell(
                          onTap: onCtaTap,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(90),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctaLabel,
                                  style: AppTypography.plusJakartaSans.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Asymmetric left spine accent
          Positioned(
            left: 14,
            top: 40,
            bottom: 40,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'NAVIIGO EXPEDITIONS',
                style: AppTypography.plusJakartaSans.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 4. EDITORIAL EXPLORATION RAIL (NOT GENERIC CARDS)
/// ─────────────────────────────────────────────────────────
class HomeEditorialExplorationRail extends StatefulWidget {
  final List<DestinationModel> destinations;

  const HomeEditorialExplorationRail({super.key, required this.destinations});

  @override
  State<HomeEditorialExplorationRail> createState() =>
      _HomeEditorialExplorationRailState();
}

class _HomeEditorialExplorationRailState
    extends State<HomeEditorialExplorationRail> {
  int _selectedCategoryIndex = 0;

  static const List<String> _categories = [
    'All Chapters',
    'Sacred Ghats',
    'High Passes',
    'Desert Fortresses',
    'Coastal Ports',
  ];

  @override
  Widget build(BuildContext context) {
    final displayDestinations = widget.destinations.isNotEmpty
        ? widget.destinations
        : [
            const DestinationModel(
              id: 'varanasi',
              title: 'Varanasi',
              subtitle: 'Uttar Pradesh',
              image: '',
              rating: 4.9,
              category: 'Spiritual',
            ),
            const DestinationModel(
              id: 'jaipur',
              title: 'Jaipur',
              subtitle: 'Rajasthan',
              image: '',
              rating: 4.8,
              category: 'Heritage',
            ),
            const DestinationModel(
              id: 'rishikesh',
              title: 'Rishikesh',
              subtitle: 'Uttarakhand',
              image: '',
              rating: 4.8,
              category: 'Adventure',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPLORE',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Curated Horizons',
                    style: AppTypography.epilogue.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brown,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/explore-discover'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Full Atlas',
                        style: AppTypography.plusJakartaSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Restrained Typography Chips (No 5 generic colored square buttons)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_categories.length, (index) {
              final isSelected = _selectedCategoryIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brown : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.brown : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _categories[index],
                      style: AppTypography.plusJakartaSans.copyWith(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),

        // Editorial Horizontal Composition: Alternating rhythm (wide vs portrait frames)
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: displayDestinations.length,
            itemBuilder: (context, index) {
              final dest = displayDestinations[index];
              final isEven = index % 2 == 0;
              final width = isEven ? 240.0 : 180.0;

              return Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: InkWell(
                  onTap: () => context.push('/destination/${dest.id}'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image with error fallback to branded asset
                        dest.image.startsWith('http')
                            ? Image.network(
                                dest.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/brand/jaipur-heritage.jpg',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                dest.image.startsWith('assets/')
                                    ? dest.image
                                    : 'assets/brand/jaipur-heritage.jpg',
                                fit: BoxFit.cover,
                              ),

                        // Gradient protection
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.45, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(40),
                                Colors.black.withAlpha(200),
                              ],
                            ),
                          ),
                        ),

                        // Top rating chip
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: AppColors.yellow,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  dest.rating.toStringAsFixed(1),
                                  style: AppTypography.micro(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom destination metadata
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dest.category.toUpperCase(),
                                style:
                                    AppTypography.micro(
                                      color: AppColors.cream,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dest.title,
                                style: AppTypography.epilogue.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                dest.subtitle,
                                style: AppTypography.plusJakartaSans.copyWith(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 5. SINGLE FEATURE STORY / DESTINATION MOMENT
/// ─────────────────────────────────────────────────────────
class HomeFeaturedJournalMoment extends StatelessWidget {
  final JournalArticleModel? article;

  const HomeFeaturedJournalMoment({super.key, this.article});

  void _showReadingSheet(BuildContext context, JournalArticleModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                  children: [
                    Text(
                      item.tag.toUpperCase(),
                      style: AppTypography.eyebrow(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: AppTypography.epilogue.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brown,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.author} · ${item.readTime}',
                      style: AppTypography.caption(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.asset(
                          'assets/brand/varanasi-dawn-hero.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.content.isNotEmpty
                          ? item.content
                          : 'As twilight breaks over the Ganga, wooden rowboats drift silently across the morning mist. The ancient bells of Kashi chime in rhythm with Vedic chants that have echoed here for millennia. Walking the ghats at sunrise reveals silk weavers, stone carvers, and yogis in quiet contemplation.',
                      style: AppTypography.bodyLarge(
                        color: AppColors.textPrimary,
                      ).copyWith(height: 1.7),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brown,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Close Dispatch'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item =
        article ??
        const JournalArticleModel(
          id: 'varanasi-dawn',
          title: 'Dawn on the Sacred Ghats of Varanasi',
          subtitle:
              'Twilight chants and drifting wooden boats along the sacred Ganga',
          image: '',
          tag: 'CULTURE & TRADITION',
          author: 'Editorial Desk',
          readTime: '4 min read',
          content:
              'As twilight breaks over the Ganga, wooden rowboats drift across the morning mist. The bells of Kashi Vishwanath chime in rhythm with ancient Vedic prayers.',
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FEATURE STORY',
                style: AppTypography.eyebrow(color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dispatch Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brown.withAlpha(10),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    'assets/brand/varanasi-dawn-hero.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.tag.toUpperCase(),
                            style: AppTypography.micro(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.readTime,
                            style: AppTypography.micro(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: AppTypography.epilogue.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.content.isNotEmpty
                            ? item.content
                            : 'As twilight breaks over the Ganga, wooden rowboats drift across the mist. Ancient chants echo from the steps of Dashashwamedh.',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondary,
                        ).copyWith(height: 1.45),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => _showReadingSheet(context, item),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'READ DISPATCH →',
                                style: AppTypography.plusJakartaSans.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 6. SUBTLE FOOTER NOTE
/// ─────────────────────────────────────────────────────────
class HomeJournalFooter extends StatelessWidget {
  const HomeJournalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Center(
        child: Column(
          children: [
            Container(width: 32, height: 2, color: AppColors.cream),
            const SizedBox(height: 12),
            Text(
              'NaviiGo · Travelled with Intention · 2026',
              style: AppTypography.micro(
                color: AppColors.textTertiary,
              ).copyWith(letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
