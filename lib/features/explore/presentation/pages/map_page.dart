import 'package:flutter/material.dart';
import 'dart:ui';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Hotels', 'Food', 'Sights', 'Transit'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117), // Dark premium map base
      body: Stack(
        children: [
          // Simulated Dark Map Background
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _DarkMapPainter(),
          ),
          
          // Map Markers
          Positioned(
            top: 200,
            left: 100,
            child: _buildGlowingMarker(Icons.hotel_rounded, const Color(0xFF2563EB)),
          ),
          Positioned(
            top: 350,
            left: 280,
            child: _buildGlowingMarker(Icons.restaurant_rounded, const Color(0xFFFF6B00)),
          ),
          Positioned(
            top: 150,
            left: 250,
            child: _buildGlowingMarker(Icons.camera_alt_rounded, const Color(0xFF059669)),
          ),
          Positioned(
            top: 450,
            left: 150,
            child: _buildClusterMarker('12'),
          ),

          // Top Gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF0F1117).withValues(alpha: 0.9), Colors.transparent],
                ),
              ),
            ),
          ),

          // Top Header & Search
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
                              const SizedBox(width: 12),
                              Text('Search anywhere...', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Map Filters
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF6B00) : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF6B00) : Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

          // Bottom Sheet Carousel
          Positioned(
            bottom: 100, // Above bottom nav
            left: 0,
            right: 0,
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildMapLocationCard('https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&w=600&q=80', 'Santorini Cliff', 'Sights • 1.2 km away', 4.9),
                _buildMapLocationCard('https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=600&q=80', 'Grand Resort', 'Hotels • 3.5 km away', 4.7),
                _buildMapLocationCard('https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=600&q=80', 'Ocean View Cafe', 'Food • 0.8 km away', 4.8),
              ],
            ),
          ),

          // Floating Action Buttons (My location, layers)
          Positioned(
            bottom: 300,
            right: 20,
            child: Column(
              children: [
                _buildFab(Icons.layers_rounded),
                const SizedBox(height: 12),
                _buildFab(Icons.near_me_rounded, isPrimary: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlowingMarker(IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          width: 2,
          height: 12,
          color: color,
        ),
      ],
    );
  }

  Widget _buildClusterMarker(String text) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildFab(IconData icon, {bool isPrimary = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFFF6B00) : const Color(0xFF1A1D2E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPrimary ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildMapLocationCard(String image, String title, String subtitle, double rating) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 14),
                            const SizedBox(width: 4),
                            Text('$rating', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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

class _DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // A stylized vector-like background representing a dark mode map
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Base landmass color
    paint.color = const Color(0xFF151824);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw "water" bodies
    paint.color = const Color(0xFF0F1117);
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width * 0.6, size.height * 0.5);
    path1.quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width, size.height * 0.6);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    canvas.drawPath(path1, paint);

    // Draw main roads
    paint.color = const Color(0xFF2A2E42);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    final road1 = Path();
    road1.moveTo(size.width * 0.1, 0);
    road1.quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.8, size.height);
    canvas.drawPath(road1, paint);

    final road2 = Path();
    road2.moveTo(size.width, size.height * 0.2);
    road2.quadraticBezierTo(size.width * 0.5, size.height * 0.3, 0, size.height * 0.8);
    canvas.drawPath(road2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
