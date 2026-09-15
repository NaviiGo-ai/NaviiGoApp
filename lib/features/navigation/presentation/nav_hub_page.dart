import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/auth/auth_provider.dart';

class NavHubPage extends ConsumerWidget {
  final Widget child;

  const NavHubPage({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/explore') ||
        location.startsWith('/explore-discover') ||
        location.startsWith('/hidden-gems') ||
        location.startsWith('/restaurants') ||
        location.startsWith('/transportation')) {
      return 1;
    }
    if (location.startsWith('/trips') ||
        location.startsWith('/itinerary') ||
        location.startsWith('/upcoming-trips') ||
        location.startsWith('/ongoing-trips') ||
        location.startsWith('/live-tracking') ||
        location.startsWith('/trip-planner')) {
      return 2;
    }
    if (location.startsWith('/digital-passport') ||
        location.startsWith('/passport') ||
        location.startsWith('/saved-places') ||
        location.startsWith('/bookings') ||
        location.startsWith('/payment-history')) {
      return 3;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/help-support')) {
      return 4;
    }
    return 0; // Default: Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/explore-discover');
        break;
      case 2:
        context.go('/trips');
        break;
      case 3:
        context.go('/digital-passport');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.cottage_outlined,
                  Icons.cottage_rounded,
                  'Home',
                  currentIndex,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.explore_outlined,
                  Icons.explore_rounded,
                  'Explore',
                  currentIndex,
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.alt_route_outlined,
                  Icons.alt_route_rounded,
                  'Trips',
                  currentIndex,
                ),
                _buildNavItem(
                  context,
                  3,
                  Icons.card_membership_outlined,
                  Icons.card_membership_rounded,
                  'Passport',
                  currentIndex,
                ),
                _buildNavItem(
                  context,
                  4,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profile',
                  currentIndex,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int currentIndex,
  ) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cream.withAlpha(120)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.micro(color: color).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavDrawer extends ConsumerWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header with Naviigo Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/brand/naviigo-mark-primary.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.navigation_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'NaviiGo',
                    style: AppTypography.editorialTitle(
                      color: AppColors.brown,
                    ).copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionHeader('JOURNEYS'),
                  _buildDrawerItem(
                    context,
                    'Home',
                    Icons.cottage_outlined,
                    '/home',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Upcoming Journeys',
                    Icons.calendar_today_rounded,
                    '/upcoming-trips',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Live Trip Companion',
                    Icons.navigation_rounded,
                    '/ongoing-trips',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Past Journeys',
                    Icons.history_rounded,
                    '/past-trips',
                    currentRoute,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.border, height: 1),
                  ),

                  _buildSectionHeader('DISCOVER'),
                  _buildDrawerItem(
                    context,
                    'Explore Atlas',
                    Icons.explore_outlined,
                    '/explore-discover',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Hidden Gems',
                    Icons.wb_twilight_rounded,
                    '/hidden-gems',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Local Dining',
                    Icons.restaurant_rounded,
                    '/restaurants',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Transit & Commute',
                    Icons.directions_transit_rounded,
                    '/transportation',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Certified Local Guides',
                    Icons.badge_outlined,
                    '/local-guides',
                    currentRoute,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.border, height: 1),
                  ),

                  _buildSectionHeader('TRAVEL WALLET'),
                  _buildDrawerItem(
                    context,
                    'Wallet & Credits',
                    Icons.account_balance_wallet_outlined,
                    '/payment-history',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Digital Passport',
                    Icons.card_membership_rounded,
                    '/digital-passport',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Saved Places',
                    Icons.bookmark_border_rounded,
                    '/saved-places',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Bookings & Vouchers',
                    Icons.confirmation_number_outlined,
                    '/bookings',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Story Creator',
                    Icons.auto_awesome_rounded,
                    '/story-creator',
                    currentRoute,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.border, height: 1),
                  ),

                  _buildSectionHeader('ACCOUNT'),
                  _buildDrawerItem(
                    context,
                    'Profile & Preferences',
                    Icons.person_outline_rounded,
                    '/profile',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Settings',
                    Icons.tune_rounded,
                    '/settings',
                    currentRoute,
                  ),
                  _buildDrawerItem(
                    context,
                    'Help & Support',
                    Icons.support_agent_rounded,
                    '/help-support',
                    currentRoute,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
              title: Text(
                'Log Out',
                style: AppTypography.button(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        title,
        style: AppTypography.eyebrow(
          color: AppColors.textTertiary,
        ).copyWith(fontSize: 10),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    String currentRoute,
  ) {
    final bool isSelected = currentRoute == route;
    final Color color = isSelected ? AppColors.primary : AppColors.textPrimary;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: AppTypography.bodyMedium(
          color: color,
        ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.cream.withAlpha(90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
