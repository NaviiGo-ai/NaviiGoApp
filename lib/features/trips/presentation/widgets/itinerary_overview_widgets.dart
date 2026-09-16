import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../../../core/motion/nav_haptics.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SAFE IMAGE HELPER (Asset & Network with graceful fallback)
/// ─────────────────────────────────────────────────────────────────────────────
class SafeExpeditionImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafeExpeditionImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return Image.network(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceWarm,
      child: const Center(
        child: Icon(Icons.terrain_rounded, color: AppColors.primary, size: 36),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// VERTICAL JOURNEY TRACK PAINTER
/// Continuous vertical brand spine connecting Day Chapters
/// ─────────────────────────────────────────────────────────────────────────────
class VerticalJourneyTrackPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color trackColor;
  final Color nodeColor;
  final double nodeCenterY;

  VerticalJourneyTrackPainter({
    this.isFirst = false,
    this.isLast = false,
    required this.trackColor,
    required this.nodeColor,
    this.nodeCenterY = 28.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Top track segment
    if (!isFirst) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, nodeCenterY),
        trackPaint,
      );
    }

    // Bottom track segment
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, nodeCenterY),
        Offset(centerX, size.height),
        trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VerticalJourneyTrackPainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.nodeCenterY != nodeCenterY;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// VIEW MODE SWITCHER (CHAPTERS OVERVIEW vs. DAY IN MOTION)
/// ─────────────────────────────────────────────────────────────────────────────
class ItineraryViewSwitcher extends StatelessWidget {
  final int selectedIndex; // 0 = Chapters Overview, 1 = Day In Motion
  final ValueChanged<int> onSelect;

