import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/models/user_preferences_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';

class OnboardingWizardPage extends ConsumerStatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  ConsumerState<OnboardingWizardPage> createState() =>
      _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  final List<String> _styles = [
    'Backpacker',
    'Luxury',
    'Foodie',
    'Adventure',
    'Culture',
    'Relaxation',
    'Nightlife',
    'Nature',
  ];
  final Set<String> _selectedStyles = {};
  bool _isSaving = false;

  Future<void> _handleContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid != null && _selectedStyles.isNotEmpty) {
        await ref
            .read(userRepositoryProvider)
            .updateUserPreferences(
              uid,
              UserPreferencesModel(interests: _selectedStyles.toList()),
            );
      }
    } catch (_) {
      // Non-blocking preference persistence
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        context.go('/vibe-match');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/vibe-match'),
            child: Text(
              'Skip',
              style: AppTypography.button(
                color: AppColors.textSecondary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is your travel style?',
                style: AppTypography.editorialTitle(
                  color: AppColors.brown,
                ).copyWith(fontSize: 32, height: 1.2),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
              const SizedBox(height: 12),
              Text(
                'Select at least 3 styles to personalize your curated itineraries.',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              const SizedBox(height: 40),

              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: _styles.map((style) {
                  final isSelected = _selectedStyles.contains(style);
                  return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedStyles.remove(style);
                            } else {
                              _selectedStyles.add(style);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            style,
                            style: AppTypography.bodyMedium(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .scale(begin: const Offset(0.8, 0.8));
                }).toList(),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedStyles.length >= 3 && !_isSaving
                      ? _handleContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.border,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continue to Vibe Match',
                          style: AppTypography.button(color: Colors.white),
                        ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
