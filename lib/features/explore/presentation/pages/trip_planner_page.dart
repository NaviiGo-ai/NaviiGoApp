import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  double _budget = 10000;
  bool _isGenerating = false;

  void _generatePlan() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isGenerating = false);
    context.go('/trips');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Figma Light Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('NaviiGo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: _isGenerating 
        ? _buildLoadingState() 
        : _buildForm(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 24),
          Text(
            'AI is crafting your perfect journey...',
            style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF4A3428), height: 1.2, fontFamily: 'serif'), // Use a serif-like feeling for heading if possible, or bold brown.
              children: [
                TextSpan(text: 'Where will your\n'),
                TextSpan(text: 'curiosity', style: TextStyle(color: Color(0xFFFF6B00))),
                TextSpan(text: ' take\nyou?'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Destination Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2), // Light peach/beige
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              decoration: InputDecoration(
                icon: const Icon(Icons.location_on_rounded, color: Color(0xFFFF6B00), size: 20),
                hintText: 'Enter destination',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          
          // Dates
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF6B00), size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEPART', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                          const Text('Oct 24', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF6B00), size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RETURN', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                          const Text('Nov 02', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Budget Planner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BUDGET PLANNER', style: TextStyle(color: Color(0xFF6B4E3B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text('₹5000 - 15000', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Budget Range', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                Slider(
                  value: _budget,
                  min: 5000,
                  max: 15000,
                  activeColor: Colors.green,
                  inactiveColor: Colors.grey[300],
                  onChanged: (val) => setState(() => _budget = val),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _generatePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Generate Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Pill Toggles (Trending / Favorites)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D), // Light orange background for active pill
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('TRENDING', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('FAVORITES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Trending Journeys Placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trending Journeys', style: TextStyle(color: Color(0xFF4A3428), fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('VIEW ALL', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildTrendingCard('https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&q=80', 'Lorem Ipsum', '5 Days  •  ₹15,000'),
                _buildTrendingCard('https://images.unsplash.com/photo-1506744626753-1fa44df14c28?auto=format&fit=crop&q=80', 'Lorem Ipsum', '3 Days  •  ₹8,000'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          // Local Experiences Vertical List
          const Text('Local Experiences', style: TextStyle(color: Color(0xFF4A3428), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildLocalExperienceCard('https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&q=80', 'The Heritage Grande', 'Lorem ipsum dolor sit amet.', 4.5, 120, '\$420'),
          _buildLocalExperienceCard('https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&q=80', 'Aqua Marine Villas', 'Lorem ipsum dolor sit amet.', 4.8, 85, '\$380'),
          
          const SizedBox(height: 100), // Bottom nav padding
        ],
      ),
    );
  }

  Widget _buildTrendingCard(String url, String title, String subtitle) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D), // Yellowish orange
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('7 DAYS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalExperienceCard(String url, String title, String subtitle, double rating, int reviews, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const Icon(Icons.star_half_rounded, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text('($reviews)', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Text(price, style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
