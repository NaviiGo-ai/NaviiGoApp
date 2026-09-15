import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/master_destinations.dart';

/// Image resolver for Atlas widgets
ImageProvider _resolveAtlasImage(String img) {
  if (img.startsWith('http')) return NetworkImage(img);
  if (img.startsWith('assets/')) return AssetImage(img);
  return const AssetImage('assets/brand/varanasi-dawn-hero.jpg');
}

/// ─────────────────────────────────────────────────────────
/// 1. LARGE EDITORIAL SEARCH: "WHERE NEXT?"
/// ─────────────────────────────────────────────────────────
class AtlasEditorialSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const AtlasEditorialSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MOBILE TRAVEL ATLAS · 2026',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.brown,
                  size: 22,
                ),
                tooltip: 'Saved places',
                visualDensity: VisualDensity.compact,
                onPressed: () => context.push('/saved-places'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'WHERE NEXT?',
            style: AppTypography.epilogue.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.06,
              letterSpacing: -1.2,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: 14),

          // Bespoke destination input surface (not a generic standard TextField)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brown.withAlpha(12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimary,
                    ).copyWith(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter destination, state, or curiosity...',
                      hintStyle: AppTypography.bodyMedium(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: onClear,
                    visualDensity: VisualDensity.compact,
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
/// 2. ONE CINEMATIC FEATURED DESTINATION
/// ─────────────────────────────────────────────────────────
class AtlasCinematicFeature extends StatelessWidget {
  final MasterDestination destination;

  const AtlasCinematicFeature({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
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
                'CINEMATIC DESTINATION',
                style: AppTypography.eyebrow(color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => context.push('/destination/${destination.id}'),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                image: DecorationImage(
                  image: _resolveAtlasImage(destination.image),
                  fit: BoxFit.cover,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.black.withAlpha(60),
                      AppColors.brown.withAlpha(220),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top tag row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            '${destination.state.toUpperCase()} · ${destination.category.toUpperCase()}',
                            style: AppTypography.micro(color: AppColors.brown)
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.yellow,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                destination.rating.toStringAsFixed(1),
                                style: AppTypography.micro(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom metadata & CTA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: AppTypography.epilogue.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.description,
                          style: AppTypography.plusJakartaSans.copyWith(
                            fontSize: 12,
                            color: AppColors.cream,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'EXPLORE DESTINATION →',
                                    style: AppTypography.plusJakartaSans
                                        .copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
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
/// 3. TRENDING: LARGE HORIZONTAL EDITORIAL CAROUSEL
/// ─────────────────────────────────────────────────────────
class AtlasTrendingCarousel extends StatelessWidget {
  final List<MasterDestination> destinations;

  const AtlasTrendingCarousel({super.key, required this.destinations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPEDITION TRENDS',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Trending Horizons',
                    style: AppTypography.epilogue.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brown,
                    ),
                  ),
                ],
              ),
              Text(
                'CURATED',
                style: AppTypography.micro(
                  color: AppColors.textTertiary,
                ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        // Large horizontal editorial cards
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () => context.push('/destination/${dest.id}'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown.withAlpha(16),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image: DecorationImage(
                        image: _resolveAtlasImage(dest.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(40),
                            Colors.black.withAlpha(210),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Rating
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
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

                          // Bottom text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dest.state.toUpperCase()} · ${dest.bestTime.toUpperCase()}',
                                style:
                                    AppTypography.micro(
                                      color: AppColors.cream,
                                    ).copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dest.name,
                                style: AppTypography.epilogue.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dest.description,
                                style: AppTypography.plusJakartaSans.copyWith(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
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
/// 4. HIDDEN GEMS: ALTERNATING VERTICAL IMAGE COMPOSITIONS
/// ─────────────────────────────────────────────────────────
class AtlasHiddenGemsComposition extends StatelessWidget {
  final List<MasterDestination> gems;

  const AtlasHiddenGemsComposition({super.key, required this.gems});

  @override
  Widget build(BuildContext context) {
    if (gems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                'OFF THE BEATEN TRACK',
                style: AppTypography.eyebrow(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hidden Corners',
            style: AppTypography.epilogue.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: 14),

          // Alternating vertical composition
          ...List.generate(gems.length.clamp(0, 3), (index) {
            final gem = gems[index];
            final isLeftImage = index % 2 == 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: InkWell(
                onTap: () => context.push('/destination/${gem.id}'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brown.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: isLeftImage
                        ? [
                            _buildGemImage(gem, 140),
                            Expanded(child: _buildGemNarrative(gem)),
                          ]
                        : [
                            Expanded(child: _buildGemNarrative(gem)),
                            _buildGemImage(gem, 140),
                          ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGemImage(MasterDestination gem, double width) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: _resolveAtlasImage(gem.image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildGemNarrative(MasterDestination gem) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${gem.category.toUpperCase()} · ${gem.state.toUpperCase()}',
            style: AppTypography.micro(
              color: AppColors.primary,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            gem.name,
            style: AppTypography.epilogue.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gem.description,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'View Waypoints →',
                style: AppTypography.plusJakartaSans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brown,
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
/// 5. TRAVEL JOURNAL: TEXT + PHOTOGRAPH
/// ─────────────────────────────────────────────────────────
class AtlasTravelJournalDispatch extends StatelessWidget {
  const AtlasTravelJournalDispatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
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
                'TRAVEL JOURNAL',
                style: AppTypography.eyebrow(color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dispatches from the Road',
            style: AppTypography.epilogue.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: 12),

          // Text + Photograph split block
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brown.withAlpha(10),
                  blurRadius: 12,
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
                    'assets/brand/kerala-backwaters.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KERALA BACKWATERS · DRIFTING AT TWILIGHT',
                        style: AppTypography.micro(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Where Water Meets the Sky',
                        style: AppTypography.epilogue.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“Drifting past twilight on the Vembanad Lake, the water reflects coconut palms etched against a burning violet sunset. Time slows to the rhythm of bamboo oars.”',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textPrimary,
                        ).copyWith(fontStyle: FontStyle.italic, height: 1.45),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NaviiGo Field Journal · 5 min read',
                            style: AppTypography.micro(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.push('/destination/kochi'),
                            child: Text(
                              'EXPLORE ROUTE →',
                              style: AppTypography.plusJakartaSans.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
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
