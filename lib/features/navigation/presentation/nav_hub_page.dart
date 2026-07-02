import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NavHubPage extends StatelessWidget {
  final Widget child;

  const NavHubPage({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/explore') || location.startsWith('/restaurants')) return 2;
    if (location.startsWith('/trips')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/digital-passport')) return 4;
    return 0; // Default to Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/explore');
        break;
      case 3:
        context.go('/trips');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);
    final String location = GoRouterState.of(context).uri.path;
    final bool isLightMode = currentIndex == 2 || currentIndex == 3 || currentIndex == 4 || location.startsWith('/ongoing-trips'); // Explore, Trips, Profile, Ongoing Trips

    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2, context),
        backgroundColor: const Color(0xFFFF6B00), // Orange
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.explore, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          color: isLightMode ? Colors.white : const Color(0xFF1E1E1E),
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildNavItem(context, 0, Icons.home_filled, 'HOME', currentIndex, isLightMode),
                    const SizedBox(width: 24),
                    _buildNavItem(context, 1, Icons.map_rounded, 'MAP', currentIndex, isLightMode),
                  ],
                ),
                Row(
                  children: [
                    _buildNavItem(context, 3, Icons.flight_takeoff_rounded, 'TRIPS', currentIndex, isLightMode),
                    const SizedBox(width: 24),
                    _buildNavItem(context, 4, Icons.person, 'PROFILE', currentIndex, isLightMode),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, int currentIndex, bool isLightMode) {
    final bool isSelected = currentIndex == index;
    final Color selectedColor = const Color(0xFFFF6B00);
    final Color unselectedColor = isLightMode ? Colors.grey[400]! : Colors.grey;
    final Color color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
