import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ARExplorePage extends StatefulWidget {
  const ARExplorePage({super.key});

  @override
  State<ARExplorePage> createState() => _ARExplorePageState();
}

class _ARExplorePageState extends State<ARExplorePage> {
  final List<Map<String, dynamic>> _landmarks = [
    {
      'name': 'Hawa Mahal',
      'distance': '450m',
      'bearing': '34° NNE',
      'type': 'Palace of Winds',
      'icon': Icons.account_balance_rounded,
      'top': 200.0,
      'left': 40.0,
    },
    {
      'name': 'Jantar Mantar',
      'distance': '820m',
      'bearing': '72° ENE',
      'type': 'Solar Observatory',
      'icon': Icons.wb_sunny_outlined,
      'top': 360.0,
      'right': 40.0,
    },
    {
      'name': 'City Palace',
      'distance': '1.1km',
      'bearing': '115° ESE',
      'type': 'Royal Residence',
      'icon': Icons.castle_rounded,
      'bottom': 260.0,
      'left': 80.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2228),
      body: Stack(
        children: [
          // Camera canvas simulation
          Positioned.fill(
            child: Container(
              color: const Color(0xFF141A1F),
              child: CustomPaint(painter: _HorizonCompassPainter()),
            ),
          ),

          // Top Navigation HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NAVIIGO LIVE COMPASS',
                        style: AppTypography.micro(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Jaipur Heritage Circuit',
                        style: AppTypography.tripTitle(
                          color: Colors.white,
                        ).copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.teal),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sensors_rounded,
                          color: AppColors.teal,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HUD ACTIVE',
                          style: AppTypography.micro(
                            color: AppColors.teal,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Central Reticle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // AR Landmark Overlays
          ..._landmarks.map((lm) {
            return Positioned(
              top: lm['top'] as double?,
              bottom: lm['bottom'] as double?,
              left: lm['left'] as double?,
              right: lm['right'] as double?,
              child: _buildLandmarkBadge(lm),
            );
          }),

          // Bottom telemetry bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearest Stop: Hawa Mahal',
                          style: AppTypography.caption(
                            color: AppColors.brown,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Point your camera towards northeast to align waypoint.',
                          style: AppTypography.micro(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '34° NNE',
                      style: AppTypography.micro(
                        color: AppColors.brown,
                      ).copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildLandmarkBadge(Map<String, dynamic> lm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(lm['icon'] as IconData, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lm['name'] as String,
                style: AppTypography.caption(
                  color: AppColors.brown,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${lm['type']} • ${lm['distance']}',
                style: AppTypography.micro(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizonCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    // Center crosshair guidelines
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    // Compass degree ticks
    final tickPaint = Paint()
      ..color = AppColors.teal.withAlpha(80)
      ..strokeWidth = 1.5;

    final centerY = size.height * 0.15;
    for (double x = 40; x < size.width; x += 30) {
      canvas.drawLine(
        Offset(x, centerY - 6),
        Offset(x, centerY + 6),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
