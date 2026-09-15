import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ARExplorePage extends StatefulWidget {
  const ARExplorePage({super.key});

  @override
  State<ARExplorePage> createState() => _ARExplorePageState();
}

class _ARExplorePageState extends State<ARExplorePage> {
  int _selectedLandmarkIndex = 0;

  final List<Map<String, dynamic>> _landmarks = [
    {
      'name': 'Hawa Mahal',
      'type': 'Palace of Winds',
      'category': 'Rajput Architecture',
      'lat': 26.9239,
      'lng': 75.8267,
      'icon': Icons.account_balance_rounded,
      'description':
          'Built in 1799 by Maharaja Sawai Pratap Singh, featuring 953 intricately carved jharokhas (casements).',
      'timings': '9:00 AM – 5:00 PM',
      'entryFee': '₹50 (Indians) / ₹200 (Foreigners)',
    },
    {
      'name': 'Jantar Mantar',
      'type': 'UNESCO Astronomical Observatory',
      'category': 'Scientific Heritage',
      'lat': 26.9248,
      'lng': 75.8246,
      'icon': Icons.wb_sunny_outlined,
      'description':
          'Collection of 19 architectural astronomical instruments built by the Rajput king Sawai Jai Singh II.',
      'timings': '9:00 AM – 4:30 PM',
      'entryFee': '₹50 (Indians) / ₹200 (Foreigners)',
    },
    {
      'name': 'City Palace',
      'type': 'Royal Residence & Museum',
      'category': 'Palatial Complex',
      'lat': 26.9258,
      'lng': 75.8237,
      'icon': Icons.castle_rounded,
      'description':
          'Stunning blend of Rajasthani and Mughal architecture housing the Chandra Mahal and Mubarak Mahal.',
      'timings': '9:30 AM – 5:00 PM',
      'entryFee': '₹300 (Indians) / ₹700 (Foreigners)',
    },
    {
      'name': 'Amber Palace (Amer Fort)',
      'type': 'Hilltop Fortress',
      'category': 'UNESCO World Heritage',
      'lat': 26.9855,
      'lng': 75.8513,
      'icon': Icons.fort_rounded,
      'description':
          'Majestic fort known for artistic Hindu style elements overlooking Maota Lake.',
      'timings': '8:00 AM – 5:30 PM',
      'entryFee': '₹100 (Indians) / ₹500 (Foreigners)',
    },
  ];

  Future<void> _openNavigation(double lat, double lng, String name) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    HapticFeedback.lightImpact();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinates: $lat, $lng ($name)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openSearch(String name) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$name, Jaipur, Rajasthan')}',
    );
    HapticFeedback.lightImpact();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _landmarks[_selectedLandmarkIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF141A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141A1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HERITAGE WAYPOINTS',
              style: AppTypography.micro(
                color: AppColors.primary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Jaipur Historic Circuit',
              style: AppTypography.tripTitle(
                color: Colors.white,
              ).copyWith(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_rounded,
                  color: AppColors.teal,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_landmarks.length} SITES',
                  style: AppTypography.micro(
                    color: AppColors.teal,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Waypoint selection pill bar
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _landmarks.length,
              itemBuilder: (context, index) {
                final lm = _landmarks[index];
                final isSelected = index == _selectedLandmarkIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lm['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lm['name'] as String,
                          style: AppTypography.micro(
                            color: isSelected ? Colors.white : Colors.white70,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedLandmarkIndex = index);
                    },
                    backgroundColor: const Color(0xFF1E262E),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.white12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Visual Circuit Map / Waypoint Card Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main Waypoint Spotlight Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2228),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary.withAlpha(60),
                                  ),
                                ),
                                child: Icon(
                                  selected['icon'] as IconData,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.teal.withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (selected['category'] as String).toUpperCase(),
                                        style: AppTypography.micro(
                                          color: AppColors.teal,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selected['name'] as String,
                                      style: AppTypography.editorialTitle(
                                        color: Colors.white,
                                      ).copyWith(fontSize: 22),
                                    ),
                                    Text(
                                      selected['type'] as String,
                                      style: AppTypography.micro(
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),

                          Text(
                            selected['description'] as String,
                            style: AppTypography.bodyMedium(
                              color: Colors.white70,
                            ).copyWith(height: 1.4),
                          ),
                          const Spacer(),

                          // Quick facts
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141A1F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: AppColors.yellow,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Hours: ',
                                      style: AppTypography.caption(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        selected['timings'] as String,
                                        style: AppTypography.caption(
                                          color: Colors.white,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number_outlined,
                                      color: AppColors.teal,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Entry: ',
                                      style: AppTypography.caption(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        selected['entryFee'] as String,
                                        style: AppTypography.caption(
                                          color: Colors.white,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons: Navigate & View in Maps
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openSearch(
                                    selected['name'] as String,
                                  ),
                                  icon: const Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'EXPLORE',
                                    style: AppTypography.button(
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openNavigation(
                                    selected['lat'] as double,
                                    selected['lng'] as double,
                                    selected['name'] as String,
                                  ),
                                  icon: const Icon(
                                    Icons.navigation_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'DIRECTIONS',
                                    style: AppTypography.button(
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
