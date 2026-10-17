import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/adaptive/adaptive_theme_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../explore/presentation/widgets/discovery_widgets.dart';
import '../../../pilgrimage/domain/pilgrimage_pilot.dart';
import '../providers/home_discovery_provider.dart';

class HomeDiscoveryWelcome extends StatelessWidget {
  const HomeDiscoveryWelcome({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOLLOW YOUR CURIOSITY',
            style: AppTypography.eyebrow(color: colors.primaryAction),
          ),
          const SizedBox(height: 10),
          Text(
            'Somewhere new.\nSomething meaningful.',
            style: AppTypography.editorialTitle(
              color: colors.editorialBrown,
            ).copyWith(fontSize: 32, height: 1.12),
          ),
          const SizedBox(height: 10),
          Text(
            'Sacred journeys, quiet corners and your next great detour.',
            style: AppTypography.bodyMedium(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class HomePilgrimageBanner extends StatelessWidget {
  const HomePilgrimageBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Semantics(
        button: true,
        label: 'Pilgrimage pilot',
        child: Material(
          color: colors.editorialBrown,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => context.push('/pilgrimage-pilot'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.temple_hindu_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A more thoughtful pilgrimage',
                          style: AppTypography.bodyMedium(
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Five destinations · start with Ujjain',
                          style: AppTypography.caption(
                            color: Colors.white.withAlpha(225),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeDiscoveryActions extends StatelessWidget {
  const HomeDiscoveryActions({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in const [
            (Icons.route_outlined, 'Plan a trip', '/trip-planner'),
            (Icons.bookmark_outline, 'Saved places', '/saved-places'),
            (Icons.landscape_outlined, 'Hidden gems', '/hidden-gems'),
            (Icons.train_outlined, 'Transit', '/transportation'),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push(item.$3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: colors.surfaceWarm,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            item.$1,
                            color: colors.editorialBrown,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.$2,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeDiscoveryFilters extends StatelessWidget {
  final HomeDiscoveryCategory selected;
  final ValueChanged<HomeDiscoveryCategory> onChanged;
  const HomeDiscoveryFilters({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Keep discovering',
                  style: AppTypography.editorialTitle(
                    color: colors.editorialBrown,
                  ).copyWith(fontSize: 27),
                ),
              ),
              Icon(Icons.explore_outlined, color: colors.primaryAction),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Row(
            children: [
              for (final category in HomeDiscoveryCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: selected == category,
                    onSelected: (_) => onChanged(category),
                    selectedColor: colors.editorialBrown,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected == category
                          ? Colors.white
                          : colors.textPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeDiscoveryCard extends StatelessWidget {
  final HomeDiscoveryEntry entry;
  const HomeDiscoveryCard({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    final city = entry.destination;
    final place = entry.place;
    final pilot = findPilgrimageDestination(city.id);
    final title = place?.name ?? (pilot?.title ?? city.name);
    void open() {
      if (place != null) {
        context.push('/place-details', extra: place);
      } else if (pilot != null) {
        context.push('/pilgrimage-pilot/${city.id}');
      } else {
        context.push('/destination/${city.id}');
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiscoveryImage(
                image:
                    place?.photoUrl ??
                    (place == null ? destinationImage(city) : null),
                label: place == null
                    ? '${city.name}, ${city.state}'
                    : '${place.name}, ${city.name}, ${city.state}',
                height: place == null ? 250 : 205,
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place == null
                          ? city.category.toUpperCase()
                          : 'AROUND ${city.name.toUpperCase()}',
                      style: AppTypography.eyebrow(color: colors.primaryAction),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: AppTypography.editorialTitle(
                        color: colors.editorialBrown,
                      ).copyWith(fontSize: place == null ? 27 : 23),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place == null ? city.state : place.vicinity,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (place == null && city.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        city.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place != null
                                ? 'Take a closer look'
                                : pilot != null
                                ? 'Prepare this journey'
                                : 'Explore destination',
                            style: AppTypography.bodySmall(
                              color: colors.primaryAction,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.primaryAction,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDiscoveryFooter extends StatelessWidget {
  final HomeDiscoveryState state;
  final VoidCallback onLoadMore;
  final VoidCallback onSkip;
  const HomeDiscoveryFooter({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.onSkip,
  });
  @override
  Widget build(BuildContext context) {
    final colors = AdaptiveThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(
        children: [
          if (state.isLoading) ...[
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: colors.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Finding your next detour…',
              style: AppTypography.bodySmall(color: colors.textSecondary),
            ),
          ] else if (state.error != null) ...[
            const Icon(Icons.cloud_off_outlined, size: 24),
            const SizedBox(height: 10),
            Text(state.error!, textAlign: TextAlign.center),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry places'),
                ),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Keep exploring'),
                ),
              ],
            ),
          ] else if (state.hasMore)
            OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.south_rounded),
              label: const Text('Discover more'),
            )
          else ...[
            Icon(
              Icons.wb_sunny_outlined,
              color: colors.primaryAction,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              'You’re all caught up.',
              style: AppTypography.bodyMedium(color: colors.editorialBrown),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another category or pull down to refresh.',
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'Place data: Geoapify / OpenStreetMap',
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
