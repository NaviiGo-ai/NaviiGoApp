import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GeneratedItineraryPage extends StatelessWidget {
  const GeneratedItineraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5), // Light beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.go('/explore'),
        ),
        title: const Text('NaviiGo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          // Multiplayer Live Avatars
          SizedBox(
            width: 80,
            child: Stack(
              children: [
                Positioned(
                  right: 40,
                  top: 12,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80'),
                    child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.2, end: 0.2, duration: 2.seconds),
                ),
                Positioned(
                  right: 20,
                  top: 12,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=100&q=80'),
                    child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0.2, end: -0.2, duration: 2.seconds),
                ),
                Positioned(
                  right: 4,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black), 
            onPressed: () {},
          ).animate().shake(hz: 2, duration: 1.seconds, delay: 2.seconds),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text ABOVE image
            const Text('Santorini Escape', style: TextStyle(color: Color(0xFF8B4513), fontSize: 32, fontWeight: FontWeight.w900)).animate().fadeIn().slideX(),
            const SizedBox(height: 8),
            const Text('GREECE • 7 DAYS', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            
            // Hero Image Card
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&q=80'), // Santorini
                  fit: BoxFit.cover,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT EXPEDITION', style: TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Oia Sunsets', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 32),

            // Estimated Costs
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECDA), // Pale orange/peach
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: const Color(0xFFD67B45), size: 16),
                      const SizedBox(width: 8),
                      const Text('Estimated Costs', style: TextStyle(color: Color(0xFF6B4E3B), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.home_work_rounded, 'ACCOMMODATION', '€ 1,200'),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.directions_bus_rounded, 'TRANSPORTATION', '€ 300'),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.restaurant_rounded, 'FOOD AND DINING', '€ 800'),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.local_activity_rounded, 'ACTIVITIES', '€ 450'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Colors.black12),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL ESTIMATED', style: TextStyle(color: Color(0xFF6B4E3B), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('€ 2,750', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 48),

            // Interactive Expanding Timeline
            _buildExpandableDay(
              date: 'JUNE 10, 2024',
              title: 'Day 1: Arrival & Oia',
              description: 'Check in and watch the famous sunset.',
              initiallyExpanded: true,
              items: [
                _buildTimelineItem('10:00 AM', 'Check-in at Grand Resort', 'Drop off bags and freshen up.', 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&q=80'),
                _buildTimelineItem('02:30 PM', 'Oia Castle Walk', 'Head up to the castle ruins for the best sunset viewing spot.', 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&q=80', isLast: true),
              ],
            ),
            const SizedBox(height: 16),
            _buildExpandableDay(
              date: 'JUNE 11, 2024',
              title: 'Day 2: Caldera Cruise',
              description: 'Sail the volcanic islands.',
              initiallyExpanded: false,
              items: [
                _buildTimelineItem('09:00 AM', 'Catamaran Departure', 'Set sail from Ammoudi Bay.', 'https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&q=80'),
                _buildTimelineItem('01:00 PM', 'Volcano Hot Springs', 'Swim in the therapeutic sulfur waters.', 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&q=80', isLast: true),
              ],
            ),
            
            const SizedBox(height: 100), // Bottom nav padding
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B00),
        onPressed: () {},
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ).animate().scale(delay: 800.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCostRow(IconData icon, String label, String amount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEDACA), // Slightly darker tan for icon background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF8B4513), size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF6B4E3B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        Text(amount, style: const TextStyle(color: Color(0xFF8B4513), fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExpandableDay({
    required String date, 
    required String title, 
    required String description, 
    required List<Widget> items,
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        iconColor: const Color(0xFF8B4513),
        collapsedIconColor: const Color(0xFF8B4513),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Color(0xFF8B4513), fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(description, style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.5)),
        ),
        children: [
          const SizedBox(height: 24),
          ...items.animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1);
  }

  Widget _buildTimelineItem(String time, String title, String description, String imageUrl, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB74D),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 120, // Enough to connect to next
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                ),
              if (isLast)
                const SizedBox(height: 24),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Color(0xFF8B4513), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.black87, fontSize: 11, height: 1.5)),
                if (!isLast) const SizedBox(height: 32),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Thumbnail
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
