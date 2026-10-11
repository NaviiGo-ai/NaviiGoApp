import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../domain/models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';

class SavePlaceButton extends ConsumerWidget {
  final SavedPlaceModel place;
  final String? destinationId;
  const SavePlaceButton({super.key, required this.place, this.destinationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null || place.id.isEmpty) {
      return const Text('Sign in to save places');
    }
    final stream = ref.watch(savedPlacesStreamProvider);
    final saved = ref
        .watch(safeSavedPlacesProvider)
        .any((p) => p.id == place.id);
    final owned =
        stream.hasValue &&
        !stream.isReloading &&
        (stream.valueOrNull ?? []).every((p) => p.sourceUserId == uid);
    final provider = savedPlaceActionProvider((uid: uid, id: place.id));
    final action = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: !owned || action.isLoading
              ? null
              : () => ref
                    .read(provider.notifier)
                    .setSaved(place, !saved, destinationId: destinationId),
          icon: Icon(
            saved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined,
          ),
          label: Text(
            action.isLoading
                ? 'Saving…'
                : saved
                ? 'Remove from saved'
                : 'Save place',
          ),
        ),
        if (action.hasError)
          Semantics(
            liveRegion: true,
            child: Text(
              'Save failed. Your saved state is unchanged. Tap to retry.',
            ),
          ),
        if (stream.hasError)
          TextButton(
            onPressed: () => ref.invalidate(savedPlacesStreamProvider),
            child: const Text('Retry saved places'),
          ),
      ],
    );
  }
}
