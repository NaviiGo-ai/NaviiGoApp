import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../pilgrimage/domain/pilgrimage_pilot.dart';
import '../../../places/data/places_repository.dart';
import '../../../places/domain/models/place_model.dart';
import '../../../places/presentation/providers/places_provider.dart';

enum HomeDiscoveryCategory {
  all('Discover'),
  pilgrimage('Pilgrimage'),
  nature('Nature'),
  heritage('Heritage'),
  coast('Coast');

  final String label;
  const HomeDiscoveryCategory(this.label);
}

class HomeDiscoveryEntry {
  final MasterDestination destination;
  final PlaceModel? place;
  const HomeDiscoveryEntry(this.destination, [this.place]);
  String get id =>
      place == null ? 'city:${destination.id}' : 'place:${place!.id}';
}

class HomeDiscoveryState {
  final HomeDiscoveryCategory category;
  final List<HomeDiscoveryEntry> entries;
  final int cursor;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  const HomeDiscoveryState({
    this.category = HomeDiscoveryCategory.all,
    this.entries = const [],
    this.cursor = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });
}

/// One bounded nearby-place request per city, only as the reader scrolls.
/// A failed page retains its cursor for Retry; it never masquerades as empty.
class HomeDiscoveryController extends StateNotifier<HomeDiscoveryState> {
  final PlacesRepository repository;
  final List<MasterDestination> catalogue;
  final _seen = <String>{};
  int _generation = 0;
  double scrollOffset = 0;

  HomeDiscoveryController(this.repository, {List<MasterDestination>? catalogue})
    : catalogue = catalogue ?? kMasterDestinations,
      super(const HomeDiscoveryState());

  List<MasterDestination> get cities {
    final filtered = catalogue
        .where(
          (city) => switch (state.category) {
            HomeDiscoveryCategory.all => true,
            HomeDiscoveryCategory.pilgrimage => city.category == 'Spiritual',
            HomeDiscoveryCategory.nature => const [
              'Mountains',
              'Adventure',
            ].contains(city.category),
            HomeDiscoveryCategory.heritage => city.category == 'Heritage',
            HomeDiscoveryCategory.coast => city.category == 'Coastal',
          },
        )
        .toList();
    final priority = pilgrimageDestinations.map((d) => d.id).toList();
    return [
      for (final id in priority) ...filtered.where((d) => d.id == id),
      ...filtered.where((d) => !priority.contains(d.id)),
    ];
  }

  Future<void> loadNext() async {
    if (!mounted || state.isLoading || !state.hasMore) return;
    final available = cities;
    if (state.cursor >= available.length) {
      state = HomeDiscoveryState(
        category: state.category,
        entries: state.entries,
        cursor: state.cursor,
        hasMore: false,
      );
      return;
    }
    final generation = _generation;
    final cursor = state.cursor;
    final city = available[cursor];
    final cityEntry = HomeDiscoveryEntry(city);
    final entries = [...state.entries];
    if (_seen.add(cityEntry.id)) entries.add(cityEntry);
    state = HomeDiscoveryState(
      category: state.category,
      entries: List.unmodifiable(entries),
      cursor: cursor,
      isLoading: true,
    );
    try {
      final places = await repository.getNearbyPlaces(
        lat: city.lat,
        lng: city.lng,
        radius: 8000,
      );
      if (!mounted || generation != _generation) return;
      for (final place in places.take(20)) {
        if (!_nearCity(place, city)) continue;
        final entry = HomeDiscoveryEntry(city, place);
        if (_seen.add(entry.id)) entries.add(entry);
      }
      state = HomeDiscoveryState(
        category: state.category,
        entries: List.unmodifiable(entries),
        cursor: cursor + 1,
        hasMore: cursor + 1 < available.length,
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = HomeDiscoveryState(
        category: state.category,
        entries: List.unmodifiable(entries),
        cursor: cursor,
        error: 'Places around ${city.name} could not load.',
      );
    }
  }

  Future<void> refresh([HomeDiscoveryCategory? category]) async {
    _generation++;
    _seen.clear();
    scrollOffset = 0;
    state = HomeDiscoveryState(category: category ?? state.category);
    await loadNext();
  }

  Future<void> skipUnavailableCity() async {
    if (state.error == null || state.isLoading) return;
    final next = state.cursor + 1;
    state = HomeDiscoveryState(
      category: state.category,
      entries: state.entries,
      cursor: next,
      hasMore: next < cities.length,
    );
    await loadNext();
  }

  static bool _nearCity(PlaceModel place, MasterDestination city) {
    if (const {
      'religious monuments',
      'tourist attraction',
      'monument',
      'statue',
    }.contains(place.name.trim().toLowerCase())) {
      return false;
    }
    if (place.id.isEmpty ||
        place.name.trim().isEmpty ||
        !place.hasCoordinates) {
      return false;
    }
    double radians(double value) => value * math.pi / 180;
    final dLat = radians(place.lat! - city.lat);
    final dLng = radians(place.lng! - city.lng);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(city.lat)) *
            math.cos(radians(place.lat!)) *
            math.pow(math.sin(dLng / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1))) <= 12;
  }
}

final homeDiscoveryProvider =
    StateNotifierProvider<HomeDiscoveryController, HomeDiscoveryState>((ref) {
      // Reset the feed/filter on account changes without mixing private trip data.
      ref.watch(currentUserProvider.select((user) => user?.uid));
      return HomeDiscoveryController(ref.watch(placesRepositoryProvider));
    });
