import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required String route}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[400]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
      dense: true,
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.push(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              _buildSectionHeader('DASHBOARD'),
              _buildDrawerItem(context, icon: Icons.home_rounded, title: 'Home', route: '/home'),
              _buildDrawerItem(context, icon: Icons.calendar_today_rounded, title: 'Upcoming Trips', route: '/upcoming-trips'),
              _buildDrawerItem(context, icon: Icons.flight_takeoff_rounded, title: 'Ongoing Trips', route: '/ongoing-trips'),
              _buildDrawerItem(context, icon: Icons.location_on_rounded, title: 'Live Tracking', route: '/live-tracking'),
              _buildDrawerItem(context, icon: Icons.bar_chart_rounded, title: 'Analytics', route: '/analytics'),
              
              const Divider(color: Colors.white10),
              
              _buildSectionHeader('EXPLORE'),
              _buildDrawerItem(context, icon: Icons.diamond_rounded, title: 'Hidden Gems', route: '/hidden-gems'),
              _buildDrawerItem(context, icon: Icons.restaurant_rounded, title: 'Restaurants', route: '/restaurants'),
              _buildDrawerItem(context, icon: Icons.directions_bus_rounded, title: 'Transportation', route: '/transportation'),
              
              const Divider(color: Colors.white10),
              
              _buildSectionHeader('MY BOOKINGS'),
              _buildDrawerItem(context, icon: Icons.bookmark_border_rounded, title: 'Saved Places', route: '/saved-places'),
              _buildDrawerItem(context, icon: Icons.receipt_long_rounded, title: 'Payment History', route: '/payment-history'),
              _buildDrawerItem(context, icon: Icons.book_rounded, title: 'Digital passport', route: '/digital-passport'),
              
              const Divider(color: Colors.white10),
              
              _buildSectionHeader('MORE'),
              _buildDrawerItem(context, icon: Icons.video_library_rounded, title: 'Story Creator', route: '/story-creator'),
              _buildDrawerItem(context, icon: Icons.settings_rounded, title: 'Settings', route: '/settings'),
              _buildDrawerItem(context, icon: Icons.help_outline_rounded, title: 'Help & Support', route: '/help-support'),
              
              ListTile(
                leading: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
