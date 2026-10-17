import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookings/domain/models/saved_place_model.dart';
import '../../../dashboard/domain/models/destination_model.dart';
import '../../../explore/presentation/widgets/discovery_widgets.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';

class HomeStateIntro extends StatelessWidget {
  final String kicker;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final String? image;

  const HomeStateIntro({
    super.key,
    required this.kicker,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: AppTypography.eyebrow(color: tokens.primaryAction),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                DiscoveryImage(image: image, label: title, height: 220),
                Container(
                  width: double.infinity,
                  color: tokens.editorialBrown,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.editorialTitle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: AppTypography.bodySmall(
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: onAction,
                        child: Text(actionLabel),
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

class HomeUpcomingCard extends StatelessWidget {
  final TripItineraryModel trip;
  const HomeUpcomingCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    final start = trip.parsedStartDate;
    final countdown = start == null
        ? 'Dates to be confirmed'
        : _countdown(start);
    final readiness = trip.dayPlans.isNotEmpty
        ? 'Itinerary ready'
        : 'Planning details pending';
    return _HomePanel(
      title: 'YOUR NEXT JOURNEY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destName,
                      style: AppTypography.editorialTitle(
                        color: tokens.editorialBrown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trip.startDateFormatted,
                      style: AppTypography.bodyMedium(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 86,
                height: 86,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DiscoveryImage(
                    image: approvedDestinationImage(
                      destinationId: trip.destId,
                      image: null,
                    ),
                    label: trip.destName,
                    height: 86,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Fact(label: countdown, icon: Icons.schedule_rounded),
              const SizedBox(width: 14),
              _Fact(label: readiness, icon: Icons.route_rounded),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/itinerary', extra: trip),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open itinerary'),
          ),
        ],
      ),
    );
  }

  String _countdown(DateTime start) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final departure = DateTime(start.year, start.month, start.day);
    final days = departure.difference(day).inDays;
    if (days == 0) return 'Departs today';
    if (days == 1) return 'Departs tomorrow';
    return 'In $days days';
  }
}

class HomeActiveCard extends StatelessWidget {
  final TripItineraryModel trip;
  const HomeActiveCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    final nextActivities = trip.dayPlans
        .expand((day) => day.activities)
        .where((activity) => !activity.isCompleted)
        .toList();
    final next = nextActivities.isEmpty ? null : nextActivities.first;
    return _HomePanel(
      title: 'JOURNEY IN MOTION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.destName,
            style: AppTypography.editorialTitle(color: tokens.editorialBrown),
          ),
          const SizedBox(height: 8),
          if (next == null)
            Text(
              'Your live route is open in the ongoing-trip experience.',
              style: AppTypography.bodyMedium(color: tokens.textSecondary),
            )
          else ...[
            Text(
              'NEXT',
              style: AppTypography.eyebrow(color: tokens.accentEmphasis),
            ),
            const SizedBox(height: 4),
            Text(
              next.title,
              style: AppTypography.bodyLarge(color: tokens.textPrimary),
            ),
            if (next.time != null)
              Text(
                next.time!,
                style: AppTypography.caption(color: tokens.textSecondary),
              ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/ongoing-trips'),
            icon: const Icon(Icons.near_me_rounded),
            label: const Text('Open ongoing trip'),
          ),
        ],
      ),
    );
  }
}

class HomeDestinationRail extends StatelessWidget {
  final List<DestinationModel> destinations;
  const HomeDestinationRail({super.key, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    final items = destinations.isEmpty
        ? kMasterDestinations.take(6).map(DestinationModel.fromMaster).toList()
        : destinations.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISCOVER NEXT',
            style: AppTypography.eyebrow(color: tokens.primaryAction),
          ),
          const SizedBox(height: 4),
          Text(
            'Curated horizons',
            style: AppTypography.editorialTitle(
              color: tokens.editorialBrown,
            ).copyWith(fontSize: 24),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 210,
                  child: InkWell(
                    onTap: () => context.push('/destination/${item.id}'),
                    borderRadius: BorderRadius.circular(18),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DiscoveryImage(
                              image: approvedDestinationImage(
                                destinationId: item.id,
                                image: item.image,
                              ),
                              label: item.title,
                              height: 135,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              '${item.title} · ${item.subtitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(
                                color: tokens.textPrimary,
                              ),
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
      ),
    );
  }
}

class HomeSavedPlacesRail extends StatelessWidget {
  final List<SavedPlaceModel> places;
  const HomeSavedPlacesRail({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return _HomePanel(
      title: 'YOUR SAVED PLACES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...places
              .take(3)
              .map(
                (place) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark_rounded),
                  title: Text(place.name),
                  subtitle: place.location == null
                      ? null
                      : Text(place.location!),
                  onTap: () => context.push('/saved-places'),
                ),
              ),
          TextButton(
            onPressed: () => context.push('/saved-places'),
            child: Text(
              'Open Passport',
              style: TextStyle(color: tokens.primaryAction),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeArchiveCard extends StatelessWidget {
  final int completedCount;
  const HomeArchiveCard({super.key, required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return _HomePanel(
      title: 'YOUR TRAVEL ARCHIVE',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.auto_stories_outlined),
        title: const Text('Continue through Passport'),
        subtitle: Text(
          '$completedCount completed journey${completedCount == 1 ? '' : 's'} recorded',
        ),
        onTap: () => context.push('/digital-passport'),
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  final String title;
  final Widget child;
  const _HomePanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.eyebrow(color: tokens.textTertiary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Fact({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: tokens.accentEmphasis),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
