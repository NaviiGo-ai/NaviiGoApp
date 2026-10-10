import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/router/entry_guard.dart';
import '../../auth/presentation/widgets/entry_frame.dart';
import '../../profile/presentation/providers/user_provider.dart';

/// Waits for real auth/preferences state; no artificial splash timer.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(entryStatusProvider) == EntryStatus.error;
    return EntryFrame(
      eyebrow: 'NAVIIGO',
      title: 'Every journey has a story.',
      subtitle: error
          ? 'We could not open your travel profile.'
          : 'Preparing your next chapter.',
      children: [
        Image.asset(
          'assets/brand/naviigo-mark-primary.png',
          height: 88,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.explore_outlined, size: 64),
        ),
        const SizedBox(height: 32),
        if (error) ...[
          const EntryMessage(
            'Check your connection and try again. Your saved choices are safe.',
          ),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(authStateProvider);
              ref.invalidate(userPreferencesStreamProvider);
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(authControllerProvider.notifier)
                  .signOut();
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not sign out. Please retry.'),
                  ),
                );
              }
            },
            child: const Text('Use another account'),
          ),
        ] else
          const LinearProgressIndicator(semanticsLabel: 'Loading your session'),
      ],
    );
  }
}
