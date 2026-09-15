import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;

class VoiceAssistantOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const VoiceAssistantOverlay({super.key, required this.onClose});

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Deep Blur Background
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Voice Interface
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "I'm listening...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
                  const SizedBox(height: 16),
                  const Text(
                    "Try saying: 'Find a vegan place near me'",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: -0.2),
                  const SizedBox(height: 80),

                  // Glowing Orb Animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildWaveRing(1.0 + (_controller.value * 0.5), 0.1),
                          _buildWaveRing(
                            1.2 +
                                (math.sin(_controller.value * math.pi * 2) *
                                    0.3),
                            0.3,
                          ),
                          _buildWaveRing(
                            1.5 +
                                (math.cos(_controller.value * math.pi * 2) *
                                    0.4),
                            0.5,
                          ),

                          // Core Orb
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.5),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.8),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate().scale(
                    delay: 200.ms,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

                  const SizedBox(height: 120),

                  // Close Button
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveRing(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: opacity),
            width: 4,
          ),
        ),
      ),
    );
  }
}
