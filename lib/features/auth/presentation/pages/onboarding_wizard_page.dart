import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/vibe-match'),
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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
              const Text(
                'What is your travel style?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3142),
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
              const SizedBox(height: 12),
              const Text(
                'Select at least 3 styles so our AI can personalize your itineraries.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            style,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2D3142),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                  onPressed: _selectedStyles.length >= 3
                      ? () => context.go('/vibe-match')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    'Continue to Vibe Match',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
