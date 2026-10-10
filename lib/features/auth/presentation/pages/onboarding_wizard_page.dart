import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/motion/nav_haptics.dart';
import '../../../../core/motion/nav_motion.dart';
import '../../../../core/router/entry_guard.dart';
import '../../../places/presentation/providers/places_provider.dart';
import '../../../profile/domain/models/user_preferences_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../widgets/entry_frame.dart';

class OnboardingWizardPage extends StatelessWidget {
  const OnboardingWizardPage({super.key});
  @override
  Widget build(BuildContext context) => EntryPreferencesGate(
    builder: (uid, preferences) =>
        _IdentityEditor(uid: uid, initial: preferences),
  );
}

class _IdentityEditor extends ConsumerStatefulWidget {
  final String uid;
  final UserPreferencesModel initial;
  const _IdentityEditor({required this.uid, required this.initial});
  @override
  ConsumerState<_IdentityEditor> createState() => _IdentityEditorState();
}

class _IdentityEditorState extends ConsumerState<_IdentityEditor> {
  late UserPreferencesModel _draft = widget.initial;
  late final _city = TextEditingController(text: _draft.homeCity ?? '');
  int _step = 0;
  bool _saving = false;
  String? _error;
  bool _searching = false;
  bool _searched = false;
  List<Map<String, String>> _suggestions = [];

  static const _titles = [
    'Travel, on your terms.',
    'Find your travel rhythm.',
    'Who shares the journey?',
    'What pulls you somewhere?',
    'Make room for your needs.',
    'Where do you call home?',
    'A little more you.',
  ];
  static const _subtitles = [
    'Travel should feel like an experience, not a project to manage.',
    'Choose the approach you most often enjoy. You can review it before finishing.',
    'Your usual company, not a rule for every trip.',
    'Pick what interests you. There is no minimum and no hidden score.',
    'Optional. Share only what you want considered when planning.',
    'Optional. Type a city or look for suggestions. No location permission needed.',
    'Naviigo can subtly adapt its layout and visual rhythm to your journey.',
  ];

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  void _select(UserPreferencesModel next) {
    NavHaptics.fire(NavHaptic.light);
    setState(() => _draft = next);
  }

  List<String> _toggle(List<String> values, String value) {
    final result = [...values];
    result.contains(value) ? result.remove(value) : result.add(value);
    return result;
  }

