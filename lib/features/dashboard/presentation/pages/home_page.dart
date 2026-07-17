import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/hero_destination_card.dart';
import '../widgets/explore_categories.dart';
import '../widgets/top_destinations_list.dart';
import '../widgets/whats_new_card.dart';
import '../widgets/journal_section.dart';
import '../widgets/premium_itineraries_list.dart';
import '../widgets/newsletter_card.dart';
import '../../../navigation/presentation/widgets/custom_drawer.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../../ai/presentation/widgets/voice_assistant_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showVoiceAI = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: HomeAppBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                const SliverToBoxAdapter(child: HeroDestinationCard()),
                SliverToBoxAdapter(child: ExploreCategories()),
                SliverToBoxAdapter(child: TopDestinationsList()),
                const SliverToBoxAdapter(child: WhatsNewCard()),
                SliverToBoxAdapter(child: JournalSection()),
                SliverToBoxAdapter(child: PremiumItinerariesList()),
                const SliverToBoxAdapter(child: NewsletterCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Padding for bottom nav bar
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
          ),
          
          // AI Voice Orb
          Positioned(
            bottom: 32,
            right: 24,
            child: GestureDetector(
              onTap: () {
                setState(() => _showVoiceAI = true);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor, Colors.orangeAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2000.ms),
            ),
          ),
          
          // Voice Assistant Overlay
          if (_showVoiceAI)
            Positioned.fill(
              child: VoiceAssistantOverlay(
                onClose: () {
                  setState(() => _showVoiceAI = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}
