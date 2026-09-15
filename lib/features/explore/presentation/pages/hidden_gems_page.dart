import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../bookings/presentation/providers/saved_places_provider.dart';
import '../../../bookings/domain/models/saved_place_model.dart';

class HiddenGemItem {
  final String id;
  final String name;
  final String state;
  final String category;
  final String desc;
  final String crowdLevel;
  final String bestSeason;
  final String difficulty;
  final IconData icon;

  const HiddenGemItem({
    required this.id,
    required this.name,
    required this.state,
    required this.category,
    required this.desc,
    required this.crowdLevel,
    required this.bestSeason,
    required this.difficulty,
    required this.icon,
  });
}

const List<HiddenGemItem> kAuthenticHiddenGems = [
  HiddenGemItem(
    id: 'spiti-valley',
    name: 'Spiti Valley',
    state: 'Himachal Pradesh',
    category: 'Mountains',
    desc:
        'High-altitude moonscape desert. 1000-year-old cliffside monasteries, frozen high passes, and secluded Himalayan hamlets.',
    crowdLevel: 'Very Low',
    bestSeason: 'Jun – Sep',
    difficulty: 'Moderate',
    icon: Icons.terrain_rounded,
  ),
  HiddenGemItem(
    id: 'majuli-island',
    name: 'Majuli Island',
    state: 'Assam',
    category: 'Offbeat',
    desc:
        "World's largest freshwater river island on the Brahmaputra. Living hub of neo-Vaishnavite culture and handmade bamboo mask artisans.",
    crowdLevel: 'Low',
    bestSeason: 'Oct – Mar',
    difficulty: 'Easy',
    icon: Icons.waves_rounded,
  ),
  HiddenGemItem(
    id: 'gokarna',
    name: 'Gokarna',
    state: 'Karnataka',
    category: 'Coastal',
    desc:
        'Ancient temple sanctuary meeting secluded Arabian Sea cliffs. Pristine crescent beaches untouched by commercial crowds.',
    crowdLevel: 'Low',
    bestSeason: 'Oct – Mar',
    difficulty: 'Easy',
    icon: Icons.beach_access_rounded,
  ),
  HiddenGemItem(
    id: 'chettinad',
    name: 'Chettinad',
    state: 'Tamil Nadu',
    category: 'Heritage',
    desc:
        'Grand 19th-century mansions built by merchant bankers, hand-pressed Athangudi tiles, and legendary pepper-and-star-anise cuisine.',
    crowdLevel: 'Very Low',
    bestSeason: 'Nov – Mar',
    difficulty: 'Easy',
    icon: Icons.castle_rounded,
  ),
  HiddenGemItem(
    id: 'ziro-valley',
    name: 'Ziro Valley',
    state: 'Arunachal Pradesh',
    category: 'Mountains',
    desc:
        'UNESCO World Heritage pine-clad valleys, gentle rice paddies, and the vibrant indigenous culture of the Apatani tribe.',
    crowdLevel: 'Very Low',
    bestSeason: 'Mar – Oct',
    difficulty: 'Easy',
    icon: Icons.park_rounded,
  ),
  HiddenGemItem(
    id: 'mandu',
    name: 'Mandu',
    state: 'Madhya Pradesh',
    category: 'Heritage',
    desc:
        'Forgotten fortress city draped in monsoon mist. Afghan domes, Jahaz Mahal floating between lakes, and tales of Baz Bahadur.',
    crowdLevel: 'Low',
    bestSeason: 'Jul – Mar',
    difficulty: 'Easy',
    icon: Icons.fort_rounded,
  ),
  HiddenGemItem(
    id: 'dhanushkodi',
    name: 'Dhanushkodi',
    state: 'Tamil Nadu',
    category: 'Coastal',
    desc:
        'Ethereal coastal ghost town at the southern tip of India where the Bay of Bengal merges into the Indian Ocean.',
    crowdLevel: 'Low',
    bestSeason: 'Oct – Mar',
    difficulty: 'Easy',
    icon: Icons.navigation_rounded,
  ),
  HiddenGemItem(
    id: 'mawlynnong',
    name: 'Mawlynnong',
    state: 'Meghalaya',
    category: 'Offbeat',
    desc:
        "Cleanest village in Asia. Centuries-old living root bridges woven from rubber trees and panoramic lookouts over the plains.",
    crowdLevel: 'Low',
    bestSeason: 'Oct – May',
    difficulty: 'Easy',
    icon: Icons.eco_rounded,
  ),
];

class HiddenGemsPage extends ConsumerStatefulWidget {
  const HiddenGemsPage({super.key});

  @override
  ConsumerState<HiddenGemsPage> createState() => _HiddenGemsPageState();
}

class _HiddenGemsPageState extends ConsumerState<HiddenGemsPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Mountains',
    'Coastal',
    'Heritage',
    'Offbeat',
  ];

  List<HiddenGemItem> get _filteredGems {
    if (_selectedCategory == 'All') return kAuthenticHiddenGems;
    return kAuthenticHiddenGems
        .where((g) => g.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final gems = _filteredGems;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brown),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'HIDDEN GEMS',
          style: AppTypography.editorialTitle(
            color: AppColors.brown,
          ).copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.brown),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showFilterSheet(context);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uncharted Sanctuaries',
                    style: AppTypography.editorialTitle(
                      color: AppColors.brown,
                    ).copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Curated enclaves with low crowd density, pristine heritage, and untamed nature across India.',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: AppTypography.button(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final gem = gems[index];
                return _buildGemCard(gem);
              }, childCount: gems.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemCard(HiddenGemItem gem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/trip-planner', extra: {'destination': gem.name});
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warmCream,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(gem.icon, color: AppColors.brown, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gem.name,
                            style: AppTypography.tripTitle(
                              color: AppColors.brown,
                            ),
                          ),
                          Text(
                            gem.state,
                            style: AppTypography.micro(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        gem.crowdLevel.toUpperCase(),
                        style: AppTypography.micro(
                          color: AppColors.teal,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  gem.desc,
                  style: AppTypography.bodySmall(
                    color: AppColors.textPrimary,
                  ).copyWith(height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gem.bestSeason,
                      style: AppTypography.micro(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Difficulty: ${gem.difficulty}',
                      style: AppTypography.micro(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final user = ref.read(currentUserProvider);
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please sign in to save places to your bucket list.',
                              ),
                            ),
                          );
                          return;
                        }

                        final savedPlace = SavedPlaceModel(
                          id: gem.id,
                          name: gem.name,
                          type: gem.category,
                          location: gem.state,
                          createdAt: DateTime.now(),
                        );

                        await ref
                            .read(savedPlacesRepositoryProvider)
                            .toggleSavedPlace(user.uid, savedPlace);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${gem.name} to your Saved Places',
                              ),
                              backgroundColor: AppColors.teal,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(
                        'Save',
                        style: AppTypography.micro(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Hidden Enclaves',
              style: AppTypography.tripTitle(color: AppColors.brown),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: AppTypography.button(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
