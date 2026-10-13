import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../../core/motion/nav_haptics.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifications = true;
  bool _location = true;
  bool _savingAppearance = false;
  bool? _requestedAppearance;
  String? _appearanceError;

  Future<void> _saveAppearance(bool enabled) async {
    final uid = ref.read(currentUserProvider)?.uid;
    final preferences = ref.read(userPreferencesStreamProvider).valueOrNull;
    if (uid == null ||
        preferences == null ||
        preferences.sourceUserId != uid ||
        _savingAppearance) {
      return;
    }
    setState(() {
      _savingAppearance = true;
      _appearanceError = null;
      _requestedAppearance = enabled;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .updateUserPreferences(
            uid,
            preferences.copyWith(adaptiveAppearanceEnabled: enabled),
          )
          .timeout(const Duration(seconds: 15));
      ref.invalidate(userPreferencesStreamProvider);
    } catch (_) {
      if (mounted) {
        setState(
          () => _appearanceError =
              'Save not confirmed. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingAppearance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileStreamProvider).valueOrNull;
    final authUser = ref.watch(currentUserProvider);
    final preferences = authUser == null
        ? null
        : ref.watch(userPreferencesStreamProvider);

    final String displayName =
        (userProfile?.displayName != null &&
            userProfile!.displayName!.isNotEmpty)
        ? userProfile.displayName!
        : (authUser?.displayName ?? 'Naviigo Explorer');
    final String email =
        (userProfile?.email != null && userProfile!.email!.isNotEmpty)
        ? userProfile.email!
        : (authUser?.email ?? 'No email available');
    final String initials = userProfile?.initials ?? 'NV';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const NavHubLeading(iconColor: AppColors.brown),
        title: Text(
          'SETTINGS',
          style: AppTypography.editorialTitle(
            color: AppColors.brown,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Profile quick link card
          GestureDetector(
            onTap: () {
              NavHaptics.fire(NavHaptic.light);
              context.push('/profile');
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: AppTypography.editorialTitle(
                        color: Colors.white,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.tripTitle(
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: AppTypography.micro(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'EDIT',
                      style: AppTypography.micro(
                        color: AppColors.brown,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          _buildSectionHeader('PREFERENCES'),
          const SizedBox(height: 10),
          _buildSettingsBlock([
            SwitchListTile.adaptive(
              title: const Text('Adaptive Appearance'),
              subtitle: Text(
                _appearanceError ?? 'Subtle visual rhythm for your journey.',
              ),
              value:
                  preferences?.valueOrNull?.adaptiveAppearanceEnabled ?? true,
              onChanged: _savingAppearance || preferences?.valueOrNull == null
                  ? null
                  : _saveAppearance,
            ),
            if (_savingAppearance)
              const LinearProgressIndicator(
                semanticsLabel: 'Saving appearance',
              ),
            if (_appearanceError != null)
              TextButton(
                onPressed: () => _saveAppearance(_requestedAppearance!),
                child: const Text('Retry appearance save'),
              ),
            if (preferences?.hasError == true)
              TextButton(
                onPressed: () => ref.invalidate(userPreferencesStreamProvider),
                child: const Text('Retry preferences'),
              ),
            _buildDivider(),
            _buildToggleRow(
              'Push Notifications',
              Icons.notifications_outlined,
              _notifications,
              (val) {
                NavHaptics.fire(NavHaptic.light);
                setState(() => _notifications = val);
              },
            ),
            _buildDivider(),
            _buildToggleRow(
              'Location Services',
              Icons.location_on_outlined,
              _location,
              (val) {
                NavHaptics.fire(NavHaptic.light);
                setState(() => _location = val);
              },
            ),
          ]),
          const SizedBox(height: 28),

          _buildSectionHeader('ACCOUNT & WALLET'),
          const SizedBox(height: 10),
          _buildSettingsBlock([
            _buildLinkRow(
              'Personal Profile & Travel Style',
              Icons.person_outline_rounded,
              () => context.push('/profile'),
            ),
            _buildDivider(),
            _buildLinkRow(
              'Travel Wallet & Credits',
              Icons.account_balance_wallet_outlined,
              () => context.push('/payment-history'),
            ),
            _buildDivider(),
            _buildLinkRow(
              'Bookings & Offline Vouchers',
              Icons.confirmation_number_outlined,
              () => context.push('/bookings'),
            ),
          ]),
          const SizedBox(height: 28),

          _buildSectionHeader('SUPPORT & LEGAL'),
          const SizedBox(height: 10),
          _buildSettingsBlock([
            _buildLinkRow(
              'Help & Support Concierge',
              Icons.support_agent_rounded,
              () => context.push('/help-support'),
            ),
            _buildDivider(),
            _buildLinkRow(
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              () => _showLegalDialog(
                context,
                'Privacy Policy',
                'Naviigo is committed to protecting your travel telemetry, location privacy, and booking details. Your active tracking sessions are private, temporary, and shared only with your authorized Buddies.',
              ),
            ),
            _buildDivider(),
            _buildLinkRow(
              'Terms of Service',
              Icons.gavel_rounded,
              () => _showLegalDialog(
                context,
                'Terms of Service',
                'All bookings, itinerary generations, and wallet credits are governed by the Naviigo Platform Terms. Prices and external provider reservations are subject to partner confirmation.',
              ),
            ),
          ]),
          const SizedBox(height: 36),

          // Log Out Action
          Center(
            child: TextButton.icon(
              onPressed: () async {
                NavHaptics.fire(NavHaptic.light);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text(
                      'Log Out',
                      style: AppTypography.tripTitle(color: AppColors.brown),
                    ),
                    content: Text(
                      'Are you sure you want to log out of your Naviigo account?',
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: AppTypography.button(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text(
                          'Log Out',
                          style: AppTypography.button(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await signOutFrom(context, ref);
                }
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              label: Text(
                'Log Out of Naviigo',
                style: AppTypography.button(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: AppTypography.micro(
          color: AppColors.textSecondary,
        ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsBlock(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 52.0),
      child: Divider(color: AppColors.border, height: 1),
    );
  }

  Widget _buildToggleRow(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brown, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium(
                color: AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        NavHaptics.fire(NavHaptic.light);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brown, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: AppTypography.tripTitle(color: AppColors.brown),
        ),
        content: Text(
          content,
          style: AppTypography.bodyMedium(color: AppColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
