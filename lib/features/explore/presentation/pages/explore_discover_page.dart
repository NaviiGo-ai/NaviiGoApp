import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../analytics/data/analytics_repository.dart';
import '../../../dashboard/domain/models/destination_model.dart';
import '../../domain/models/recommendation_model.dart';
import '../providers/explore_provider.dart';
import '../widgets/discovery_widgets.dart';

class ExploreDiscoverPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  const ExploreDiscoverPage({super.key, this.initialQuery});

  @override
  ConsumerState<ExploreDiscoverPage> createState() =>
      _ExploreDiscoverPageState();
}

class _ExploreDiscoverPageState extends ConsumerState<ExploreDiscoverPage> {
  late final TextEditingController _searchController;
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    final ownerUid = ref.watch(currentUserProvider)?.uid;
    final searchKey = (query: _query, ownerUid: ownerUid);
    final search = ref.watch(exploreSearchProvider(searchKey));
    final categories = _categories;
    final recommendations = ownerUid == null
        ? const AsyncData<List<RecommendationModel>>([])
        : ref.watch(recommendationsProvider(ownerUid));

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _SearchHeader(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            if (_query.length < 2) ...[
              SliverToBoxAdapter(
                child: _CategoryChips(
                  categories: categories,
                  selected: _selectedCategory,
                  onSelected: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
              SliverToBoxAdapter(
                child: _RecommendationsSection(state: recommendations),
              ),
              SliverToBoxAdapter(
                child: _CuratedSection(category: _selectedCategory),
              ),
            ] else
              ..._searchSlivers(context, search, searchKey),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  List<Widget> _searchSlivers(
    BuildContext context,
    AsyncValue<ExploreSearchState> search,
    ({String query, String? ownerUid}) key,
  ) {
    return [
      SliverToBoxAdapter(
        child: search.when(
          loading: () => const _SearchStatus(
            message: 'Searching the atlas…',
            loading: true,
          ),
          error: (_, __) => _SearchStatus(
            message: 'Search is unavailable right now.',
            action: TextButton(
              onPressed: () => ref.invalidate(exploreSearchProvider(key)),
              child: const Text('Retry'),
            ),
          ),
          data: (state) {
            if (state.status == ExploreSearchStatus.unavailable) {
              return const _SearchStatus(
                message:
                    'The place provider is unavailable. Try again shortly.',
              );
            }
            if (state.status == ExploreSearchStatus.empty) {
              return _SearchStatus(
                message: 'No destinations or places matched “$_query”.',
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      if (search.hasValue) ...[
        if (search.value!.destinations.isNotEmpty)
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'CURATED DESTINATIONS'),
          ),
        if (search.value!.destinations.isNotEmpty)
          SliverList.builder(
            itemCount: search.value!.destinations.length,
            itemBuilder: (context, index) => _DestinationCard(
              destination: DestinationModel.fromMaster(
                search.value!.destinations[index],
              ),
            ),
          ),
        if (search.value!.suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'LIVE PLACE SUGGESTIONS'),
          ),
        if (search.value!.suggestions.isNotEmpty)
          SliverList.builder(
            itemCount: search.value!.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = search.value!.suggestions[index];
              return _SuggestionTile(
                suggestion: suggestion,
                onTap: () {
                  final value = suggestion['description'] ?? '';
                  _searchController.text = value;
                  _searchController.selection = TextSelection.collapsed(
                    offset: value.length,
                  );
                  setState(() => _query = value);
                },
              );
            },
          ),
      ],
    ];
  }

  List<String> get _categories => kMasterDestinations
      .map((destination) => destination.category)
      .toSet()
      .toList();
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'DISCOVER / EXPLORE',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow(color: tokens.primaryAction),
                ),
              ),
              IconButton(
                onPressed: () => context.push('/saved-places'),
                tooltip: 'Saved places',
                icon: Icon(
                  Icons.bookmark_border_rounded,
                  color: tokens.editorialBrown,
                ),
              ),
            ],
          ),
          Text(
            'Where next?',
            style: AppTypography.editorialTitle(color: tokens.editorialBrown),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search a destination or place',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: tokens.primaryAction,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) =>
                    onSelected(selected == category ? null : category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratedSection extends StatelessWidget {
  final String? category;
  const _CuratedSection({this.category});

  @override
  Widget build(BuildContext context) {
    final destinations = kMasterDestinations
        .where(
          (destination) => category == null || destination.category == category,
        )
        .take(8)
        .map(DestinationModel.fromMaster)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'CURATED DESTINATIONS'),
        ...destinations.map(
          (destination) => _DestinationCard(destination: destination),
        ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final AsyncValue state;
  const _RecommendationsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final tokens = AdaptiveThemeExtension.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOR YOUR NEXT CHAPTER',
                style: AppTypography.eyebrow(color: tokens.accentEmphasis),
              ),
              const SizedBox(height: 8),
              ...items
                  .take(5)
                  .map<Widget>(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.auto_awesome_outlined,
                        color: tokens.accentEmphasis,
                      ),
                      title: Text(item.name),
                      subtitle: item.reasons.isEmpty
                          ? null
                          : Text(item.reasons.first),
                      onTap: () => context.push('/destination/${item.id}'),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _DestinationCard extends ConsumerWidget {
  final DestinationModel destination;
  const _DestinationCard({required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            unawaited(
              ref
                  .read(analyticsRepositoryProvider)
                  .logEvent(
                    eventType: 'PLACE_VIEWED',
                    placeId: destination.id,
                    destinationId: destination.id,
                  ),
            );
            context.push('/destination/${destination.id}');
          },
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 100,
                child: DiscoveryImage(
                  image: approvedDestinationImage(
                    destinationId: destination.id,
                    image: destination.image,
                  ),
                  label: destination.title,
                  height: 100,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.category.toUpperCase(),
                        style: AppTypography.micro(color: tokens.primaryAction),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination.title,
                        style: AppTypography.bodyLarge(
                          color: tokens.editorialBrown,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        destination.subtitle,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (destination.bestTime.isNotEmpty)
                        Text(
                          'Best time: ${destination.bestTime}',
                          style: AppTypography.micro(
                            color: tokens.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final Map<String, String> suggestion;
  final VoidCallback onTap;
  const _SuggestionTile({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.place_outlined, color: tokens.primaryAction),
        title: Text(suggestion['description'] ?? ''),
        subtitle: (suggestion['sub'] ?? '').isEmpty
            ? null
            : Text(suggestion['sub']!),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        label,
        style: AppTypography.eyebrow(color: tokens.textTertiary),
      ),
    );
  }
}

class _SearchStatus extends StatelessWidget {
  final String message;
  final bool loading;
  final Widget? action;
  const _SearchStatus({
    required this.message,
    this.loading = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          if (loading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.primaryAction,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: tokens.textSecondary),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
