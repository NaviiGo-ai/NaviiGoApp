import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class TransportationPage extends StatefulWidget {
  const TransportationPage({super.key});

  @override
  State<TransportationPage> createState() => _TransportationPageState();
}

class _TransportationPageState extends State<TransportationPage> {
  int _selectedCategoryIndex =
      0; // 0: Cabs & Rides, 1: Trains & Rail, 2: Flights
  MasterDestination _selectedDestination = kMasterDestinations[1]; // Jaipur

  final List<String> _categories = [
    'CABS & RIDES',
    'TRAINS & RAIL',
    'FLIGHTS & AIR',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'TRANSIT & MOBILITY',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Destination Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESTINATION HUB',
                    style: AppTypography.micro(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MasterDestination>(
                    value: _selectedDestination,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: kMasterDestinations.map((dest) {
                      return DropdownMenuItem(
                        value: dest,
                        child: Text(
                          '${dest.name}, ${dest.state}',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDestination = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Segmented Control
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _categories[index],
                        style: AppTypography.eyebrow(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategoryIndex = index);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Category Content
            if (_selectedCategoryIndex == 0)
              _buildCabsSection()
            else if (_selectedCategoryIndex == 1)
              _buildTrainsSection()
            else
              _buildFlightsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCabsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOCAL RIDES & TAXIS',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Connect directly with certified drivers or open verified ride apps to your destination.',
          style: AppTypography.caption(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        _buildTransitProviderCard(
          title: 'Uber India',
          subtitle: 'City cabs, rentals & airport drops',
          badge: 'APP LAUNCH',
          icon: Icons.local_taxi_rounded,
          onTap: () async {
            final uri = Uri.parse(
              'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[formatted_address]=${Uri.encodeComponent(_selectedDestination.name)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        const SizedBox(height: 12),
        _buildTransitProviderCard(
          title: 'Ola Cabs & Autos',
          subtitle: 'Autos, Prime Sedans & Outstation',
          badge: 'APP LAUNCH',
          icon: Icons.electric_rickshaw,
          onTap: () async {
            final uri = Uri.parse(
              'https://book.olacabs.com/?pickup_name=Current%20Location&drop_name=${Uri.encodeComponent(_selectedDestination.name)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        const SizedBox(height: 12),
        _buildTransitProviderCard(
          title: 'Prepaid Local Taxi Stand',
          subtitle: 'Official railway station & airport fixed counter',
          badge: 'MAP LOCATOR',
          icon: Icons.local_shipping_outlined,
          onTap: () async {
            final target = _selectedDestination.station.isNotEmpty
                ? _selectedDestination.station
                : _selectedDestination.name;
            final uri = Uri.parse(
              'https://www.google.com/maps/search/prepaid+taxi+stand+near+${Uri.encodeComponent(target)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }

  Widget _buildTrainsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RAILWAY TRANSIT',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Primary Station: ${_selectedDestination.station} (${_selectedDestination.name} Junction)',
          style: AppTypography.caption(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        _buildTransitProviderCard(
          title: 'IRCTC Rail Connect',
          subtitle:
              'Book Vande Bharat, Rajdhani & Express trains to ${_selectedDestination.station}',
          badge: 'OFFICIAL PORTAL',
          icon: Icons.train_rounded,
          onTap: () async {
            final uri = Uri.parse('https://www.irctc.co.in/nget/train-search');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        const SizedBox(height: 12),
        _buildTransitProviderCard(
          title: 'Live Train Running Status',
          subtitle:
              'Track incoming trains to ${_selectedDestination.station} in real-time',
          badge: 'LIVE STATUS',
          icon: Icons.access_time_filled,
          onTap: () async {
            final target = _selectedDestination.station.isNotEmpty
                ? _selectedDestination.station
                : _selectedDestination.name;
            final uri = Uri.parse(
              'https://www.google.com/search?q=live+train+status+${Uri.encodeComponent(target)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }

  Widget _buildFlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FLIGHTS & AIR CONNECTIONS',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Nearest Airport: ${_selectedDestination.iata} (${_selectedDestination.name})',
          style: AppTypography.caption(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        _buildTransitProviderCard(
          title: 'Compare Airfares to ${_selectedDestination.iata}',
          subtitle:
              'Direct & connecting flights across Indigo, Air India & Vistara',
          badge: 'SEARCH & COMPARE',
          icon: Icons.flight_takeoff_rounded,
          onTap: () async {
            final target = _selectedDestination.iata.isNotEmpty
                ? _selectedDestination.iata
                : _selectedDestination.name;
            final uri = Uri.parse(
              'https://www.google.com/travel/flights?q=flights+to+${Uri.encodeComponent(target)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }

  Widget _buildTransitProviderCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.tripTitle(color: AppColors.textPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: AppTypography.micro(color: AppColors.primary),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
