import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NavHubPage extends StatelessWidget {
  final Widget child;

  const NavHubPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      drawer: const NavDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('NaviiGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'DASHBOARD',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            _buildNavItem(context, 'Home', Icons.home_rounded, '/home', currentRoute),
            _buildNavItem(context, 'Upcoming Trips', Icons.calendar_today_rounded, '/upcoming-trips', currentRoute),
            _buildNavItem(context, 'Ongoing Trips', Icons.directions_run_rounded, '/ongoing-trips', currentRoute),
            _buildNavItem(context, 'Live Tracking', Icons.my_location_rounded, '/live-tracking', currentRoute),
            _buildNavItem(context, 'Analytics', Icons.bar_chart_rounded, '/analytics', currentRoute),

            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'EXPLORE',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            _buildNavItem(context, 'Hidden Gems', Icons.diamond_rounded, '/hidden-gems', currentRoute),
            _buildNavItem(context, 'Restaurants', Icons.restaurant_rounded, '/restaurants', currentRoute),
            _buildNavItem(context, 'Transportation', Icons.directions_transit_rounded, '/transportation', currentRoute),

            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'MY BOOKINGS',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            _buildNavItem(context, 'Saved Places', Icons.bookmark_rounded, '/saved-places', currentRoute),
            _buildNavItem(context, 'Payment History', Icons.receipt_long_rounded, '/payment-history', currentRoute),
            _buildNavItem(context, 'Digital passport', Icons.military_tech_rounded, '/digital-passport', currentRoute),

            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'MORE',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            _buildNavItem(context, 'Story Creator', Icons.movie_creation_rounded, '/story-creator', currentRoute),
            _buildNavItem(context, 'Settings', Icons.settings_rounded, '/settings', currentRoute),
            _buildNavItem(context, 'Help & Support', Icons.help_outline_rounded, '/help-support', currentRoute),
            _buildNavItem(context, 'Logout', Icons.logout_rounded, '/login', currentRoute, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String route, String currentRoute, {bool isLogout = false}) {
    final isSelected = currentRoute == route && !isLogout;
    final color = isLogout ? Colors.redAccent : (isSelected ? AppColors.primary : Colors.white70);

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withAlpha((0.1 * 255).round()),
      onTap: () {
        context.pop(); // Close drawer
        context.go(route);
      },
    );
  }
}
