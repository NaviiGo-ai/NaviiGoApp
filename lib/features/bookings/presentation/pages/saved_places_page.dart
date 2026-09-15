import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../providers/saved_places_provider.dart';
import '../../domain/models/saved_place_model.dart';

class SavedPlacesPage extends ConsumerWidget {
  const SavedPlacesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlacesAsync = ref.watch(savedPlacesStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Saved Places',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: savedPlacesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFEC6426)),
        ),
        error: (err, _) =>
            Center(child: Text('Error loading saved places: $err')),
        data: (places) {
          if (places.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return _buildPlaceItem(context, ref, user?.uid, place);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEC6426).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 48,
                color: Color(0xFFEC6426),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No saved places yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bookmark monuments, stays, and scenic viewpoints across India to quickly add them to future itineraries.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC6426),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Explore Places',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceItem(
    BuildContext context,
    WidgetRef ref,
    String? uid,
    SavedPlaceModel place,
  ) {
    final hasImage = place.image != null && place.image!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? Image.network(
                  place.image!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/brand/india-cover-soft.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/brand/india-cover-soft.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          place.location ?? place.type,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.bookmark_remove_rounded,
            color: Color(0xFFEC6426),
          ),
          onPressed: () {
            if (uid != null) {
              ref
                  .read(savedPlacesRepositoryProvider)
                  .toggleSavedPlace(uid, place);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed ${place.name} from saved places'),
                ),
              );
            }
          },
        ),
        onTap: () {
          if (place.id.startsWith('rest_')) {
            context.push('/restaurants');
          } else {
            context.push('/trip-planner', extra: {'destination': place.name});
          }
        },
      ),
    );
  }
}
