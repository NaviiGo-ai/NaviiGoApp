import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/firebase_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      final user = FirebaseClient.auth.currentUser;
      if (user != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle warm atmosphere corner tint
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cream.withAlpha(80),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Authentic Naviigo Brand Mark
                Image.asset(
                      'assets/brand/naviigo-mark-primary.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/brand/naviigo-mark-orange.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.easeOutCubic)
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 24),
                Text(
                      'NaviiGo',
                      style: AppTypography.displayHero(
                        color: AppColors.brown,
                      ).copyWith(fontSize: 34, letterSpacing: -0.5),
                    )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 6),
                Text(
                  'Every journey has a story.',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ).copyWith(letterSpacing: 0.2),
                ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