  const ItineraryViewSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cream.withAlpha(120),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPill(
              title: 'CHAPTERS OVERVIEW',
              icon: Icons.menu_book_rounded,
              isSelected: selectedIndex == 0,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                onSelect(0);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildPill(
              title: 'DAY IN MOTION',
              icon: Icons.alt_route_rounded,
              isSelected: selectedIndex == 1,
              onTap: () {
                NavHaptics.fire(NavHaptic.light);
                onSelect(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brown : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style:
                  AppTypography.micro(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// TRIP MASTHEAD SUMMARY STATS
/// ─────────────────────────────────────────────────────────────────────────────
class ItineraryStatsRow extends StatelessWidget {
  final TripItineraryModel trip;

  const ItineraryStatsRow({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    int totalWaypoints = 0;
    for (final dp in trip.dayPlans) {
      totalWaypoints += dp.activities.length;
    }

    final budget = trip.form['budget'] ?? 18500;
    final budgetFormatted =
        '₹${budget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    final pace = trip.form['pace']?.toString() ?? 'Balanced Pace';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'DURATION',
            '${trip.totalDays} DAYS',
            Icons.calendar_today_outlined,
          ),
          _buildDivider(),
          _buildStatItem(
            'WAYPOINTS',
            '$totalWaypoints STOPS',
            Icons.pin_drop_outlined,
          ),
          _buildDivider(),
          _buildStatItem(
            'PACING',
            pace.toUpperCase().split(' ').first,
            Icons.speed_rounded,
          ),
          _buildDivider(),
          _buildStatItem(
            'ALLOCATION',
            budgetFormatted,
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.micro(color: AppColors.textTertiary)
                  .copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.caption(
            color: AppColors.brown,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: AppColors.border);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CHAPTER CARD ALONG THE JOURNEY LINE (SCREEN 5)
/// Alternating layout with distinctive personality per day
/// ─────────────────────────────────────────────────────────────────────────────
class ItineraryChapterCard extends StatelessWidget {
  final int index;
  final int totalCount;
  final TripDayPlanModel dayPlan;
  final VoidCallback onExploreDay;

  const ItineraryChapterCard({
    super.key,
    required this.index,
    required this.totalCount,
    required this.dayPlan,
    required this.onExploreDay,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    final isLast = index == totalCount - 1;
    final acts = dayPlan.activities;

    // Distinguish Day styles (alternating editorial aesthetics)
    final isAlternate = index % 2 == 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Vertical Journey Track Spine
          SizedBox(
            width: 48,
            child: CustomPaint(
              painter: VerticalJourneyTrackPainter(
                isFirst: isFirst,
                isLast: isLast,
                trackColor: AppColors.primary.withAlpha(100),
                nodeColor: AppColors.primary,
                nodeCenterY: 28.0,
              ),
              child: Align(
                alignment: const Alignment(0.0, -0.85),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAlternate ? AppColors.teal : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isAlternate ? AppColors.teal : AppColors.primary)
                                .withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '0${index + 1}',
                      style: AppTypography.micro(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right: The Chapter Story Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 20, bottom: 20),
              child: GestureDetector(
                onTap: onExploreDay,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFirst
                          ? AppColors.primary.withAlpha(120)
                          : AppColors.border,
                      width: isFirst ? 1.5 : 1.0,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Chapter Eyebrow & Waypoint Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isAlternate
                                  ? AppColors.teal.withAlpha(25)
                                  : AppColors.cream,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CHAPTER 0${index + 1} · ${acts.length} WAYPOINTS',
                              style:
                                  AppTypography.micro(
                                    color: isAlternate
                                        ? AppColors.teal
                                        : AppColors.brown,
                                  ).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                            ),
                          ),
                          Text(
                            dayPlan.dateFormatted ?? 'Day 0${index + 1}',
                            style: AppTypography.micro(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Chapter Headline in Epilogue
                      Text(
                        dayPlan.theme ?? 'Expedition Chapter',
                        style: AppTypography.tripTitle(
                          color: AppColors.brown,
                        ).copyWith(fontSize: 18, height: 1.25),
                      ),
                      const SizedBox(height: 10),

                      // Stop Highlights Sequence (Compact Chips)
                      if (acts.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: acts.take(3).map((a) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isAlternate
                                          ? AppColors.teal
                                          : AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      a.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.caption(
                                            color: AppColors.textPrimary,
                                          ).copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ),
                                  if (a.time != null)
                                    Text(
                                      a.time!,
                                      style: AppTypography.micro(
                                        color: AppColors.textTertiary,
                                      ).copyWith(fontSize: 10),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Bottom Interactive Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TIMELINE & ROUTE',
                            style:
                                AppTypography.micro(
                                  color: isAlternate
                                      ? AppColors.teal
                                      : AppColors.primary,
                                ).copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'EXPLORE DAY',
                                style: AppTypography.micro(
                                  color: AppColors.brown,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.brown,
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
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// INTER-CHAPTER TRANSIT / OVERNIGHT MOMENT
/// ─────────────────────────────────────────────────────────────────────────────
class InterChapterTransitNode extends StatelessWidget {
  final int index;

  const InterChapterTransitNode({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final isStay = index % 2 == 0;
    final label = isStay
        ? 'OVERNIGHT REST · HERITAGE STAY'
        : 'EVENING LEISURE & TRANSIT';
    final icon = isStay ? Icons.hotel_rounded : Icons.nightlife_rounded;

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cream.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.micro(
                    color: AppColors.brown,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ROUTE MAP SHORTCUT CARD
/// ─────────────────────────────────────────────────────────────────────────────
class ExpeditionRouteMapCard extends StatelessWidget {
  final TripItineraryModel trip;
  final VoidCallback onTap;

  const ExpeditionRouteMapCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brown,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FULL EXPEDITION ROUTE MAP',
                      style: AppTypography.micro(color: AppColors.yellow)
                          .copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Interactive Waypoints & Transfers',
                      style: AppTypography.caption(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${trip.totalDays} Days · Verified navigation paths',
                      style: AppTypography.micro(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// DAY SELECTOR PILL RAIL (FOR SCREEN 6)
/// ─────────────────────────────────────────────────────────────────────────────
class DaySelectorRail extends StatelessWidget {
  final int totalDays;
  final int selectedIndex;
  final ValueChanged<int> onSelectDay;

  const DaySelectorRail({
    super.key,
    required this.totalDays,
    required this.selectedIndex,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: totalDays,
        itemBuilder: (context, idx) {
          final isSelected = idx == selectedIndex;
          return GestureDetector(
            onTap: () {
              NavHaptics.fire(NavHaptic.light);
              onSelectDay(idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brown : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brown : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brown.withAlpha(40),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'DAY 0${idx + 1}',
                  style:
                      AppTypography.micro(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ).copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
