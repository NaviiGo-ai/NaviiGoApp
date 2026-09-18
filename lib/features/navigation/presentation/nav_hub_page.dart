import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/motion/nav_haptics.dart';
import '../../../core/motion/nav_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/auth/auth_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Scroll-driven chrome compaction (§4 / §60).
/// 0.0 = fully expanded, 1.0 = fully compacted. Pages drive this from a scroll
/// listener; the shell responds by tightening the bottom bar.
/// ─────────────────────────────────────────────────────────────────────────────
final navChromeCollapseProvider = StateProvider<double>((ref) => 0.0);

/// The shell's own [ScaffoldState].
///
/// The drawer lives on the shell so all 27 in-shell routes share one, but each
/// page nests its own [Scaffold] for its app bar — so `Scaffold.of(context)`
/// from inside a page resolves to that inner Scaffold, which has no drawer.
/// This key is how [NavHubLeading] reaches the real one.
final GlobalKey<ScaffoldState> navHubScaffoldKey = GlobalKey<ScaffoldState>();

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

const List<_NavDestination> _destinations = [
  _NavDestination(
    icon: Icons.cottage_outlined,
    activeIcon: Icons.cottage_rounded,
    label: 'Home',
    route: '/home',
  ),
  _NavDestination(
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
    label: 'Explore',
    route: '/explore-discover',
  ),
  _NavDestination(
    icon: Icons.alt_route_outlined,
    activeIcon: Icons.alt_route_rounded,
    label: 'Trips',
    route: '/trips',
  ),
  _NavDestination(
    icon: Icons.card_membership_outlined,
    activeIcon: Icons.card_membership_rounded,
    label: 'Passport',
    route: '/digital-passport',
  ),
  _NavDestination(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    route: '/profile',
  ),
];

class NavHubPage extends ConsumerStatefulWidget {
  final Widget child;

  const NavHubPage({super.key, required this.child});

  @override
  ConsumerState<NavHubPage> createState() => _NavHubPageState();
}

class _NavHubPageState extends ConsumerState<NavHubPage> {
  /// The last location the shell built for, so a route change can be told
  /// apart from a rebuild for any other reason.
  String? _lastPath;

