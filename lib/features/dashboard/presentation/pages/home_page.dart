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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      body: SafeArea(
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
        ),
      ),
    );
  }
}
