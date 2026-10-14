import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../providers/user_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final profile = userProfileAsync.value;

    final displayName =
        profile?.displayName ?? currentUser?.displayName ?? 'Nomad Explorer';
    final email =
        profile?.email ?? currentUser?.email ?? 'signed.out@naviigo.com';
    final initials = profile?.initials ?? 'NV';
    final totalTrips = profile?.totalTrips ?? 0;
    final totalBookings = profile?.totalBookings ?? 0;

    const bgColor = Color(0xFFF8F9FA);
    const textDark = Color(0xFF24323A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const NavHubLeading(iconColor: textDark),
        title: const Text(
          'Profile & Account',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF632713),
                    backgroundImage:
                        (profile?.photoURL != null &&
                            profile!.photoURL!.isNotEmpty)
                        ? NetworkImage(profile.photoURL!)
                        : null,
                    child:
                        (profile?.photoURL == null ||
                            profile!.photoURL!.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFFFDE3CF),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEC6426,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NAVIIGO CLOUD SYNCED',
                            style: TextStyle(
                              color: Color(0xFFEC6426),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Real Metrics
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('$totalTrips', 'Total Trips'),
                  Container(width: 1, height: 36, color: Colors.grey[200]),
                  _buildMetric('$totalBookings', 'Bookings'),
                  Container(width: 1, height: 36, color: Colors.grey[200]),
                  _buildMetric('Active', 'Cloud Sync'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Links
            _buildSectionHeader('TRAVEL PASSPORT & MEMORIES'),
            _buildOptionTile(
              icon: Icons.card_travel_rounded,
              title: 'Digital Passport',
              subtitle: 'Stamps, XP level & visited regions',
              onTap: () => context.push('/digital-passport'),
            ),
            _buildOptionTile(
              icon: Icons.bookmark_border_rounded,
              title: 'Saved Places',
              subtitle: 'Bucket list items & monuments',
              onTap: () => context.push('/saved-places'),
            ),
            _buildOptionTile(
              icon: Icons.confirmation_number_outlined,
              title: 'Bookings & Wallet',
              subtitle: 'Transport tickets & hotel references',
              onTap: () => context.push('/bookings'),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('SECURITY & PREFERENCES'),
            _buildOptionTile(
              icon: Icons.tune_rounded,
              title: 'Travel preferences',
              subtitle: 'Travel style, interests and home city',
              onTap: () => context.push('/travel-preferences'),
            ),
            _buildOptionTile(
              icon: Icons.security_rounded,
              title: 'Safety & Trusted Contacts',
              subtitle: 'Emergency contacts & sharing settings',
              onTap: () => context.push('/help-support'),
            ),
            _buildOptionTile(
              icon: Icons.settings_outlined,
              title: 'Settings & Cache',
              subtitle: 'Offline data, notifications & preferences',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await signOutFrom(context, ref);
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF24323A),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEC6426).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFEC6426), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