  /// Which bottom-nav root owns the current location.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/explore') ||
        location.startsWith('/hidden-gems') ||
        location.startsWith('/restaurants') ||
        location.startsWith('/restaurant') ||
        location.startsWith('/transportation') ||
        location.startsWith('/local-guides') ||
        location.startsWith('/map') ||
        location.startsWith('/ar-explore') ||
        location.startsWith('/destination') ||
        location.startsWith('/place-details') ||
        location.startsWith('/places')) {
      return 1;
    }
    if (location.startsWith('/trips') ||
        location.startsWith('/itinerary') ||
        location.startsWith('/upcoming-trips') ||
        location.startsWith('/ongoing-trips') ||
        location.startsWith('/past-trips') ||
        location.startsWith('/live-tracking') ||
        location.startsWith('/trip-planner')) {
      return 2;
    }
    if (location.startsWith('/digital-passport') ||
        location.startsWith('/passport') ||
        location.startsWith('/saved-places') ||
        location.startsWith('/bookings') ||
        location.startsWith('/payment-history') ||
        location.startsWith('/story-creator')) {
      return 3;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/help-support')) {
      return 4;
    }
    return 0;
  }

  /// Settles the chrome, skipping the write when it is already there — a
  /// scroll emits this on every frame and the value only has two states.
  void _setChrome(double value) {
    if (ref.read(navChromeCollapseProvider) != value) {
      ref.read(navChromeCollapseProvider.notifier).state = value;
    }
  }

  /// A deliberate move — a tab tap, a drawer tap, any push into the shell —
  /// brings the chrome back. Without this the bar stays tight into the next
  /// screen, which has not been scrolled at all.
  void _restoreChromeOnRouteChange(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    if (path == _lastPath) return;
    _lastPath = path;

    // Post-frame, because build is not allowed to write a provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setChrome(0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    _restoreChromeOnRouteChange(context);

    final int currentIndex = _calculateSelectedIndex(context);
    final double collapse = ref.watch(navChromeCollapseProvider);

    return Scaffold(
      key: navHubScaffoldKey,
      backgroundColor: AppColors.background,
      // One drawer for every in-shell route. Without this the app had no
      // reachable navigation beyond the five bottom-nav roots.
      drawer: const NavDrawer(),
      body: NotificationListener<ScrollNotification>(
        // ── §4 / §60: scroll-driven chrome coordination ──────────────────────
        // Scrolling into the page tightens the bar so the content gets the
        // room; coming back up — or landing back at the top — returns it.
        // Only the vertical axis counts: swiping the destination carousel or
        // panning the map is not a reason to hide the navigation.
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;

          if (notification is UserScrollNotification) {
            // Intent, not position. This fires once per direction change and
            // routinely *before* the first pixel has moved — so it has to be
            // read on its own. Reordering it behind a position check is how
            // the bar ends up never collapsing on the first drag.
            switch (notification.direction) {
              case ScrollDirection.reverse:
                _setChrome(1.0);
              case ScrollDirection.forward:
                _setChrome(0.0);
              case ScrollDirection.idle:
                break; // Says nothing about intent.
            }
          } else if (notification is ScrollUpdateNotification &&
              notification.metrics.pixels <=
                  notification.metrics.minScrollExtent) {
            // Back at the top there is nothing left to recede from.
            _setChrome(0.0);
          }

          return false;
        },
        child: widget.child,
      ),
      bottomNavigationBar: _NavBottomBar(
        currentIndex: currentIndex,
        collapse: collapse,
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// BOTTOM NAVIGATION (§4)
///
/// The selection indicator travels between tabs rather than blinking on and
/// off — so switching roots reads as moving along the nav, not as five separate
/// buttons each toggling. Icons scale 6% (never a giant jump), labels settle,
/// and each tap gives a light haptic.
/// ─────────────────────────────────────────────────────────────────────────────
class _NavBottomBar extends StatelessWidget {
  final int currentIndex;
  final double collapse;

  const _NavBottomBar({required this.currentIndex, required this.collapse});

  @override
  Widget build(BuildContext context) {
    // Clamp before arithmetic so transient out-of-range provider values
    // (e.g. from rapid route changes) never produce pathological heights.
    final double safeCollapse = collapse.clamp(0.0, 1.0);
    // Expanded: 62 px — enough for icon + label.
    // Collapsed: 54 px — enough for icon only, never squeezes to zero.
    final double height = lerpDouble(62, 54, safeCollapse);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: height, end: height),
          duration: NavMotion.standard,
          curve: NavMotion.settle,
          builder: (context, h, _) {
            return SizedBox(
              height: h,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double itemWidth =
                      constraints.maxWidth / _destinations.length;

                  return Stack(
                    children: [
                      // Travelling selection indicator.
                      AnimatedPositioned(
                        duration: NavReduce.duration(
                          context,
                          NavMotion.standard,
                        ),
                        curve: NavMotion.settle,
                        left: (currentIndex * itemWidth) + (itemWidth - 48) / 2,
                        top: 6,
                        child: Container(
                          width: 48,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.cream.withAlpha(150),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (int i = 0; i < _destinations.length; i++)
                            _NavItem(
                              destination: _destinations[i],
                              isSelected: i == currentIndex,
                              // Pass the already-clamped value so _NavItem
                              // never receives values outside [0, 1].
                              collapse: safeCollapse,
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Linear interpolation without pulling in `dart:ui` just for `lerpDouble`.
  static double lerpDouble(double a, double b, double t) => a + ((b - a) * t);
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final double collapse;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.collapse,
  });

  @override
  Widget build(BuildContext context) {
    // collapse is already clamped by _NavBottomBar before being passed here,
    // but guard again in case _NavItem is ever instantiated directly.
    final double safeCollapse = collapse.clamp(0.0, 1.0);
    final Color color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: destination.label,
        child: InkWell(
          onTap: () {
            NavHaptics.fire(NavHaptic.light);
            // Already here — re-tapping a root should not rebuild the world.
            if (GoRouterState.of(context).uri.path != destination.route) {
              context.go(destination.route);
            }
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Flutter Web can briefly deliver pathologically small constraints
              // during route/browser-resize transitions. Bail out gracefully
              // instead of building an unconstrained Column that overflows.
              if (constraints.maxWidth < 24 || constraints.maxHeight < 24) {
                return const SizedBox.shrink();
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isSelected ? NavMotion.navIconScale : 1.0,
                    duration: NavReduce.duration(context, NavMotion.fast),
                    curve: NavMotion.response,
                    child: Icon(
                      isSelected ? destination.activeIcon : destination.icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                  // Label physically relinquishes layout height as nav collapses.
                  // ClipRect + Align(heightFactor) shrinks the bounding box to
                  // zero, so the Column stops allocating vertical space for the
                  // label even before opacity reaches 0. Opacity alone is NOT
                  // sufficient — it hides pixels but does not release height.
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 1.0 - safeCollapse,
                      child: AnimatedOpacity(
                        opacity: 1.0 - safeCollapse,
                        duration: NavReduce.duration(context, NavMotion.fast),
                        child: AnimatedDefaultTextStyle(
                          duration: NavReduce.duration(context, NavMotion.fast),
                          curve: NavMotion.response,
                          style: AppTypography.micro(color: color).copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 10.5,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(destination.label),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SHELL APP-BAR LEADING (§4)
///
/// Back when there is genuinely somewhere to go back to; otherwise the drawer,
/// because that is the only way to reach the routes the five roots don't cover.
/// ─────────────────────────────────────────────────────────────────────────────
class NavHubLeading extends StatelessWidget {
  final Color? iconColor;

  const NavHubLeading({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final Color color = iconColor ?? AppColors.textPrimary;

    // `context.canPop()` resolves through GoRouter.of(), which asserts that a
    // GoRouter ancestor exists. Pages are also built outside the router (widget
    // tests, embedded previews), so probe for it instead of assuming.
    final GoRouter? router = GoRouter.maybeOf(context);

    if (router != null && router.canPop()) {
      return IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: color),
        tooltip: 'Back',
        onPressed: () => router.pop(),
      );
    }

    return IconButton(
      icon: Icon(Icons.menu_rounded, color: color),
      tooltip: 'Open navigation',
      onPressed: () {
        final ScaffoldState? shell = navHubScaffoldKey.currentState;
        if (shell != null && shell.hasDrawer) {
          shell.openDrawer();
        } else {
          Scaffold.maybeOf(context)?.openDrawer();
        }
      },
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

                  const _DrawerDivider(),

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

                  const _DrawerDivider(),

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

                  const _DrawerDivider(),

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
      leading: AnimatedSwitcher(
        duration: NavReduce.duration(context, NavMotion.fast),
        child: Icon(
          icon,
          key: ValueKey('${icon.codePoint}_$isSelected'),
          color: color,
          size: 20,
        ),
      ),
      title: AnimatedDefaultTextStyle(
        duration: NavReduce.duration(context, NavMotion.fast),
        curve: NavMotion.response,
        style: AppTypography.bodyMedium(
          color: color,
        ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
        child: Text(title),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.cream.withAlpha(90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        NavHaptics.fire(NavHaptic.light);
        Navigator.of(context).pop();
        if (context.mounted) {
          context.go(route);
        }
      },
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(color: AppColors.border, height: 1),
    );
  }
}
