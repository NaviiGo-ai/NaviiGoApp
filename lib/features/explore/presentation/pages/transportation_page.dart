import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/network/api_provider.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

/// Planning ranges belong to NaviiGo; observed flight fares identify their source.
({int low, int high}) estimatedRideFare(
  double kilometres, {
  bool auto = false,
}) {
  final base = auto ? 30 : 60;
  final rate = auto ? 12 : 18;
  final low = math.max(base, (kilometres * rate).round());
  return (low: low, high: (low * 1.4).ceil());
}

class TransportationPage extends ConsumerStatefulWidget {
  const TransportationPage({super.key});
  @override
  ConsumerState<TransportationPage> createState() => _TransportationPageState();
}

class _TransportationPageState extends ConsumerState<TransportationPage> {
  int _tab = 0;
  MasterDestination _origin = findDestinationById('dehradun')!;
  MasterDestination _destination = findDestinationById('jaipur')!;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  double _kilometres = 5;
  Map<String, dynamic>? _flights;
  bool _loading = false;
  String? _error;
  int _request = 0;

  void _invalidate() {
    _request++;
    _flights = null;
    _error = null;
    _loading = false;
  }

  Future<void> _searchFlights() async {
    final request = ++_request;
    if (_origin.iata.isEmpty ||
        _destination.iata.isEmpty ||
        _origin.iata == _destination.iata) {
      setState(() => _error = 'Choose two different airports.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _flights = null;
    });
    try {
      final result = await ref
          .read(apiClientProvider)
          .get(
            '/api/transport/flights',
            timeout: const Duration(seconds: 30),
            requiresAuth: false,
            queryParams: {
              'origin': _origin.iata,
              'destination': _destination.iata,
              'date': _date.toIso8601String().split('T').first,
            },
          );
      if (!mounted || request != _request) return;
      if (result is! Map || result['results'] is! List) {
        throw const FormatException();
      }
      setState(() => _flights = Map<String, dynamic>.from(result));
    } catch (_) {
      if (mounted && request == _request) {
        setState(
          () => _error =
              'Flight prices are unavailable right now. Retry or check the airline.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this service. Please try again.'),
        ),
      );
    }
  }

  Widget _cityPicker(
    String label,
    MasterDestination selected,
    ValueChanged<MasterDestination> changed,
  ) => DropdownButtonFormField<MasterDestination>(
    value: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final d in kMasterDestinations)
        DropdownMenuItem(
          value: d,
          child: Text(
            '${d.name} (${_tab == 2 ? d.iata : d.station})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: (value) {
      if (value != null) {
        setState(() {
          changed(value);
          _invalidate();
        });
      }
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const NavHubLeading(),
      title: const Text('Transit'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Get there. Then get around.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final (index, label) in [
              (0, 'Rides'),
              (1, 'Trains'),
              (2, 'Flights'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _tab == index,
                onSelected: (_) => setState(() => _tab = index),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_tab != 0) ...[
          _cityPicker('From', _origin, (value) => _origin = value),
          const SizedBox(height: 12),
        ],
        _cityPicker('To', _destination, (value) => _destination = value),
        const SizedBox(height: 20),
        if (_tab == 0)
          ..._rides()
        else if (_tab == 1)
          ..._trains()
        else
          ..._flightWidgets(),
        const SizedBox(height: 24),
      ],
    ),
  );

  List<Widget> _rides() {
    final cab = estimatedRideFare(_kilometres);
    final auto = estimatedRideFare(_kilometres, auto: true);
    return [
      Text('Local ride distance: ${_kilometres.toStringAsFixed(1)} km'),
      Slider(
        value: _kilometres,
        min: 1,
        max: 50,
        divisions: 98,
        label: '${_kilometres.toStringAsFixed(1)} km',
        onChanged: (value) => setState(() => _kilometres = value),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NaviiGo planning estimates',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Auto rickshaw: ₹${auto.low}–₹${auto.high}'),
              Text('Cab: ₹${cab.low}–₹${cab.high}'),
              const SizedBox(height: 12),
              const Text(
                'Based on an assumed ₹12/km auto rate (₹30 minimum) and ₹18/km cab rate '
                '(₹60 minimum), with up to 40% variation. Not live Ola or Uber quotes. '
                'Surge, tolls, waiting and local tariffs can change the fare.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => _open(Uri.https('m.uber.com', '/')),
        child: const Text('Check Uber'),
      ),
      OutlinedButton(
        onPressed: () => _open(Uri.https('book.olacabs.com', '/')),
        child: const Text('Check Ola'),
      ),
    ];
  }

  List<Widget> _trains() => [
    Text(
      '${_origin.station} → ${_destination.station}',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 12),
    const Text(
      'Live schedules, seat availability and fares are not connected yet. '
      'NaviiGo needs an approved rail data provider before it can display verified results here.',
    ),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: () =>
          _open(Uri.parse('https://www.irctc.co.in/nget/train-search')),
      child: const Text('Check trains on IRCTC'),
    ),
    OutlinedButton(
      onPressed: () => _open(Uri.parse('https://enquiry.indianrail.gov.in/')),
      child: const Text('Live train status on NTES'),
    ),
  ];

  List<Widget> _flightWidgets() => [
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Departure date'),
      subtitle: Text(_date.toIso8601String().split('T').first),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final today = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(today.year, today.month, today.day),
          lastDate: today.add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          setState(() {
            _date = date;
            _invalidate();
          });
        }
      },
    ),
    FilledButton.icon(
      onPressed: _loading ? null : _searchFlights,
      icon: const Icon(Icons.search),
      label: Text(_loading ? 'Searching…' : 'Search flight prices'),
    ),
    if (_loading)
      const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
    if (_error != null)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(_error!),
      ),
    if (_flights != null) ...[
      const SizedBox(height: 16),
      Text(_flights!['notice']?.toString() ?? ''),
      Text(
        'Source: ${_flights!['source']} · Checked ${_flights!['observedAt']}',
      ),
      if ((_flights!['results'] as List).isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No fares returned for this route and date.'),
        ),
      for (final item in (_flights!['results'] as List).whereType<Map>())
        Card(
          child: ListTile(
            title: Text('${item['airline']} · ₹${item['price']}'),
            subtitle: Text(
              '${item['departure']} → ${item['arrival']}\n'
              '${item['stops']} stops · ${item['durationMinutes']} min',
            ),
            isThreeLine: true,
          ),
        ),
    ],
    const SizedBox(height: 12),
    OutlinedButton(
      onPressed: () => _open(
        Uri.https('www.google.com', '/travel/flights', {
          'q':
              'one way flights from ${_origin.iata} to ${_destination.iata} on ${_date.toIso8601String().split('T').first}',
        }),
      ),
      child: const Text('Check availability and book'),
    ),
  ];
}
