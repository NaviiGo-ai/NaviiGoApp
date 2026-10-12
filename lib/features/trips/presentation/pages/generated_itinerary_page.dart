import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/motion/nav_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/no_journey_state.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../places/domain/models/place_model.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../providers/trip_provider.dart';
import '../widgets/itinerary_overview_widgets.dart';

class GeneratedItineraryPage extends ConsumerStatefulWidget {
  final TripItineraryModel? trip;
  final bool fallbackToStoredTrip;

  const GeneratedItineraryPage({
    super.key,
    this.trip,
    this.fallbackToStoredTrip = false,
  });

  @override
  ConsumerState<GeneratedItineraryPage> createState() =>
      _GeneratedItineraryPageState();
}

class _GeneratedItineraryPageState
    extends ConsumerState<GeneratedItineraryPage> {
  // 0 = Chapters Overview, 1 = Day in Motion.
  int _viewMode = 0;
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider)?.uid;
    TripItineraryModel? activeTrip = widget.trip;

    // An explicit generation result is only renderable for the signed-in owner.
    // This guard deliberately stays in the presentation layer as a second line
    // of defence for ephemeral results arriving through navigation extras.
    if (activeTrip != null) {
      if (currentUid == null || activeTrip.userId != currentUid) {
        return _buildEmptyState(
          title: 'Itinerary Unavailable',
          message: 'This itinerary belongs to a different account.',
        );
      }
    } else if (widget.fallbackToStoredTrip) {
      final tripsAsync = ref.watch(userTripsStreamProvider);
      if (tripsAsync.isLoading) {
        return _buildLoadingState();
      }
      if (tripsAsync.hasError) {
        return _buildEmptyState(
          title: 'Itineraries Unavailable',
          message:
              'Your saved itinerary data is unavailable right now. Try again later.',
        );
      }

      activeTrip = ref.watch(activeTripProvider);
      if (activeTrip == null) {
        final allTrips = tripsAsync.value ?? const <TripItineraryModel>[];
        if (allTrips.isNotEmpty) activeTrip = allTrips.first;
      }
    }

    if (activeTrip == null) {
      return _buildEmptyState(
        title: 'No Itinerary Yet',
        message: widget.fallbackToStoredTrip
            ? 'Plan a journey to see the day details provided by your itinerary.'
            : 'The generated itinerary is no longer available on this screen.',
      );
    }
    if (activeTrip.dayPlans.isEmpty) {
      return _buildEmptyState(
        title: 'Itinerary Incomplete',
        message: 'This itinerary did not include usable day plans.',
      );
    }

    return _buildItineraryView(context, activeTrip);
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
      ),
      body: Semantics(
        container: true,
        liveRegion: true,
        label: 'Loading saved itineraries',
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
      ),
      body: Semantics(
        container: true,
        liveRegion: true,
        label: '$title. $message',
        child: NoJourneyState(title: title, message: message),
      ),
    );
  }

  Widget _buildItineraryView(BuildContext context, TripItineraryModel trip) {
    final dayPlans = trip.dayPlans;
    final selectedDayIndex = _clampSelectedDay(dayPlans.length);
    final currentDayPlan = dayPlans[selectedDayIndex];
    final activities = currentDayPlan.activities;
    final startDate = _displayDateInput(trip.form['startDate']);
    final group = _present(trip.form['group']);
    final heroMeta = [
      if (startDate != null) startDate.toUpperCase(),
      if (group != null) group.toUpperCase(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const NavHubLeading(iconColor: Colors.white),
            actions: trip.isEphemeral || !trip.isPublic
                ? null
                : [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withAlpha(102),
                        child: IconButton(
                          tooltip: 'Copy itinerary link',
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    'https://naviigo.com/itinerary/${trip.uuid}',
                              ),
                            );
                            NavHaptics.fire(NavHaptic.light);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Itinerary link copied: https://naviigo.com/itinerary/${trip.uuid}',
                                ),
                                backgroundColor: AppColors.teal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SafeExpeditionImage(
                    imagePath: trip.heroImage,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(115),
                          Colors.transparent,
                          AppColors.background.withAlpha(128),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.35, 0.78, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ITINERARY · ${trip.totalDays} DAYS',
                            style: AppTypography.micro(color: AppColors.brown)
                                .copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trip.destName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displayHero(
                            color: AppColors.brown,
                          ).copyWith(fontSize: 34, height: 1.1),
                        ),
                        if (heroMeta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            children: [
                              for (final item in heroMeta)
                                Text(
                                  item,
                                  style:
                                      AppTypography.micro(
                                        color: AppColors.textSecondary,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (trip.isEphemeral)
            SliverToBoxAdapter(
              child: Semantics(
                container: true,
                label: 'Generated preview. Save status unconfirmed.',
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Generated preview · save status unconfirmed',
                          style: AppTypography.caption(
                            color: AppColors.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: ItineraryViewSwitcher(
              selectedIndex: _viewMode,
              onSelect: (mode) => setState(() => _viewMode = mode),
            ),
          ),
          SliverToBoxAdapter(child: ItineraryStatsRow(trip: trip)),
          SliverToBoxAdapter(
            child: ExpeditionRouteMapCard(
              trip: trip,
              dayPlan: currentDayPlan,
              onTap: () => _openRouteMapSheet(context, trip, currentDayPlan),
            ),
          ),
          if (_viewMode == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'ITINERARY CHAPTERS',
                      style: AppTypography.eyebrow(color: AppColors.primary),
                    ),
                    Text(
                      '${dayPlans.length} DAYS IN ORDER PROVIDED',
                      style: AppTypography.micro(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, idx) {
                final dayPlan = dayPlans[idx];
                return ItineraryChapterCard(
                  index: idx,
                  totalCount: dayPlans.length,
                  dayPlan: dayPlan,
                  onExploreDay: () {
                    setState(() {
                      _selectedDayIndex = idx;
                      _viewMode = 1;
                    });
                  },
                );
              }, childCount: dayPlans.length),
            ),
          ],
          if (_viewMode == 1) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 12),
                child: DaySelectorRail(
                  totalDays: dayPlans.length,
                  dayPlans: dayPlans,
                  selectedIndex: selectedDayIndex,
                  onSelectDay: (idx) => setState(() => _selectedDayIndex = idx),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildDayContextCard(currentDayPlan)),
            if (activities.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyDayCard(currentDayPlan))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final activity = activities[idx];
                    final next = idx + 1 < activities.length
                        ? activities[idx + 1]
                        : null;
                    final transferSource = next == null
                        ? null
                        : _coherentTransferSource(activity, next);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActivityMotionCard(idx, activity),
                        if (transferSource != null)
                          _buildTransferStrip(transferSource),
                      ],
                    );
                  }, childCount: activities.length),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: trip.isEphemeral || trip.tripStatus.isTerminal
          ? null
          : _buildBottomActionBar(context, trip),
    );
  }

  int _clampSelectedDay(int count) {
    final clamped = _selectedDayIndex.clamp(0, count - 1).toInt();
    if (clamped != _selectedDayIndex) {
      // Keep the local view state valid when a refreshed itinerary has fewer
      // days. This is intentionally not persisted with the trip.
      _selectedDayIndex = clamped;
    }
    return clamped;
  }

  Widget _buildDayContextCard(TripDayPlanModel dayPlan) {
    final theme = _present(dayPlan.theme);
    final date = _present(dayPlan.dateFormatted);
    final area = _present(dayPlan.areaFocus);
    final weather = _present(dayPlan.weatherContext);
    final hasContext =
        theme != null || date != null || area != null || weather != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Semantics(
        container: true,
        label: _dayContextSemantics(dayPlan),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 10,
                runSpacing: 5,
                children: [
                  Text(
                    'DAY ${dayPlan.dayNumber} TIMELINE',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                  Text(
                    '${dayPlan.activities.length} ACTIVITIES',
                    style: AppTypography.micro(
                      color: AppColors.brown,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (theme != null) ...[
                const SizedBox(height: 6),
                Text(
                  theme,
                  style: AppTypography.tripTitle(
                    color: AppColors.brown,
                  ).copyWith(fontSize: 20, height: 1.25),
                ),
              ],
              if (hasContext) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (date != null) _contextChip('Date · $date'),
                    if (area != null) _contextChip('Area focus · $area'),
                    if (weather != null)
                      _contextChip(
                        'Itinerary-provided weather/context · $weather',
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'No additional day context was provided.',
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _contextChip(String text) {
    return Text(
      text,
      style: AppTypography.caption(color: AppColors.textSecondary),
    );
  }

  Widget _buildEmptyDayCard(TripDayPlanModel dayPlan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Semantics(
        container: true,
        liveRegion: true,
        label:
            'No activities were provided for day ${dayPlan.dayNumber}. The itinerary has no activity details for this day.',
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.event_note_outlined,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No activities were provided for day ${dayPlan.dayNumber}.',
                textAlign: TextAlign.center,
                style: AppTypography.tripTitle(color: AppColors.brown),
              ),
              const SizedBox(height: 6),
              Text(
                'This itinerary has no activity details for the selected day.',
                textAlign: TextAlign.center,
                style: AppTypography.caption(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityMotionCard(int index, TripActivityModel activity) {
    final category = _present(activity.category);
    final duration = _present(activity.duration);
    final time = _present(activity.time);
    final title = _activityTitle(activity);
    final categoryColor = _categoryColor(category);

    return Semantics(
      container: true,
      label: _activitySemantics(activity),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (time != null)
                  Text(
                    time,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.micro(
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w900, fontSize: 11),
                  )
                else
                  const SizedBox(height: 14),
                const SizedBox(height: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null || duration != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: AppTypography.micro(color: categoryColor)
                                  .copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        if (duration != null)
                          Text(
                            'Duration · $duration',
                            style: AppTypography.micro(
                              color: AppColors.textTertiary,
                            ).copyWith(fontSize: 10),
                          ),
                      ],
                    ),
                  if (category != null || duration != null)
                    const SizedBox(height: 6),
                  Text(
                    title ?? 'Activity details unavailable',
                    style: AppTypography.tripTitle(
                      color: title == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ).copyWith(fontSize: 16, height: 1.25),
                  ),
                  if (_present(activity.description) != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      _present(activity.description)!,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary,
                      ).copyWith(fontSize: 13, height: 1.4),
                    ),
                  ],
                  if (_present(activity.location) != null)
                    _buildActivityInfo(
                      Icons.place_outlined,
                      'Location',
                      _present(activity.location)!,
                    ),
                  if (_present(activity.estimatedCost) != null)
                    _buildActivityInfo(
                      Icons.payments_outlined,
                      'Itinerary-provided estimated cost',
                      _present(activity.estimatedCost)!,
                    ),
                  if (_present(activity.bookingRequirement) != null)
                    _buildActivityInfo(
                      Icons.info_outline,
                      'Booking advisory',
                      _present(activity.bookingRequirement)!,
                    ),
                  if (_present(activity.mealContext) != null)
                    _buildActivityInfo(
                      Icons.restaurant_outlined,
                      'Meal context',
                      _present(activity.mealContext)!,
                    ),
                  if (activity.isGenericDiningFallback)
                    _buildActivityInfo(
                      Icons.restaurant_menu_outlined,
                      'Dining note',
                      'Generic dining fallback supplied by itinerary',
                    ),
                  for (final warning in activity.warnings)
                    if (_present(warning) != null)
                      _buildActivityInfo(
                        Icons.warning_amber_outlined,
                        'Itinerary warning',
                        _present(warning)!,
                      ),
                  if (_present(activity.source) != null)
                    _buildActivityInfo(
                      Icons.source_outlined,
                      'Source',
                      _present(activity.source)!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label · $value',
              style: AppTypography.caption(
                color: AppColors.textSecondary,
              ).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  TripActivityModel? _coherentTransferSource(
    TripActivityModel current,
    TripActivityModel next,
  ) {
    if (_hasTransferEndpoints(current)) return current;
    if (_hasTransferEndpoints(next)) return next;
    return null;
  }

  bool _hasTransferEndpoints(TripActivityModel activity) {
    return _present(activity.transferOrigin) != null &&
        _present(activity.transferDestination) != null;
  }

  Widget _buildTransferStrip(TripActivityModel transfer) {
    final origin = _present(transfer.transferOrigin)!;
    final destination = _present(transfer.transferDestination)!;
    final mode = _present(transfer.transferMode);
    final details = [
      '$origin → $destination',
      if (mode != null) mode,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4, bottom: 12),
      child: Semantics(
        container: true,
        label: 'Itinerary-provided transfer: $details',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 2, height: 32, color: AppColors.borderStrong),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _transferIcon(mode),
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        details,
                        style:
                            AppTypography.micro(
                              color: AppColors.textSecondary,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _transferIcon(String? mode) {
    final normalized = mode?.toLowerCase() ?? '';
    if (normalized.contains('train') || normalized.contains('rail')) {
      return Icons.train_outlined;
    }
    if (normalized.contains('bus')) return Icons.directions_bus_outlined;
    if (normalized.contains('walk')) return Icons.directions_walk_outlined;
    if (normalized.contains('bike') || normalized.contains('cycle')) {
      return Icons.directions_bike_outlined;
    }
    if (normalized.contains('flight') || normalized.contains('air')) {
      return Icons.flight_outlined;
    }
    if (normalized.contains('car') || normalized.contains('taxi')) {
      return Icons.directions_car_outlined;
    }
    return Icons.directions_outlined;
  }

  Widget _buildBottomActionBar(BuildContext context, TripItineraryModel trip) {
    final liveButton = ElevatedButton.icon(
      onPressed: () {
        NavHaptics.fire(NavHaptic.strong);
        // The live screen owns permission, fix freshness, proximity, ownership,
        // and one-journey-at-a-time validation. This is only the handoff.
        context.push('/live-tracking', extra: trip);
      },
      icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
      label: const Text('START LIVE JOURNEY'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(width: double.infinity, child: liveButton),
      ),
    );
  }

  void _openRouteMapSheet(
    BuildContext context,
    TripItineraryModel trip,
    TripDayPlanModel currentDay,
  ) {
    final places = _coordinatePlaces(trip, currentDay);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.78;
        return Semantics(
          container: true,
          label: 'Coordinate-backed activity locations',
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVITY LOCATIONS',
                            style: AppTypography.eyebrow(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${trip.destName} · Day ${currentDay.dayNumber}',
                            style: AppTypography.sectionTitle(
                              color: AppColors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close activity locations',
                      child: IconButton(
                        tooltip: 'Close activity locations',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (places.isEmpty)
                  Expanded(
                    child: Center(
                      child: Semantics(
                        liveRegion: true,
                        label:
                            'Map unavailable because no activity coordinates were provided.',
                        child: Text(
                          'Map unavailable: no activity coordinates were provided.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'COORDINATES PROVIDED BY ITINERARY',
                    style: AppTypography.eyebrow(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: places.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.border, height: 16),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.brown,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: AppTypography.micro(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.name,
                                    style: AppTypography.bodyMedium(
                                      color: AppColors.textPrimary,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (_present(place.vicinity) != null)
                                    Text(
                                      place.vicinity,
                                      style: AppTypography.caption(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  Text(
                                    '${place.lat}, ${place.lng}',
                                    style: AppTypography.micro(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                context.push('/map', extra: place);
                              },
                              child: const Text('OPEN IN MAP'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<PlaceModel> _coordinatePlaces(
    TripItineraryModel trip,
    TripDayPlanModel day,
  ) {
    final places = <PlaceModel>[];
    for (var index = 0; index < day.activities.length; index++) {
      final activity = day.activities[index];
      if (!_hasCoordinates(activity.lat, activity.lng)) continue;
      places.add(
        PlaceModel(
          id: activity.placeId ?? '${trip.uuid}-day-${day.dayNumber}-$index',
          name: _activityTitle(activity) ?? 'Activity location',
          vicinity: _present(activity.location) ?? '',
          lat: activity.lat,
          lng: activity.lng,
        ),
      );
    }
    return places;
  }

  String _dayContextSemantics(TripDayPlanModel dayPlan) {
    final details = <String>['Day ${dayPlan.dayNumber} timeline'];
    final theme = _present(dayPlan.theme);
    final date = _present(dayPlan.dateFormatted);
    final area = _present(dayPlan.areaFocus);
    final weather = _present(dayPlan.weatherContext);
    if (theme != null) details.add(theme);
    if (date != null) details.add('Date $date');
    if (area != null) details.add('Area focus $area');
    if (weather != null) {
      details.add('Itinerary-provided weather/context $weather');
    }
    return details.join('. ');
  }

  String _activitySemantics(TripActivityModel activity) {
    final details = <String>[];
    final title = _activityTitle(activity);
    if (title != null) details.add(title);
    final time = _present(activity.time);
    final location = _present(activity.location);
    final category = _present(activity.category);
    if (time != null) details.add('Time $time');
    if (location != null) details.add('Location $location');
    if (category != null) details.add('Category $category');
    return details.isEmpty
        ? 'Activity details unavailable'
        : details.join('. ');
  }

  Color _categoryColor(String? category) {
    final normalized = category?.toLowerCase() ?? '';
    if (normalized.contains('spiritual') || normalized.contains('culture')) {
      return AppColors.teal;
    }
    if (normalized.contains('nature') || normalized.contains('outdoor')) {
      return const Color(0xFF2E7D32);
    }
    if (normalized.contains('dining') || normalized.contains('food')) {
      return const Color(0xFFD84315);
    }
    return AppColors.primary;
  }
}

String? _present(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _displayDateInput(Object? raw) {
  final value = _present(raw);
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String? _activityTitle(TripActivityModel activity) {
  final title = _present(activity.title);
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
