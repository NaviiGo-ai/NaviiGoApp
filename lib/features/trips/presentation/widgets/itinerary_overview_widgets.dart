import 'package:flutter/material.dart';

import '../../../../core/motion/nav_haptics.dart';
import '../../../../core/motion/nav_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/trip_itinerary_model.dart';

/// Asset and network images fail closed to a quiet, useful placeholder.
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
    if (imagePath.trim().isEmpty) return _buildFallback();
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

/// Continuous vertical brand spine connecting the itinerary chapters.
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

    if (!isFirst) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, nodeCenterY),
        trackPaint,
      );
    }
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
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.nodeCenterY != nodeCenterY;
  }
}

/// Switches between the two read-only itinerary views.
class ItineraryViewSwitcher extends StatelessWidget {
  final int selectedIndex;
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
              context,
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
              context,
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

  Widget _buildPill(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final child = AnimatedContainer(
      duration: NavReduce.duration(context, NavMotion.fast),
      curve: NavMotion.response,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 150;
          final text = Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style:
                AppTypography.micro(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          );
          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(height: 3),
                text,
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(child: text),
            ],
          );
        },
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title${isSelected ? ', selected' : ''}',
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Truthful summary values from the itinerary and its input form.
class ItineraryStatsRow extends StatelessWidget {
  final TripItineraryModel trip;

