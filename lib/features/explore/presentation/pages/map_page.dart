import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'Heritage',
    'Nature',
    'Spiritual',
    'Coastal',
  ];
  late PageController _pageController;
  int _activeCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<MasterDestination> get _filteredDestinations {
    if (_selectedFilter == 0) return kMasterDestinations;
    final selectedCategory = _filters[_selectedFilter];
    return kMasterDestinations
        .where(
          (d) => d.category.toLowerCase() == selectedCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _filteredDestinations;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Authentic warm topographic canvas map
          Positioned.fill(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _WarmIndiaMapPainter(),
            ),
          ),

          // Interactive Map Waypoints for India
          Positioned(
            top: 220,
            left: 140,
            child: _buildWaypointMarker(
              'Jaipur',
              Icons.fort_rounded,
              AppColors.primary,
              0,
            ),
          ),
          Positioned(
            top: 310,
            left: 240,
            child: _buildWaypointMarker(
              'Varanasi',
              Icons.temple_hindu_rounded,
              AppColors.secondary,
              1,
            ),
          ),
          Positioned(
            top: 430,
            left: 110,
            child: _buildWaypointMarker(
              'Goa',
              Icons.beach_access_rounded,
              AppColors.teal,
              2,
            ),
          ),
          Positioned(
            top: 500,
            left: 180,
            child: _buildWaypointMarker(
              'Kerala',
              Icons.water_rounded,
              AppColors.teal,
              3,
            ),
          ),

          // Top Header & Category Pills
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.brown,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.travel_explore_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NAVIIGO ROUTE ATLAS',
                                style: AppTypography.micro(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Explore Master Circuits',
                                style: AppTypography.caption(
                                  color: AppColors.brown,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmCream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${destinations.length} REGIONS',
                            style: AppTypography.micro(color: AppColors.brown),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Pills
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilter == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_filters[index]),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedFilter = index);
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
                ],
              ),
            ),
          ),

          // Floating Controls (External Google Maps & Center Navigation)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                _buildMapControl(
                  icon: Icons.open_in_new_rounded,
                  onTap: () async {
                    if (destinations.isEmpty) return;
                    final activeDest =
                        destinations[_activeCardIndex.clamp(0, destinations.length - 1)];
                    final uri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${activeDest.name}, ${activeDest.state}, India')}',
                    );
                    HapticFeedback.lightImpact();
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coordinates: ${activeDest.lat}, ${activeDest.lng}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildMapControl(
                  icon: Icons.navigation_rounded,
                  isPrimary: true,
                  onTap: () async {
                    if (destinations.isEmpty) return;
                    final activeDest =
                        destinations[_activeCardIndex.clamp(0, destinations.length - 1)];
                    final uri = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${activeDest.lat},${activeDest.lng}&travelmode=driving',
                    );
                    HapticFeedback.lightImpact();
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Route to ${activeDest.name}: ${activeDest.lat}, ${activeDest.lng}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom Destinations Carousel
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 190,
            child: destinations.isEmpty
                ? const SizedBox.shrink()
                : PageView.builder(
                    controller: _pageController,
                    itemCount: destinations.length,
                    onPageChanged: (i) => setState(() => _activeCardIndex = i),
                    itemBuilder: (context, index) {
                      final dest = destinations[index];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/destination/${dest.id}');
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: index == _activeCardIndex
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: index == _activeCardIndex ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brown.withAlpha(16),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(19),
                                ),
                                child: dest.image.startsWith('assets/')
                                    ? Image.asset(
                                        dest.image,
                                        width: 120,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                                      )
                                    : Image.network(
                                        dest.image,
                                        width: 120,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                                      ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.warmCream,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              dest.category.toUpperCase(),
                                              style: AppTypography.micro(
                                                color: AppColors.brown,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.star_rounded,
                                            color: AppColors.yellow,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            dest.rating.toStringAsFixed(1),
                                            style:
                                                AppTypography.caption(
                                                  color: AppColors.brown,
                                                ).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        dest.name,
                                        style: AppTypography.editorialTitle(
                                          color: AppColors.brown,
                                        ).copyWith(fontSize: 18),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${dest.state} • ${dest.iata}',
                                        style: AppTypography.micro(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        dest.description,
                                        style: AppTypography.caption(
                                          color: AppColors.textPrimary,
                                        ).copyWith(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointMarker(
    String title,
    IconData icon,
    Color color,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (_pageController.hasClients &&
            index < _filteredDestinations.length) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: AppTypography.caption(
                    color: AppColors.brown,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 8, color: color),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 120,
      color: AppColors.surfaceWarm,
      child: const Center(
        child: Icon(
          Icons.photo_library_outlined,
          color: AppColors.border,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown.withAlpha(16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.brown,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 120,
      color: AppColors.surfaceWarm,
      child: const Center(
        child: Icon(
          Icons.photo_library_outlined,
          color: AppColors.border,
          size: 32,
        ),
      ),
    );
  }
}

class _WarmIndiaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = const Color(0xFFFBF6F0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFEFE6DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Subtle editorial topographic lines
    for (double y = 80; y < size.height; y += 120) {
      final path = Path();
      path.moveTo(0, y);
      path.cubicTo(
        size.width * 0.3,
        y - 30,
        size.width * 0.7,
        y + 40,
        size.width,
        y,
      );
      canvas.drawPath(path, linePaint);
    }

    // River Ganga / Indus curve representation
    final riverPaint = Paint()
      ..color = AppColors.teal.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final riverPath = Path();
    riverPath.moveTo(size.width * 0.15, 120);
    riverPath.cubicTo(
      size.width * 0.4,
      200,
      size.width * 0.6,
      280,
      size.width * 0.9,
      340,
    );
    canvas.drawPath(riverPath, riverPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
