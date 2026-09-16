import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/models/user_preferences_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../../../core/motion/nav_haptics.dart';

class VibeMatchPage extends ConsumerStatefulWidget {
  const VibeMatchPage({super.key});

  @override
  ConsumerState<VibeMatchPage> createState() => _VibeMatchPageState();
}

class _VibeMatchPageState extends ConsumerState<VibeMatchPage> {
  static const List<String> _vibeIds = [
    'jaipur',
    'varanasi',
    'kerala',
    'ladakh',
  ];

  late final List<MasterDestination> _vibes = _vibeIds
      .map((id) => kMasterDestinations.where((d) => d.id == id).firstOrNull)
      .whereType<MasterDestination>()
      .toList();

  final Set<String> _likedIds = {};
  int _currentIndex = 0;
  bool _isLiked = false;
  bool _isPassed = false;
  bool _isCompleting = false;

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    _isCompleting = true;

    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid != null && _likedIds.isNotEmpty) {
        await ref
            .read(userRepositoryProvider)
            .updateUserPreferences(
              uid,
              UserPreferencesModel(interests: _likedIds.toList()),
            );
      }
    } catch (_) {
      // Non-blocking preference persistence
    } finally {
      if (mounted) {
        context.go('/home');
      }
    }
  }

  void _handleSwipe(bool liked) {
    if (_vibes.isEmpty) {
      context.go('/home');
      return;
    }

    NavHaptics.fire(NavHaptic.light);
    if (liked) {
      _likedIds.add(_vibes[_currentIndex].id);
    }

    setState(() {
      if (liked) {
        _isLiked = true;
      } else {
        _isPassed = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (_currentIndex < _vibes.length - 1) {
        setState(() {
          _currentIndex++;
          _isLiked = false;
          _isPassed = false;
        });
      } else {
        _completeOnboarding();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentVibe = _vibes[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIBE MATCH',
                        style: AppTypography.micro(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Curate Your Journey',
                        style: AppTypography.editorialTitle(
                          color: AppColors.brown,
                        ).copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Skip',
                      style: AppTypography.button(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  transform: Matrix4.translationValues(
                    _isLiked ? 80.0 : (_isPassed ? -80.0 : 0.0),
                    0.0,
                    0.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brown.withAlpha(18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            currentVibe.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceWarm,
                              child: const Icon(
                                Icons.terrain_rounded,
                                size: 64,
                                color: AppColors.border,
                              ),
                            ),
                          ),
                        ),
                        // Bottom Gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(50),
                                  Colors.black.withAlpha(200),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Vibe Information
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentVibe.category.toUpperCase(),
                                  style: AppTypography.micro(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentVibe.name,
                                style: AppTypography.editorialTitle(
                                  color: Colors.white,
                                ).copyWith(fontSize: 32),
                              ),
                              Text(
                                '${currentVibe.state} • Best Season: ${currentVibe.bestTime}',
                                style: AppTypography.bodySmall(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentVibe.description,
                                style: AppTypography.caption(
                                  color: Colors.white.withAlpha(220),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: () => _handleSwipe(false),
                  ),
                  _buildActionButton(
                    icon: Icons.favorite_rounded,
                    color: AppColors.primary,
                    isLarge: true,
                    onTap: () => _handleSwipe(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 68.0 : 54.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(80), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: isLarge ? 32 : 24),
      ),
    );
  }
}