  Future<void> _search() async {
    final query = _city.text.trim();
    if (query.length < 2) return;
    setState(() {
      _searching = true;
      _searched = false;
    });
    List<Map<String, String>> results;
    try {
      results = await ref
          .read(placesRepositoryProvider)
          .searchAutocomplete(query)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      results = [];
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searched = query == _city.text.trim();
      _suggestions = _searched ? results : [];
    });
  }

  Future<void> _next() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (_step < 6) {
      setState(() => _step++);
      return;
    }
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
          .updateUserPreferences(
            widget.uid,
            _draft.copyWith(homeCity: _city.text.trim()),
            includeEmptyLists: true,
          )
          .timeout(const Duration(seconds: 15));
      await ref
          .refresh(userPreferencesStreamProvider.future)
          .timeout(const Duration(seconds: 15));
      if (mounted && ref.read(currentUserProvider)?.uid == widget.uid) {
        context.go(entryLocation('/vibe-match', GoRouterState.of(context).uri));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Your save is not confirmed yet. Check your connection and retry. Your choices are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _choices(
    Map<String, String> options,
    bool Function(String) selected,
    void Function(String) select,
  ) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: options.entries
        .map(
          (e) => FilterChip(
            label: Text(e.value),
            selected: selected(e.key),
            onSelected: (_) => select(e.key),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        )
        .toList(),
  );

  Widget _content() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/brand/jaipur-heritage.jpg',
                height: 200,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 100,
                  child: Icon(Icons.explore_outlined, size: 48),
                ),
              ),
            ),
            const EntryMessage(
              'Build a travel identity with a few choices. Nothing is assumed, and optional details can stay private.',
            ),
          ],
        );
      case 1:
        return _choices(
          const {
            'budget': 'Backpacking · Budget',
            'mid-range': 'Comfort · Mid-range',
            'luxury': 'Luxury',
          },
          (v) => _draft.travelStyle == v,
          (v) => _select(_draft.copyWith(travelStyle: v)),
        );
      case 2:
        return _choices(
          const {
            'solo': 'Solo',
            'couple': 'Couple',
            'friends': 'Friends',
            'family': 'Family',
          },
          (v) => _draft.preferredGroup == v,
          (v) => _select(_draft.copyWith(preferredGroup: v)),
        );
      case 3:
        return _choices(
          const {
            'culture': 'Culture',
            'food': 'Food',
            'nature': 'Nature',
            'adventure': 'Adventure',
            'spiritual': 'Spiritual',
            'beaches': 'Beaches',
            'nightlife': 'Nightlife & social',
          },
          _draft.interests.contains,
          (v) =>
              _select(_draft.copyWith(interests: _toggle(_draft.interests, v))),
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dietary preferences'),
            const SizedBox(height: 12),
            _choices(
              const {
                'vegetarian': 'Vegetarian',
                'vegan': 'Vegan',
                'jain': 'Jain',
                'gluten-free': 'Gluten-free',
              },
              _draft.dietaryPreferences.contains,
              (v) => _select(
                _draft.copyWith(
                  dietaryPreferences: _toggle(_draft.dietaryPreferences, v),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Accessibility needs'),
            const SizedBox(height: 12),
            _choices(
              const {
                'wheelchair': 'Wheelchair access',
                'step-free': 'Step-free routes',
                'limited-walking': 'Less walking',
              },
              _draft.accessibilityNeeds.contains,
              (v) => _select(
                _draft.copyWith(
                  accessibilityNeeds: _toggle(_draft.accessibilityNeeds, v),
                ),
              ),
            ),
            const EntryMessage(
              'Preferences help express your needs; venue accessibility still needs to be verified.',
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Home city'),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {
                _suggestions = [];
                _searched = false;
              }),
            ),
            OutlinedButton(
              onPressed: _searching || _city.text.trim().length < 2
                  ? null
                  : _search,
              child: const Text('Find city suggestions'),
            ),
            if (_searching)
              const LinearProgressIndicator(semanticsLabel: 'Searching cities'),
            if (_searched && _suggestions.isEmpty) ...[
              const EntryMessage(
                'No suggestions available. Keep your typed city, skip, or retry.',
              ),
              TextButton(
                onPressed: _search,
                child: const Text('Retry suggestions'),
              ),
            ],
            ..._suggestions
                .take(5)
                .map(
                  (s) => ListTile(
                    title: Text(s['description'] ?? ''),
                    onTap: () => setState(() {
                      _city.text = s['description'] ?? '';
                      _suggestions = [];
                      _searched = false;
                    }),
                  ),
                ),
          ],
        );
      default:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Adaptive Appearance'),
          subtitle: const Text(
            'Turn it off anytime for the standard Naviigo appearance.',
          ),
          value: _draft.adaptiveAppearanceEnabled,
          onChanged: _saving
              ? null
              : (v) => _select(_draft.copyWith(adaptiveAppearanceEnabled: v)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        (_step != 1 || _draft.travelStyle != null) &&
        (_step != 2 || _draft.preferredGroup != null);
    return EntryFrame(
      eyebrow: 'YOUR TRAVEL IDENTITY',
      title: _titles[_step],
      subtitle: _subtitles[_step],
      step: _step,
      onBack: _step > 0 && !_saving ? () => setState(() => _step--) : null,
      children: [
        AnimatedSwitcher(
          duration: NavReduce.duration(context, NavMotion.fast),
          child: KeyedSubtree(key: ValueKey(_step), child: _content()),
        ),
        if (_error != null) EntryMessage(_error!),
        const SizedBox(height: 28),
        if (_saving)
          const LinearProgressIndicator(semanticsLabel: 'Saving preferences'),
        ElevatedButton(
          onPressed: !_saving && canContinue ? _next : null,
          child: Text(
            _saving
                ? 'Waiting for confirmation…'
                : _error != null
                ? 'Retry save'
                : _step == 6
                ? 'Save & explore your vibe'
                : 'Continue',
          ),
        ),
        if (_step == 4 || _step == 5)
          TextButton(onPressed: _next, child: const Text('Skip this step')),
      ],
    );
  }
}
