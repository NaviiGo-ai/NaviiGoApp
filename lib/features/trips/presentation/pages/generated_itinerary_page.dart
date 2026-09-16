import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/firebase_client.dart';
import '../providers/trip_provider.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../widgets/itinerary_overview_widgets.dart';
import '../../../../core/widgets/no_journey_state.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../../core/motion/nav_haptics.dart';

class GeneratedItineraryPage extends ConsumerStatefulWidget {
  final TripItineraryModel? trip;

  const GeneratedItineraryPage({super.key, this.trip});

  @override
  ConsumerState<GeneratedItineraryPage> createState() =>
      _GeneratedItineraryPageState();
}

class _GeneratedItineraryPageState
    extends ConsumerState<GeneratedItineraryPage> {
  // 0 = CHAPTERS OVERVIEW (Screen 5), 1 = DAY IN MOTION (Screen 6)
  int _viewMode = 0;
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    TripItineraryModel? activeTrip = widget.trip;
    if (activeTrip == null) {
      activeTrip = ref.watch(activeTripProvider);
      if (activeTrip == null) {
        final allTrips = ref.watch(userTripsStreamProvider).value ?? [];
        if (allTrips.isNotEmpty) {
          activeTrip = allTrips.first;
        }
      }
    }

    // No trip means nothing to show — never invent an itinerary.
    if (activeTrip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: const NavHubLeading(),
        ),
        body: const NoJourneyState(
          title: 'No Itinerary Yet',
          message:
              'Craft a journey and NaviiGo will lay out every chapter, day by day.',
        ),
      );
    }

    return _buildItineraryView(context, activeTrip);
  }

  Widget _buildItineraryView(BuildContext context, TripItineraryModel trip) {
    final dayPlans = trip.dayPlans;
    final currentDayPlan =
        (dayPlans.isNotEmpty && _selectedDayIndex < dayPlans.length)
        ? dayPlans[_selectedDayIndex]
        : (dayPlans.isNotEmpty ? dayPlans.first : null);
    final activities = currentDayPlan?.activities ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Cinematic Hero Masthead Sliver
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const NavHubLeading(iconColor: Colors.white),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withAlpha((0.4 * 255).round()),
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: 'https://naviigo.com/itinerary/${trip.uuid}',
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
                          Colors.black.withAlpha((0.45 * 255).round()),
                          Colors.transparent,
                          AppColors.background.withAlpha((0.5 * 255).round()),
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '• EXPEDITION ITINERARY · ${trip.totalDays} DAYS',
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
                          style: AppTypography.displayHero(
                            color: AppColors.brown,
                          ).copyWith(fontSize: 34, height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${trip.startDateFormatted.toUpperCase()} · ${trip.form['group']?.toString().toUpperCase() ?? 'DUO EXPLORATION'}',
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
                  ),
                ],
              ),
            ),
          ),

          // 2. View Mode Switcher (CHAPTERS OVERVIEW vs. DAY IN MOTION)
          SliverToBoxAdapter(
            child: ItineraryViewSwitcher(
              selectedIndex: _viewMode,
              onSelect: (mode) => setState(() => _viewMode = mode),
            ),
          ),

          // 3. Stats Overview Row
          SliverToBoxAdapter(child: ItineraryStatsRow(trip: trip)),

          // 4. Route Map Shortcut Card
          SliverToBoxAdapter(
            child: ExpeditionRouteMapCard(
              trip: trip,
              onTap: () => _openRouteMapSheet(context, trip, currentDayPlan),
            ),
          ),

          // ─────────────────────────────────────────────────────────────────
          // SCREEN 5: CHAPTERS OVERVIEW (VERTICAL JOURNEY LINE)
          // ─────────────────────────────────────────────────────────────────
          if (_viewMode == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXPEDITION CHAPTERS',
                      style: AppTypography.eyebrow(color: AppColors.primary),
                    ),
                    Text(
                      '${trip.totalDays} DAYS SEQUENCE',
                      style: AppTypography.micro(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, idx) {
                final dp = dayPlans[idx];
                return Column(
                  children: [
                    ItineraryChapterCard(
                      index: idx,
                      totalCount: dayPlans.length,
                      dayPlan: dp,
                      onExploreDay: () {
                        NavHaptics.fire(NavHaptic.medium);
                        setState(() {
                          _selectedDayIndex = idx;
                          _viewMode = 1; // Switch into Day in Motion
                        });
                      },
                    ),
                    if (idx < dayPlans.length - 1)
                      InterChapterTransitNode(index: idx),
                  ],
                );
              }, childCount: dayPlans.length),
            ),
          ],

          // ─────────────────────────────────────────────────────────────────
          // SCREEN 6: DAY IN MOTION (TIMELINE WITH LANDMARK NODES & TRANSIT)
          // ─────────────────────────────────────────────────────────────────
          if (_viewMode == 1) ...[
            // Day Selector Rail
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 12),
                child: DaySelectorRail(
                  totalDays: dayPlans.length,
                  selectedIndex: _selectedDayIndex,
                  onSelectDay: (idx) => setState(() => _selectedDayIndex = idx),
                ),
              ),
            ),

            // Selected Day Theme Masthead
            if (currentDayPlan?.theme != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DAY 0${_selectedDayIndex + 1} TIMELINE',
                              style: AppTypography.eyebrow(
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${activities.length} STOPS',
                                style: AppTypography.micro(
                                  color: AppColors.brown,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentDayPlan!.theme!,
                          style: AppTypography.tripTitle(
                            color: AppColors.brown,
                          ).copyWith(fontSize: 20, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // The Day in Motion Timeline
            if (activities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
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
                          Icons.explore_outlined,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No activities scheduled for this day.',
                          style: AppTypography.tripTitle(
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Discover temples, ghats, and viewpoints in ${trip.destName} to add to this day.',
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/places',
                            extra: {'query': trip.destName},
                          ),
                          icon: const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'DISCOVER ${trip.destName.toUpperCase()} PLACES',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final act = activities[idx];
                    final isLast = idx == activities.length - 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActivityMotionCard(idx, act),
                        if (!isLast)
                          _buildTransferStrip(act, activities[idx + 1]),
                      ],
                    );
                  }, childCount: activities.length),
                ),
              ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // Sticky Bottom Action Bar
      bottomNavigationBar: Container(
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
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    NavHaptics.fire(NavHaptic.strong);
                    final uid = FirebaseClient.auth.currentUser?.uid;
                    if (uid != null) {
                      await ref
                          .read(tripRepositoryProvider)
                          .setActiveTrip(uid, trip.id);
                    }
                    if (context.mounted) {
                      context.push('/ongoing-trips');
                    }
                  },
                  icon: const Icon(
                    Icons.navigation_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('START LIVE JOURNEY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    NavHaptics.fire(NavHaptic.light);
                    context.push('/transportation');
                  },
                  icon: const Icon(
                    Icons.directions_transit_outlined,
                    size: 16,
                    color: AppColors.brown,
                  ),
                  label: Text(
                    'TRANSIT',
                    style: AppTypography.button(color: AppColors.brown),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.borderStrong,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityMotionCard(int index, TripActivityModel act) {
    final cat = act.category?.toLowerCase() ?? '';
    Color catColor = AppColors.primary;
    if (cat.contains('spiritual') || cat.contains('culture')) {
      catColor = AppColors.teal;
    } else if (cat.contains('nature') || cat.contains('outdoor')) {
      catColor = const Color(0xFF2E7D32);
    } else if (cat.contains('dining') || cat.contains('food')) {
      catColor = const Color(0xFFD84315);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Exact Time & Milestone Node
        SizedBox(
          width: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                act.time ?? '09:00 AM',
                style: AppTypography.micro(
                  color: AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w900, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withAlpha(90),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right Column: Rich Activity Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (act.category ?? 'EXPERIENCE').toUpperCase(),
                        style: AppTypography.micro(
                          color: catColor,
                        ).copyWith(fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          act.duration ?? '~1.5 HRS',
                          style: AppTypography.micro(
                            color: AppColors.textTertiary,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  act.title,
                  style: AppTypography.tripTitle(
                    color: AppColors.textPrimary,
                  ).copyWith(fontSize: 16, height: 1.25),
                ),
                if (act.description != null && act.description!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    act.description!,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 13, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferStrip(
    TripActivityModel current,
    TripActivityModel next,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4, bottom: 12),
      child: Row(
        children: [
          Container(width: 2, height: 32, color: AppColors.borderStrong),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '15 MIN · 3.2 KM · AUTO / CAB',
                  style: AppTypography.micro(
                    color: AppColors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRouteMapSheet(
    BuildContext context,
    TripItineraryModel trip,
    TripDayPlanModel? currentDay,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final acts = currentDay?.activities ?? [];

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY’S ROUTE MAP',
                        style: AppTypography.eyebrow(color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.destName} Waypoints',
                        style: AppTypography.sectionTitle(
                          color: AppColors.brown,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Visual Route Canvas
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  image: const DecorationImage(
                    image: AssetImage('assets/brand/india-cover-soft.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.brown.withAlpha(45),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pin_drop_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${acts.length} Stops along today’s Journey',
                            style: AppTypography.caption(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'WAYPOINTS IN SEQUENCE',
                style: AppTypography.eyebrow(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 8),
              if (acts.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pin_drop_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No waypoints added for today',
                          style: AppTypography.tripTitle(
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore verified places to populate this day.',
                          style: AppTypography.caption(),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push(
                              '/places',
                              extra: {'query': trip.destName},
                            );
                          },
                          icon: const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'DISCOVER ${trip.destName.toUpperCase()}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: acts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.border, height: 16),
                    itemBuilder: (context, i) {
                      final a = acts[i];
                      return Row(
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
                                '${i + 1}',
                                style: AppTypography.micro(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a.title,
                              style: AppTypography.bodyMedium(
                                color: AppColors.textPrimary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            a.time ?? '',
                            style: AppTypography.micro(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      NavHaptics.fire(NavHaptic.light);
                      Navigator.pop(context);
                      final firstStop = acts.first.title;
                      final target = '$firstStop, ${trip.destName}';
                      launchUrl(
                        Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(target)}',
                        ),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(
                      Icons.directions_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'NAVIGATE IN GOOGLE MAPS',
                      style: AppTypography.button(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
