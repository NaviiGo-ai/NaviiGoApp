import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/dashboard_providers.dart';

class TopDestinationsList extends ConsumerWidget {
  const TopDestinationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsyncValue = ref.watch(topDestinationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURATED DESTINATIONS',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Places in Motion',
                    style: AppTypography.sectionTitle(color: AppColors.brown),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/explore-discover'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: AppTypography.button(
                          color: AppColors.primary,
                        ).copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 2),
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
        SizedBox(
          height: 250,
          child: destinationsAsyncValue.when(
            data: (destinations) {
              if (destinations.isEmpty) {
                return _buildEmptyState(context);
              }
              final curated = destinations.take(7).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                physics: const BouncingScrollPhysics(),
                itemCount: curated.length,
                itemBuilder: (context, index) {
                  final dest = curated[index];
                  // Asymmetric widths: first item is wider hero card (210dp), others (170dp)
                  final double cardWidth = index == 0 ? 210 : 170;

                  return GestureDetector(
                    onTap: () => context.push('/destination/${dest.id}'),
                    // Shared element (§3, signature moment 1) — same tag the
                    // details page flies into. See explore_discover_page.dart.
                    child: Hero(
                      tag: 'destination-${dest.id}',
                      child: Container(
                        width: cardWidth,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppColors.cardShadow,
                          image: DecorationImage(
                            image: NetworkImage(dest.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Cinematic warm gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(
                                      0xFF24323A,
                                    ).withAlpha((0.25 * 255).round()),
                                    const Color(
                                      0xFF191D20,
                                    ).withAlpha((0.85 * 255).round()),
                                  ],
                                  stops: const [0.4, 0.7, 1.0],
                                ),
                              ),
                            ),
                            // Category badge top left
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(
                                    (0.4 * 255).round(),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  dest.category.toUpperCase(),
                                  style:
                                      AppTypography.micro(
                                        color: Colors.white,
                                      ).copyWith(
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                            // Rating badge top right
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: AppColors.cardShadow,
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
                                        color: AppColors.textPrimary,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bottom Info
                            Positioned(
                              bottom: 14,
                              left: 14,
                              right: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    dest.title,
                                    style: AppTypography.tripTitle(
                                      color: Colors.white,
                                    ).copyWith(fontSize: 17, height: 1.15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: AppColors.cream,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          dest.subtitle,
                                          style: AppTypography.micro(
                                            color: AppColors.cream,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                    ),
                  );
                },
              );
            },
            loading: () => _buildLoadingSkeleton(),
            error: (err, _) => _buildEmptyState(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 4,
      itemBuilder: (_, index) => Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Destinations Loading', style: AppTypography.tripTitle()),
                const SizedBox(height: 2),
                Text(
                  'Connecting to Naviigo atlas...',
                  style: AppTypography.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
