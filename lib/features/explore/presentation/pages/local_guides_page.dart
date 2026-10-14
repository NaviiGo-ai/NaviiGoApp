import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class LocalGuidesPage extends StatefulWidget {
  const LocalGuidesPage({super.key});
  @override
  State<LocalGuidesPage> createState() => _LocalGuidesPageState();
}

class _LocalGuidesPageState extends State<LocalGuidesPage> {
  MasterDestination _destination = kMasterDestinations.first;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const NavHubLeading(),
      title: const Text('Local guides'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DropdownButtonFormField<MasterDestination>(
          value: _destination,
          decoration: const InputDecoration(labelText: 'Destination'),
          items: [
            for (final d in kMasterDestinations)
              DropdownMenuItem(value: d, child: Text(d.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _destination = value);
          },
        ),
        const SizedBox(height: 32),
        const Icon(Icons.person_search_rounded, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Meet the people who know the place.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'NaviiGo does not have onboarded guide listings yet. '
          'Explore local providers on the map, then check their credentials, '
          'reviews and availability directly.',
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          icon: const Icon(Icons.map_outlined),
          label: Text('Find guides in ${_destination.name}'),
          onPressed: () async {
            final opened = await launchUrl(
              Uri.https('www.google.com', '/maps/search/', {
                'api': '1',
                'query': 'tour guides in ${_destination.name}',
              }),
              mode: LaunchMode.externalApplication,
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open the map. Please try again.'),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}
