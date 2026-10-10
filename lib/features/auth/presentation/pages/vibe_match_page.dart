import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/motion/nav_haptics.dart';
import '../../../../core/motion/nav_motion.dart';
import '../../../../core/router/entry_guard.dart';
import '../../../profile/domain/models/user_preferences_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../widgets/entry_frame.dart';

class VibeMatchPage extends StatelessWidget {
  const VibeMatchPage({super.key});
  @override
  Widget build(BuildContext context) => EntryPreferencesGate(
    builder: (uid, preferences) => _VibeEditor(uid: uid, initial: preferences),
  );
}

class _VibeEditor extends ConsumerStatefulWidget {
  final String uid;
  final UserPreferencesModel initial;
  const _VibeEditor({required this.uid, required this.initial});
  @override
  ConsumerState<_VibeEditor> createState() => _VibeEditorState();
}

class _VibeEditorState extends ConsumerState<_VibeEditor> {
  // Explicit, visible interest labels, not destination IDs or inferred scores.
  static const _cards = [
    ('jaipur', 'culture', 'Culture'),
    ('varanasi', 'spiritual', 'Spiritual'),
    ('kochi', 'nature', 'Nature'),
    ('ladakh', 'adventure', 'Adventure'),
  ];
  late final _vibes = _cards
      .where((c) => findDestinationById(c.$1) != null)
      .toList();
  late Set<String> _interests = widget.initial.interests.toSet();
  final _undo = <Set<String>>[];
  final _pages = PageController();
  int _index = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _toggle(String interest) {
    NavHaptics.fire(NavHaptic.light);
    setState(() {
      _undo.add({..._interests});
      _interests.contains(interest)
          ? _interests.remove(interest)
          : _interests.add(interest);
    });
  }

  void _move(int next) {
    if (NavReduce.of(context)) {
      _pages.jumpToPage(next);
    } else {
      _pages.animateToPage(
        next,
        duration: NavMotion.fast,
        curve: NavMotion.settle,
      );
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (ref.read(currentUserProvider)?.uid != widget.uid) {
        throw StateError('Session changed');
      }
      await ref
          .read(userRepositoryProvider)
          .completeOnboarding(
            widget.uid,
            widget.initial.copyWith(interests: _interests.toList()),
          )
          .timeout(const Duration(seconds: 15));
      ref.invalidate(userPreferencesStreamProvider);
      // The guard enters Home (or the retained deep link) only when the
      // confirmed preferences stream reports explicit completion.
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Completion is not confirmed yet. Check your connection and retry. Your choices are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntryFrame(
      eyebrow: 'VIBE MATCH',
      title: 'Follow what draws you in.',
      subtitle:
          'Swipe to browse. Tap an interest to add or remove it. Only the choices shown below are saved.',
      onBack: _saving
          ? null
          : () => context.go(
              entryLocation('/onboarding', GoRouterState.of(context).uri),
            ),
      children: [
        if (_vibes.isEmpty)
          const EntryMessage(
            'No inspiration cards available. You can still finish with your current interests.',
          )
        else ...[
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pages,
              itemCount: _vibes.length,
              onPageChanged: (i) {
                NavHaptics.fire(NavHaptic.light);
                setState(() => _index = i);
              },
              itemBuilder: (context, i) {
                final destination = findDestinationById(_vibes[i].$1)!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      destination.image,
                      height: 180,
                      fit: BoxFit.cover,
                      semanticLabel: destination.name,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 180,
                        child: Center(child: Text('Image unavailable')),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${findDestinationById(_vibes[_index].$1)!.name} · ${_vibes[_index].$3}',
            textAlign: TextAlign.center,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'Previous inspiration',
                onPressed: _index == 0 ? null : () => _move(_index - 1),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text('${_index + 1} of ${_vibes.length}'),
              IconButton(
                tooltip: 'Next inspiration',
                onPressed: _index == _vibes.length - 1
                    ? null
                    : () => _move(_index + 1),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
          FilterChip(
            label: Text(
              '${_interests.contains(_vibes[_index].$2) ? 'Remove' : 'Add'} ${_vibes[_index].$3} interest',
            ),
            selected: _interests.contains(_vibes[_index].$2),
            onSelected: _saving ? null : (_) => _toggle(_vibes[_index].$2),
          ),
        ],
        const SizedBox(height: 20),
        const Text('Your selected interests'),
        if (_interests.isEmpty)
          const EntryMessage(
            'No interests selected. That is okay — interests are optional.',
          ),
        Wrap(
          spacing: 8,
          children: _interests
              .map(
                (v) => InputChip(
                  label: Text(v),
                  onDeleted: _saving ? null : () => _toggle(v),
                ),
              )
              .toList(),
        ),
        TextButton.icon(
          onPressed: _saving || _undo.isEmpty
              ? null
              : () {
                  NavHaptics.fire(NavHaptic.light);
                  setState(() => _interests = _undo.removeLast());
                },
          icon: const Icon(Icons.undo_rounded),
          label: const Text('Undo last change'),
        ),
        const EntryMessage(
          'Finish confirms your travel identity. You do not need to add any more interests.',
        ),
        if (_error != null) EntryMessage(_error!),
        if (_saving)
          const LinearProgressIndicator(
            semanticsLabel: 'Confirming onboarding',
          ),
        ElevatedButton(
          onPressed: _saving ? null : _finish,
          child: Text(
            _saving
                ? 'Waiting for confirmation…'
                : _error == null
                ? 'Finish & start exploring'
                : 'Retry completion',
          ),
        ),
      ],
    );
  }
}
