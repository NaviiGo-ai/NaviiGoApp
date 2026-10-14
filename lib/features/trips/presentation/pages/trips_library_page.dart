import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../providers/trip_provider.dart';

/// Saved journeys remain accessible before, during and after travel.
class TripsLibraryPage extends ConsumerWidget {
  const TripsLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    final trips = ref.watch(userTripsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const NavHubLeading(),
        title: const Text('Your journeys'),
        actions: [
          IconButton(
            tooltip: 'Plan a journey',
            onPressed: () => context.push('/trip-planner'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: trips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your saved journeys.'),
              TextButton(
                onPressed: () => ref.invalidate(userTripsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (records) {
          final owned =
              records
                  .where(
                    (trip) =>
                        uid != null && trip.userId == uid && !trip.isEphemeral,
                  )
                  .toList()
                ..sort(
                  (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
                    a.createdAt ?? DateTime(1970),
                  ),
                );
          if (owned.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text('Your next journey starts here.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/trip-planner'),
                    child: const Text('Plan a journey'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('All your saved itineraries, ready to open.'),
              const SizedBox(height: 16),
              for (final trip in owned)
                Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(trip.destName),
                    subtitle: Text(
                      '${_statusLabel(trip.tripStatus)} · ${trip.dayPlans.length} ${trip.dayPlans.length == 1 ? 'day' : 'days'}'
                      '${trip.form['startDate'] == null ? '' : '\n${trip.form['startDate']}'}',
                    ),
                    isThreeLine: trip.form['startDate'] != null,
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => context.push('/itinerary', extra: trip),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(TripStatus status) => switch (status) {
    TripStatus.draft => 'Draft',
    TripStatus.planned => 'Planned',
    TripStatus.upcoming => 'Upcoming',
    TripStatus.eligibleToStart => 'Ready to start',
    TripStatus.active => 'In progress',
    TripStatus.completed => 'Completed',
    TripStatus.cancelled => 'Cancelled',
  };
}
