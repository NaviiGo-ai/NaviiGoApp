import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF0F4EF);
    final cardColor = Colors.white;
    final headerColor = const Color(0xFFE8EDE7);
    final rowBgColor = const Color(0xFFEAF0EA);
    final textDark = const Color(0xFF2D3A30);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () {},
        ),
        title: Text(
          'Profile',
          style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textDark, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF1E2420),
                        child: const Text('DK', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A866E),
                          shape: BoxShape.circle,
                          border: Border.all(color: headerColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Travel Stats
            Text('Travel Stats', style: TextStyle(color: textDark.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(Icons.flight_takeoff, '5', 'Total Trips', cardColor, const Color(0xFF4C6B52))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(Icons.location_on_outlined, '2', 'Places Visited', cardColor, const Color(0xFF4C6B52))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(Icons.emoji_events_outlined, '3', 'Badges Earned', cardColor, const Color(0xFF4C6B52))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(Icons.menu_book_outlined, '65%', 'Passport Progress', cardColor, const Color(0xFF4C6B52))),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('Saved Content', style: TextStyle(color: textDark.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildIconRow(Icons.favorite_border, 'Saved Destinations', '8', rowBgColor, textDark),
                  const SizedBox(height: 8),
                  _buildIconRow(Icons.calendar_today_outlined, 'Draft Itineraries', '3', rowBgColor, textDark),
                  const SizedBox(height: 8),
                  _buildIconRow(Icons.account_balance_outlined, 'Cultural Events', '12', rowBgColor, textDark),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Community & Sharing', style: TextStyle(color: textDark.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildListTile(Icons.book_outlined, 'Travel Diary', textDark),
                  const SizedBox(height: 8),
                  _buildListTile(Icons.share_outlined, 'Share on Social Media', textDark),
                  const SizedBox(height: 8),
                  _buildListTile(Icons.person_add_outlined, 'Invite Travel Buddy', textDark),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // My Rewards Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE9B7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, color: Color(0xFFB58017), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Rewards', style: TextStyle(color: Color(0xFF2D3A30), fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('View badges & achieve...', style: TextStyle(color: const Color(0xFF2D3A30).withValues(alpha: 0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD69A23),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('View All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Settings & Preferences', style: TextStyle(color: textDark.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildIconRowSetting(Icons.language, 'Language', 'English', rowBgColor, textDark),
                  const SizedBox(height: 8),
                  _buildIconRowSetting(Icons.attach_money, 'Currency', 'INR', rowBgColor, textDark),
                  const SizedBox(height: 8),
                  _buildIconRowSetting(Icons.accessibility_new, 'Accessibility', 'Standard', rowBgColor, textDark),
                  const SizedBox(height: 8),
                  _buildIconRowSetting(Icons.palette_outlined, 'Theme', 'Light', rowBgColor, textDark),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Emergency Contacts
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9DADB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_outlined, color: Color(0xFFDF4B50), size: 24),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency Contacts', style: TextStyle(color: Color(0xFFDF4B50), fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('SOS & Safety', style: TextStyle(color: const Color(0xFFDF4B50).withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            // Account Settings
            _buildSettingCard(Icons.security, 'Account Settings', 'Privacy & Security', cardColor, textDark),
            const SizedBox(height: 16),
            // Help & Support
            _buildSettingCard(Icons.help_outline, 'Help & Support', 'Contact us', cardColor, textDark),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Color(0xFF2D3A30), fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: const Color(0xFF2D3A30).withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildIconRow(IconData icon, String title, String badgeValue, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textC.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: textC, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: textC.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badgeValue, style: TextStyle(color: textC, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListTile(IconData icon, String title, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: textC.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textC.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: textC, fontSize: 14))),
          Icon(Icons.chevron_right, color: textC.withValues(alpha: 0.4), size: 20),
        ],
      ),
    );
  }
  
  Widget _buildIconRowSetting(IconData icon, String title, String value, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textC.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: textC, fontSize: 14))),
          Text(value, style: TextStyle(color: textC.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildSettingCard(IconData icon, String title, String subtitle, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: textC.withValues(alpha: 0.6), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textC, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: textC.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: textC.withValues(alpha: 0.4), size: 20),
        ],
      ),
    );
  }
}