  const ItineraryStatsRow({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final totalActivities = trip.dayPlans.fold<int>(
      0,
      (total, day) => total + day.activities.length,
    );
    final statItems = <({String label, String value, IconData icon})>[];
    if (trip.dayPlans.isNotEmpty || _hasValue(trip.form['days'])) {
      statItems.add((
        label: 'DURATION',
        value: '${trip.totalDays} DAYS',
        icon: Icons.calendar_today_outlined,
      ));
    }
    statItems.add((
      label: 'ACTIVITIES',
      value: '$totalActivities',
      icon: Icons.event_note_outlined,
    ));

    final pace = _value(trip.form['pace']);
    if (pace != null) {
      statItems.add((
        label: 'PACE INPUT',
        value: pace.toUpperCase(),
        icon: Icons.speed_rounded,
      ));
    }

    final budget = _budgetValue(trip.form['budget']);
    if (budget != null) {
      statItems.add((
        label: 'INPUT BUDGET',
        value: budget,
        icon: Icons.account_balance_wallet_outlined,
      ));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 16,
        runSpacing: 10,
        children: [
          for (final stat in statItems)
            _buildStatItem(stat.label, stat.value, stat.icon),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 62, maxWidth: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.micro(color: AppColors.textTertiary)
                      .copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption(
              color: AppColors.brown,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// One chapter in the backend-provided day order.
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
    final isAlternate = index.isOdd;
    final date = _value(dayPlan.dateFormatted);
    final theme = _value(dayPlan.theme);
    final area = _value(dayPlan.areaFocus);
    final activities = dayPlan.activities;
    final dayLabel = 'Day ${dayPlan.dayNumber}';

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 48,
          child: CustomPaint(
            painter: VerticalJourneyTrackPainter(
              isFirst: isFirst,
              isLast: isLast,
              trackColor: AppColors.primary.withAlpha(100),
              nodeColor: AppColors.primary,
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
                ),
                child: Center(
                  child: Text(
                    '${dayPlan.dayNumber}',
                    style: AppTypography.micro(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 20, bottom: 20),
            child: Semantics(
              button: true,
              label: '$dayLabel, ${activities.length} activities',
              hint: 'Explore this day in the itinerary',
              child: InkWell(
                onTap: () {
                  NavHaptics.fire(NavHaptic.medium);
                  onExploreDay();
                },
                borderRadius: BorderRadius.circular(20),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 5,
                        children: [
                          _chapterBadge(
                            dayLabel,
                            '$dayLabel · ${activities.length} ACTIVITIES',
                            isAlternate,
                          ),
                          if (date != null)
                            Text(
                              date,
                              style: AppTypography.micro(
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                      if (theme != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          theme,
                          style: AppTypography.tripTitle(
                            color: AppColors.brown,
                          ).copyWith(fontSize: 18, height: 1.25),
                        ),
                      ],
                      if (area != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Area focus · $area',
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (theme == null && area == null && activities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'No day details were provided.',
                            style: AppTypography.caption(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (activities.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: activities.take(3).map((activity) {
                            final title = _activityTitle(activity);
                            final time = _value(activity.time);
                            if (title == null && time == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isAlternate
                                            ? AppColors.teal
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (title != null)
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 2,
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
                                  if (time != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      time,
                                      style: AppTypography.micro(
                                        color: AppColors.textTertiary,
                                      ).copyWith(fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'VIEW DAY DETAILS',
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
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.brown,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chapterBadge(String dayLabel, String text, bool alternate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: alternate ? AppColors.teal.withAlpha(25) : AppColors.cream,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTypography.micro(
          color: alternate ? AppColors.teal : AppColors.brown,
        ).copyWith(fontWeight: FontWeight.w800, fontSize: 9),
      ),
    );
  }
}

/// A map handoff is offered only when at least one activity has coordinates.
class ExpeditionRouteMapCard extends StatelessWidget {
  final TripItineraryModel trip;
  final TripDayPlanModel? dayPlan;
  final VoidCallback onTap;

  const ExpeditionRouteMapCard({
    super.key,
    required this.trip,
    this.dayPlan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activities = dayPlan == null
        ? trip.dayPlans.expand((day) => day.activities)
        : dayPlan!.activities;
    final coordinateCount = activities
        .where((activity) => _hasCoordinates(activity.lat, activity.lng))
        .length;
    final available = coordinateCount > 0;
    final label = available
        ? 'Open coordinate-backed activity locations'
        : 'Activity map unavailable: no itinerary coordinates were provided';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Semantics(
        button: available,
        enabled: available,
        label: label,
        child: InkWell(
          onTap: available ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: available ? AppColors.brown : AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(18),
              border: available ? null : Border.all(color: AppColors.border),
              boxShadow: available ? AppColors.cardShadow : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: available ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    available
                        ? Icons.map_outlined
                        : Icons.location_off_outlined,
                    color: available ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        available
                            ? 'ACTIVITY LOCATIONS'
                            : 'ACTIVITY MAP UNAVAILABLE',
                        style:
                            AppTypography.micro(
                              color: available
                                  ? AppColors.yellow
                                  : AppColors.textSecondary,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        available
                            ? 'Coordinate-backed map handoff'
                            : 'This itinerary has no activity coordinates',
                        style: AppTypography.caption(
                          color: available
                              ? Colors.white
                              : AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        available
                            ? '$coordinateCount activities with coordinates'
                            : 'A full route map cannot be shown safely',
                        style: AppTypography.micro(
                          color: available
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (available)
                  const Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable, focusable day controls.
class DaySelectorRail extends StatelessWidget {
  final int totalDays;
  final int selectedIndex;
  final ValueChanged<int> onSelectDay;
  final List<TripDayPlanModel>? dayPlans;

  const DaySelectorRail({
    super.key,
    required this.totalDays,
    required this.selectedIndex,
    required this.onSelectDay,
    this.dayPlans,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: totalDays,
        itemBuilder: (context, idx) {
          final isSelected = idx == selectedIndex;
          final dayNumber = dayPlans != null && idx < dayPlans!.length
              ? dayPlans![idx].dayNumber
              : idx + 1;
          final label = 'Day $dayNumber';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '$label${isSelected ? ', selected' : ''}',
              child: TextButton(
                onPressed: () {
                  NavHaptics.fire(NavHaptic.light);
                  onSelectDay(idx);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 48),
                  backgroundColor: isSelected
                      ? AppColors.brown
                      : AppColors.surface,
                  foregroundColor: isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                  side: BorderSide(
                    color: isSelected ? AppColors.brown : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: NavReduce.duration(context, NavMotion.fast),
                  curve: NavMotion.response,
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
                  child: Text(label),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String? _value(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _hasValue(Object? value) => _value(value) != null;

String? _budgetValue(Object? rawBudget) {
  final value = _value(rawBudget);
  if (value == null) return null;
  final numeric = rawBudget is num
      ? rawBudget.toDouble()
      : double.tryParse(value.replaceAll(',', ''));
  if (numeric != null && numeric.isFinite && numeric > 0) {
    final formatted = numeric.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '₹$formatted';
  }
  return value;
}

String? _activityTitle(TripActivityModel activity) {
  final title = _value(activity.title);
  if (title == null || title.toLowerCase() == 'activity') return null;
  return title;
}

bool _hasCoordinates(double? lat, double? lng) {
  return lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180;
}
