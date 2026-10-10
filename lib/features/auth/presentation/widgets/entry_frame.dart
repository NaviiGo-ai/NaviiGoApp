import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/journey_line.dart';
import '../../../profile/domain/models/user_preferences_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';

/// One scroll surface keeps entry controls reachable with keyboards and large text.
class EntryFrame extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final int? step;
  final int steps;
  final VoidCallback? onBack;

  const EntryFrame({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
    this.step,
    this.steps = 7,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          onPressed: onBack,
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      Expanded(
                        child: Text(
                          eyebrow,
                          style: AppTypography.eyebrow(
                            color: tokens.editorialBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step != null) ...[
                    Semantics(
                      label: 'Step ${step! + 1} of $steps',
                      child: ExcludeSemantics(
                        child: JourneyLine(
                          totalSteps: steps,
                          currentStep: step!.toDouble(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTypography.editorialTitle(
                      color: tokens.editorialBrown,
                    ).copyWith(fontSize: 30, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium(
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EntryMessage extends StatelessWidget {
  final String message;
  const EntryMessage(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: AppTypography.bodyMedium(
          color: AdaptiveThemeExtension.of(context).textPrimary,
        ),
      ),
    ),
  );
}

/// Hydrates each editor once per UID. Rebuilds never discard unsaved choices.
class EntryPreferencesGate extends ConsumerWidget {
  final Widget Function(String uid, UserPreferencesModel preferences) builder;
  const EntryPreferencesGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final preferences = ref.watch(userPreferencesStreamProvider);
    if (uid != null &&
        !preferences.isReloading &&
        preferences.valueOrNull?.sourceUserId == uid) {
      return KeyedSubtree(
        key: ValueKey(uid),
        child: builder(uid, preferences.valueOrNull!),
      );
    }
    return EntryFrame(
      eyebrow: 'YOUR TRAVEL IDENTITY',
      title: 'A journey that feels like you.',
      subtitle: uid == null
          ? 'Sign in to save your preferences.'
          : 'Opening your preferences.',
      children: [
        if (preferences.hasError) ...[
          const EntryMessage(
            'We could not load your preferences. Check your connection and retry.',
          ),
          OutlinedButton(
            onPressed: () => ref.invalidate(userPreferencesStreamProvider),
            child: const Text('Retry'),
          ),
        ] else
          const LinearProgressIndicator(semanticsLabel: 'Loading preferences'),
      ],
    );
  }
}
