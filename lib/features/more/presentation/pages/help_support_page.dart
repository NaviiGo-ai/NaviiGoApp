import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // AI Chat Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, const Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('NaviiGo AI Assistant', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('How can we help you today?', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('Start a Chat', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 16),

          _buildFaqItem('How do I cancel my hotel booking?', 'You can cancel your booking directly from the Payment History page by selecting the booking and tapping "Cancel". Note that cancellation policies depend on the provider.'),
          const SizedBox(height: 12),
          _buildFaqItem('Can I use NaviiGo offline?', 'Yes! You can download your itineraries and map areas for offline use. Go to Settings > Travel Documents to manage your offline data.'),
          const SizedBox(height: 12),
          _buildFaqItem('How is my carbon footprint calculated?', 'We calculate it based on your transportation modes, distances traveled, and standard industry emission factors for flights, trains, and cars.'),
          const SizedBox(height: 12),
          _buildFaqItem('What is a Digital Passport?', 'The Digital Passport is a gamified record of your travels! You earn stamps and badges for visiting new places and completing trips.'),
          
          const SizedBox(height: 40),
          Center(
            child: Text('Still need help?', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('support@naviigo.com', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF2D3142),
          collapsedIconColor: Colors.grey,
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2D3142))),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
