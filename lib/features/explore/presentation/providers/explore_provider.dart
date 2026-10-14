import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../places/data/places_repository.dart';
import '../../../places/presentation/providers/places_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../data/recommendations_repository.dart';
import '../../domain/models/recommendation_model.dart';

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepository(apiClient: ref.watch(apiClientProvider)),
);

final recommendationsProvider = FutureProvider.autoDispose
    .family<List<RecommendationModel>, String>((ref, ownerUid) async {
      final user = ref.watch(currentUserProvider);
      if (user == null || user.uid != ownerUid) return [];
      final preferences = ref.watch(safeAdaptivePreferencesProvider);
      return ref
          .read(recommendationsRepositoryProvider)
          .getRecommendations(
            user: user,
            interests: preferences.interests,
            group: preferences.preferredGroup,
          );
    });

enum ExploreSearchStatus { idle, loading, success, empty, unavailable }

class ExploreSearchState {
  final ExploreSearchStatus status;
  final List<MasterDestination> destinations;
  final List<Map<String, String>> suggestions;

  const ExploreSearchState({
    required this.status,
    this.destinations = const [],
    this.suggestions = const [],
  });

  const ExploreSearchState.idle() : this(status: ExploreSearchStatus.idle);
}

final exploreSearchProvider = FutureProvider.autoDispose
    .family<ExploreSearchState, ({String query, String? ownerUid})>((
      ref,
      args,
    ) async {
      final query = args.query.trim();
      if (query.length < 2) return const ExploreSearchState.idle();

      // The provider key includes the authenticated owner. Old unauthenticated
      // place responses can finish, but can never become the new user's state.
      final ready = Completer<void>();
      var disposed = false;
      final timer = Timer(const Duration(milliseconds: 300), ready.complete);
      ref.onDispose(() {
        disposed = true;
        timer.cancel();
        if (!ready.isCompleted) ready.complete();
      });
      ref.onCancel(() {
        disposed = true;
        timer.cancel();
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
      if (disposed) return const ExploreSearchState.idle();
      final alias = findDestinationById(query);
      final local = kMasterDestinations.where((destination) {
        final clean = query.toLowerCase();
        return destination.id == alias?.id ||
            destination.name.toLowerCase().contains(clean) ||
            destination.state.toLowerCase().contains(clean) ||
            destination.category.toLowerCase().contains(clean) ||
            destination.description.toLowerCase().contains(clean);
      }).toList();
      AutocompleteSearchResult response;
      try {
        response = await ref
            .read(placesRepositoryProvider)
            .searchAutocompleteResult(query);
      } catch (_) {
        return ExploreSearchState(
          status: local.isEmpty
              ? ExploreSearchStatus.unavailable
              : ExploreSearchStatus.success,
          destinations: local,
        );
      }
      final suggestions = response.predictions
          .where((item) => item['description']?.isNotEmpty ?? false)
          .toList();
      if (local.isEmpty && suggestions.isEmpty && response.unavailable) {
        return ExploreSearchState(
          status: ExploreSearchStatus.unavailable,
          destinations: local,
        );
      }
      if (local.isEmpty && suggestions.isEmpty) {
        return ExploreSearchState(
          status: ExploreSearchStatus.empty,
          destinations: local,
        );
      }
      return ExploreSearchState(
        status: ExploreSearchStatus.success,
        destinations: local,
        suggestions: suggestions,
      );
    });
