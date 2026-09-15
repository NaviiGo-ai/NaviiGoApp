import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class GuideItem {
  final String id;
  final String name;
  final String destination;
  final String specialization;
  final List<String> languages;
  final double rating;
  final int reviewsCount;
  final String licenseNumber;

  const GuideItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.specialization,
    required this.languages,
    required this.rating,
    required this.reviewsCount,
    required this.licenseNumber,
  });

  String get initials =>
      name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join();
}

const List<GuideItem> kVerifiedGuides = [
  GuideItem(
    id: 'g_1',
    name: 'Rajendra Sharma',
    destination: 'Jaipur',
    specialization: 'Rajput Architecture & Amer Fort Historian',
    languages: ['English', 'Hindi', 'French'],
    rating: 4.9,
    reviewsCount: 142,
    licenseNumber: 'MOT-IN-JP-2018-884',
  ),
  GuideItem(
    id: 'g_2',
    name: 'Vikas Pandey',
    destination: 'Varanasi',
    specialization: 'Ghats Philosophy, Morning Chants & Silk Weaving',
    languages: ['English', 'Hindi', 'Sanskrit'],
    rating: 4.95,
    reviewsCount: 189,
    licenseNumber: 'MOT-IN-VNS-2016-419',
  ),
  GuideItem(
    id: 'g_3',
    name: 'Ananya Nair',
    destination: 'Munnar',
    specialization: 'Western Ghats Biodiversity & Tea Plantation Trails',
    languages: ['English', 'Malayalam', 'Tamil'],
    rating: 4.88,
    reviewsCount: 96,
    licenseNumber: 'MOT-IN-KL-2020-102',
  ),
  GuideItem(
    id: 'g_4',
    name: 'Manjunath Gowda',
    destination: 'Hampi',
    specialization: 'Vijayanagara Empire Archaeology & Boulder Treks',
    languages: ['English', 'Kannada', 'Hindi'],
    rating: 4.92,
    reviewsCount: 114,
    licenseNumber: 'MOT-IN-KA-2017-632',
  ),
];

class LocalGuidesPage extends StatefulWidget {
  const LocalGuidesPage({super.key});

  @override
  State<LocalGuidesPage> createState() => _LocalGuidesPageState();
}

class _LocalGuidesPageState extends State<LocalGuidesPage> {
  String _selectedDestination = 'All';

  @override
  Widget build(BuildContext context) {
    final destinations = [
      'All',
      ...kMasterDestinations.map((d) => d.name).take(6),
    ];
    final filteredGuides = _selectedDestination == 'All'
        ? kVerifiedGuides
        : kVerifiedGuides
              .where((g) => g.destination == _selectedDestination)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'VERIFIED LOCAL GUIDES',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: destinations.map((dest) {
                final isSelected = _selectedDestination == dest;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      dest.toUpperCase(),
                      style: AppTypography.micro(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedDestination = dest);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Guides List
          Expanded(
            child: filteredGuides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_search_outlined,
                          size: 48,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No guides found for $_selectedDestination',
                          style: AppTypography.tripTitle(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try selecting "All" to view all certified guides',
                          style: AppTypography.caption(),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: filteredGuides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final guide = filteredGuides[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.warmCream,
                                  child: Text(
                                    guide.initials,
                                    style: AppTypography.editorialTitle(
                                      color: AppColors.brown,
                                    ).copyWith(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              guide.name,
                                              style: AppTypography.tripTitle(
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.teal.withAlpha(
                                                20,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'CERTIFIED',
                                              style: AppTypography.micro(
                                                color: AppColors.teal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${guide.destination} • MOT License ${guide.licenseNumber}',
                                        style: AppTypography.micro(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: AppColors.yellow,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            guide.rating.toStringAsFixed(2),
                                            style:
                                                AppTypography.caption(
                                                  color: AppColors.textPrimary,
                                                ).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${guide.reviewsCount} journeys)',
                                            style: AppTypography.micro(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              guide.specialization,
                              style: AppTypography.bodyMedium(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: guide.languages.map((lang) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWarm,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    lang,
                                    style: AppTypography.micro(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _showGuideInquirySheet(context, guide);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'CONNECT WITH GUIDE',
                                  style: AppTypography.button(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGuideInquirySheet(BuildContext context, GuideItem guide) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.cream,
                  child: Text(
                    guide.initials,
                    style: AppTypography.tripTitle(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.name,
                        style: AppTypography.tripTitle(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${guide.destination} • Verified Heritage Expert',
                        style: AppTypography.caption(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Trip notes or preferred date:',
              style: AppTypography.caption(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText:
                    'e.g. 2 travelers, morning walking tour next Saturday',
                hintStyle: AppTypography.caption(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Inquiry sent to ${guide.name}! They will respond in your NaviiGo message thread.',
                    ),
                    backgroundColor: AppColors.teal,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SUBMIT INQUIRY',
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
}
