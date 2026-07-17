import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class VibeMatchPage extends StatefulWidget {
  const VibeMatchPage({super.key});

  @override
  State<VibeMatchPage> createState() => _VibeMatchPageState();
}

class _VibeMatchPageState extends State<VibeMatchPage> {
  final List<String> _images = [
    'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=800&q=80', // Taj
    'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=800&q=80', // Beach
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80', // Mountains
    'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=800&q=80', // London City
  ];

  int _currentIndex = 0;
  bool _isLiked = false;
  bool _isPassed = false;

  void _handleSwipe(bool liked) {
    setState(() {
      if (liked) {
        _isLiked = true;
      } else {
        _isPassed = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_currentIndex < _images.length - 1) {
        setState(() {
          _currentIndex++;
          _isLiked = false;
          _isPassed = false;
        });
      } else {
        // Done with Vibe Match, go to Home
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117), // Dark aesthetic for images
      body: Stack(
        children: [
          // Background blurred image
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.network(
                _images[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vibe Match',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                
                const Text(
                  'Swipe right if this is your vibe.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Card Stack Simulation
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Next card (underneath)
                        if (_currentIndex < _images.length - 1)
                          Transform.scale(
                            scale: 0.95,
                            child: Transform.translate(
                              offset: const Offset(0, 20),
                              child: _buildCard(_images[_currentIndex + 1]),
                            ),
                          ),
                        
                        // Current Card (Animated on Swipe)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          left: _isPassed ? -400 : (_isLiked ? 400 : 0),
                          child: AnimatedRotation(
                            turns: _isPassed ? -0.05 : (_isLiked ? 0.05 : 0),
                            duration: const Duration(milliseconds: 300),
                            child: _buildCard(_images[_currentIndex]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(Icons.close_rounded, Colors.red, () => _handleSwipe(false)),
                    const SizedBox(width: 32),
                    _buildActionButton(Icons.favorite_rounded, Colors.green, () => _handleSwipe(true)),
                  ],
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Icon(icon, color: color, size: 40),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOut);
  }
}
