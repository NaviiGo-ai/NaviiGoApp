import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DigitalPassportPage extends StatelessWidget {
  const DigitalPassportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Digital Passport', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 3D Globe Passport Header
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Spinning Globe Image (simulated 3D)
                  ClipOval(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A), // Deep ocean blue
                      ),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1614729939124-03290b5609ce?auto=format&fit=crop&w=800&q=80', // Earth map
                        fit: BoxFit.cover,
                      ).animate(onPlay: (c) => c.repeat()).moveX(begin: -200, end: 0, duration: 20.seconds, curve: Curves.linear),
                    ),
                  ),
                  // Spherical Shading Overlay for 3D effect
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                        stops: const [0.5, 1.0],
                        center: const Alignment(-0.3, -0.3),
                        radius: 0.8,
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                    ),
                  ),
                  
                  // Level Badge floating on globe
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1B2D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 16),
                          SizedBox(width: 8),
                          Text('Explorer Level 5', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Passport Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('12', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Stamps', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[200]),
                  Column(
                    children: [
                      const Text('8', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Countries', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[200]),
                  Column(
                    children: [
                      const Text('24', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Cities', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(),
            const SizedBox(height: 28),

            // Stamps Collection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stamp Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('12/30', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStamp('🇮🇳', 'India', true),
                _buildStamp('🇯🇵', 'Japan', true),
                _buildStamp('🇫🇷', 'France', true),
                _buildStamp('🇦🇪', 'UAE', true),
                _buildStamp('🇮🇹', 'Italy', true),
                _buildStamp('🇮🇩', 'Indonesia', true),
                _buildStamp('🇬🇷', 'Greece', true),
                _buildStamp('🇹🇭', 'Thailand', true),
                _buildStamp('🇪🇸', 'Spain', false),
                _buildStamp('🇧🇷', 'Brazil', false),
                _buildStamp('🇦🇺', 'Australia', false),
                _buildStamp('🇲🇽', 'Mexico', false),
              ],
            ),
            const SizedBox(height: 28),

            const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildAchievementCard(Icons.flight_takeoff_rounded, 'First Flight', 'Took your first trip', const Color(0xFF2563EB), true),
                  _buildAchievementCard(Icons.terrain_rounded, 'Peak Climber', 'Visited 3 mountains', const Color(0xFF059669), true),
                  _buildAchievementCard(Icons.restaurant_rounded, 'Foodie Explorer', 'Tried 10 local dishes', const Color(0xFFFF6B00), true),
                  _buildAchievementCard(Icons.camera_alt_rounded, 'Shutterbug', 'Captured 500+ photos', const Color(0xFF8B5CF6), false),
                  _buildAchievementCard(Icons.public_rounded, 'Globe Trotter', 'Visited 10 countries', const Color(0xFFDC2626), false),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildActivityItem('Stamp earned: Kyoto, Japan', '2 weeks ago', Icons.bookmark_added_rounded, const Color(0xFFFF6B00)),
            _buildActivityItem('Achievement unlocked: Peak Climber', '1 month ago', Icons.emoji_events_rounded, const Color(0xFF059669)),
            _buildActivityItem('Stamp earned: Tuscany, Italy', '2 months ago', Icons.bookmark_added_rounded, const Color(0xFF2563EB)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStamp(String emoji, String country, bool unlocked) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? const Color(0xFFFFF3E0) : Colors.grey[200],
            border: Border.all(
              color: unlocked ? const Color(0xFFFF6B00) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              unlocked ? emoji : '🔒',
              style: TextStyle(fontSize: unlocked ? 24 : 18),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          country,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: unlocked ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(IconData icon, String title, String subtitle, Color color, bool unlocked) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? color.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? color.withValues(alpha: 0.3) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: unlocked ? color : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: unlocked ? Colors.black87 : Colors.grey)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: unlocked ? Colors.grey[600] : Colors.grey[400]), maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
        ],
      ),
    );
  }
}

class _PassportStat extends StatelessWidget {
  final String value;
  final String label;
  const _PassportStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
