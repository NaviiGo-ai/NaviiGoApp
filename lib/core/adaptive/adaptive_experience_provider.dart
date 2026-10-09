import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adaptive_experience_controller.dart';
import 'adaptive_experience_profile.dart';
import 'adaptive_experience_state.dart';

final adaptiveExperienceControllerProvider =
    Provider<AdaptiveExperienceController>((ref) {
      return const AdaptiveExperienceController();
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
