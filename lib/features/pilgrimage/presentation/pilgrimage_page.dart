import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/pilgrimage_pilot.dart';

class PilgrimagePage extends StatelessWidget {
  const PilgrimagePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pilgrimage journeys')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'A journey needs more than a plan.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Prepare before you leave, keep your journey together and know what to recheck when things change. Our pilgrimage pilot starts with five destinations, with Ujjain as our first field focus.',
        ),
        const SizedBox(height: 16),
        const _PreparationStatus(),
        const SizedBox(height: 20),
        for (final destination in pilgrimageDestinations)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(destination.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${destination.region}\n${destination.introduction}',
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/pilgrimage-pilot/${destination.id}'),
            ),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.push('/founder-travels'),
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Founder Travels · Kainchi Dham'),
        ),
      ],
    ),
  );
}

class PilgrimageDestinationPage extends StatelessWidget {
  final String destinationId;
  const PilgrimageDestinationPage({super.key, required this.destinationId});

  @override
  Widget build(BuildContext context) {
    final destination = findPilgrimageDestination(destinationId);
    if (destination == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pilgrimage journeys')),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/pilgrimage-pilot'),
            child: const Text('Choose a pilot destination'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(destination.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            destination.region,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Text(
            destination.introduction,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          const _PreparationStatus(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(
              '/trip-planner',
              extra: destination.plannerArguments,
            ),
            icon: const Icon(Icons.route_outlined),
            label: Text('Plan ${destination.destination.name}'),
          ),
          if (destination.id == 'mathura')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'The planner starts in Mathura. Confirm and arrange the Vrindavan leg separately.',
              ),
            ),
          const SizedBox(height: 24),
          _GuidanceSection(
            title: 'Before departure',
            items: destination.beforeDeparture,
          ),
          _GuidanceSection(
            title: 'During your journey',
            items: destination.duringJourney,
          ),
          _GuidanceSection(
            title: 'If plans change',
            items: [destination.ifPlansChange],
          ),
          const Text(
            'These are preparation prompts. Check current timings, access, availability and prices directly with official sources or the provider.',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.go('/trips'),
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('Open my saved trips'),
          ),
          TextButton(
            onPressed: () => context.push('/help-support'),
            child: const Text('Help and contact options'),
          ),
        ],
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  final String title;
  final List<String> items;
  const _GuidanceSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.checklist, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _PreparationStatus extends StatelessWidget {
  const _PreparationStatus();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Planning available · Assisted support preparing\nConfirmed pilot partners and support hours will appear here when available.',
      ),
    ),
  );
}

class FounderTravelsPage extends StatelessWidget {
  const FounderTravelsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Founder Travels')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'We travel with what we build.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        const Text('UPCOMING FIELD TEST · DIWALI 2026'),
        const SizedBox(height: 8),
        Text('Kainchi Dham', style: Theme.of(context).textTheme.headlineLarge),
        const Text('Uttarakhand, India'),
        const SizedBox(height: 16),
        const Text(
          'Our founder’s upcoming visit will help us test the support a traveller needs before departure, along the way and when plans change.',
        ),
        const SizedBox(height: 24),
        const _GuidanceSection(
          title: 'Before we leave · Preparing',
          items: [
            'Check the route, visiting information and travel arrangements. Keep confirmed details separate from open questions.',
          ],
        ),
        const _GuidanceSection(
          title: 'On the journey · Upcoming',
          items: [
            'Use NaviiGo and record where plans change or the traveller needs help.',
          ],
        ),
        const _GuidanceSection(
          title: 'What we learned · After the trip',
          items: [
            'Share dated observations, actual costs and the improvements made from the journey. The first trip report will appear after the visit.',
          ],
        ),
      ],
    ),
  );
}
