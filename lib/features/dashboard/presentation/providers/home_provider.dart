import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/adaptive/adaptive_experience_profile.dart';
import '../../../../core/adaptive/adaptive_experience_provider.dart';

enum HomeJourneySurface { discovery, upcoming, active }

HomeJourneySurface homeSurfaceForLifecycle(AdaptiveJourneyLifecycle lifecycle) {
  switch (lifecycle) {
    case AdaptiveJourneyLifecycle.activeTrip:
      return HomeJourneySurface.active;
    case AdaptiveJourneyLifecycle.upcoming:
      return HomeJourneySurface.upcoming;
    case AdaptiveJourneyLifecycle.discover:
    case AdaptiveJourneyLifecycle.planning:
    case AdaptiveJourneyLifecycle.postTrip:
      return HomeJourneySurface.discovery;
  }
}

final homeJourneySurfaceProvider = Provider<HomeJourneySurface>((ref) {
  return homeSurfaceForLifecycle(ref.watch(adaptiveJourneyLifecycleProvider));
});
