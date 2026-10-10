import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/trips/presentation/providers/trip_provider.dart';
import 'adaptive_experience_controller.dart';
import 'adaptive_experience_profile.dart';
import 'adaptive_experience_state.dart';

final adaptiveExperienceControllerProvider =
    Provider<AdaptiveExperienceController>((ref) {
      return const AdaptiveExperienceController();
    });

/// App-level lifecycle from the existing trip sources, in priority order.
/// No canonical recent-completion context exists yet; historical trips alone
/// must not select postTrip, so the fallback is discover.
final adaptiveJourneyLifecycleProvider = Provider<AdaptiveJourneyLifecycle>((
  ref,
) {
  if (ref.watch(activeTripProvider) != null) {
    return AdaptiveJourneyLifecycle.activeTrip;
  }
  if (ref.watch(upcomingTripsProvider).isNotEmpty) {
    return AdaptiveJourneyLifecycle.upcoming;
  }
  return AdaptiveJourneyLifecycle.discover;
});

/// Family provider keeps the resolver centralized while allowing the
/// composition root to supply stable profile/lifecycle/context boundaries.
final adaptiveExperienceProvider =
    Provider.family<AdaptiveExperienceState, AdaptiveExperienceInputs>((
      ref,
      inputs,
    ) {
      return ref.read(adaptiveExperienceControllerProvider).resolve(inputs);
    });
