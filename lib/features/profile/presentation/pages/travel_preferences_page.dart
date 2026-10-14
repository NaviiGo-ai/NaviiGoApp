import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../domain/models/user_preferences_model.dart';
import '../providers/user_provider.dart';

class TravelPreferencesPage extends ConsumerWidget {
  const TravelPreferencesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    return Scaffold(
      appBar: AppBar(
        leading: const NavHubLeading(),
        title: const Text('Travel preferences'),
      ),
      body: ref
          .watch(userPreferencesStreamProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(userPreferencesStreamProvider),
                child: const Text('Could not load preferences. Retry'),
              ),
            ),
            data: (preferences) =>
                uid == null || preferences.sourceUserId != uid
                ? const Center(child: Text('Sign in to edit your preferences.'))
                : _PreferencesEditor(
                    key: ValueKey(uid),
                    uid: uid,
                    initial: preferences,
                  ),
          ),
    );
  }
}

class _PreferencesEditor extends ConsumerStatefulWidget {
  final String uid;
  final UserPreferencesModel initial;
  const _PreferencesEditor({
    super.key,
    required this.uid,
    required this.initial,
  });
  @override
  ConsumerState<_PreferencesEditor> createState() => _PreferencesEditorState();
}

class _PreferencesEditorState extends ConsumerState<_PreferencesEditor> {
  late UserPreferencesModel _draft = widget.initial;
  late final _city = TextEditingController(text: _draft.homeCity ?? '');
  bool _saving = false;
  String? _message;
  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || ref.read(currentUserProvider)?.uid != widget.uid) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .updateUserPreferences(
            widget.uid,
            _draft.copyWith(homeCity: _city.text.trim()),
            includeEmptyLists: true,
          );
      if (mounted && ref.read(currentUserProvider)?.uid == widget.uid) {
        setState(() => _message = 'Your travel preferences are saved.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not save preferences. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'Make each trip feel more like you.',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        value:
            const [
              'comfort',
              'backpacker',
              'luxury',
            ].contains(_draft.travelStyle)
            ? _draft.travelStyle
            : null,
        decoration: const InputDecoration(labelText: 'Travel style'),
        items: [
          for (final item in ['comfort', 'backpacker', 'luxury'])
            DropdownMenuItem(value: item, child: Text(item)),
        ],
        onChanged: _saving
            ? null
            : (value) =>
                  setState(() => _draft = _draft.copyWith(travelStyle: value)),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value:
            const [
              'solo',
              'couple',
              'family',
              'friends',
            ].contains(_draft.preferredGroup)
            ? _draft.preferredGroup
            : null,
        decoration: const InputDecoration(labelText: 'Usually travelling with'),
        items: [
          for (final item in ['solo', 'couple', 'family', 'friends'])
            DropdownMenuItem(value: item, child: Text(item)),
        ],
        onChanged: _saving
            ? null
            : (value) => setState(
                () => _draft = _draft.copyWith(preferredGroup: value),
              ),
      ),
      const SizedBox(height: 20),
      const Text('Your interests'),
      Wrap(
        spacing: 8,
        children: [
          for (final interest in {
            ..._draft.interests,
            'culture',
            'nature',
            'food',
            'adventure',
            'spiritual',
            'history',
          })
            FilterChip(
              label: Text(interest),
              selected: _draft.interests.contains(interest),
              onSelected: _saving
                  ? null
                  : (selected) => setState(
                      () => _draft = _draft.copyWith(
                        interests: selected
                            ? [..._draft.interests, interest]
                            : _draft.interests
                                  .where((i) => i != interest)
                                  .toList(),
                      ),
                    ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _city,
        enabled: !_saving,
        decoration: const InputDecoration(labelText: 'Home city (optional)'),
      ),
      const SizedBox(height: 20),
      if (_message != null) Text(_message!),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save preferences'),
      ),
    ],
  );
}
