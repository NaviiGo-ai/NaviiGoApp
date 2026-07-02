import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text ABOVE image
            const Text('Lorem Ipsum', style: TextStyle(color: Color(0xFF8B4513), fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'serif')),
            const SizedBox(height: 8),
            const Text('LOREM IPSUM • 7 DAYS', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Hero Image Card
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&q=80'),
                  fit: BoxFit.cover,
                ),
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
                        Text('Lorem Ipsum Dolor', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  _buildCostRow(Icons.home_work_rounded, 'ACCOMMODATION', '₹ 6000'),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.directions_bus_rounded, 'TRANSPORTATION', '₹ 3000'),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.restaurant_rounded, 'FOOD AND DINING', '₹ 4000'),
                  const SizedBox(height: 16),
                  _buildCostRow(Icons.local_activity_rounded, 'ACTIVITIES', '₹ 2000'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Colors.black12),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL ESTIMATED', style: TextStyle(color: Color(0xFF6B4E3B), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('₹ 15000', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Timeline
            _buildTimelineDay('JUNE 10, 2024', 'Day 1: Lorem\nIpsum & Dolor Sit', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
            const SizedBox(height: 24),
            _buildTimelineItem('10:00 AM', 'Check-in at Lorem Ipsum', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor.', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&q=80'),
            _buildTimelineItem('02:30 PM', 'Lorem Ipsum Walk to Place', 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80'),
            
            const SizedBox(height: 48),
            _buildTimelineDay('JUNE 11, 2024', 'Day 2: Lorem\nIpsum Tour', 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'),
            const SizedBox(height: 24),
            _buildTimelineItem('09:00 AM', 'Private Lorem Ipsum', 'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'https://images.unsplash.com/photo-1518998053401-a28c4bb1c850?auto=format&fit=crop&q=80'),
            
            const SizedBox(height: 48),
            _buildTimelineDay('JUNE 12, 2024', 'Day 3: Lorem\nIpsum Exploration', 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.'),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push('/restaurants'),
              child: _buildTimelineItem('01:00 PM', 'Lunch at Lorem Ipsum (Tap for Nearby)', 'Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.', 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&q=80'),
            ),
            
            const SizedBox(height: 100), // Bottom nav padding
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B00),
        onPressed: () {},
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
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

  Widget _buildTimelineDay(String date, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(date, style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Color(0xFF8B4513), fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'serif', height: 1.1)),
        const SizedBox(height: 12),
        Text(description, style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.5)),
      ],
    );
  }

  Widget _buildTimelineItem(String time, String title, String description, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB74D),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 100,
                color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
              ),
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
                Text(title, style: const TextStyle(color: Color(0xFF8B4513), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.black87, fontSize: 10, height: 1.5)),
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
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
