import '../../../core/constants/master_destinations.dart';

/// Preparation questions, not verified operational advice or partner offers.
class PilgrimageDestination {
  final String id;
  final String title;
  final String region;
  final String introduction;
  final List<String> beforeDeparture;
  final List<String> duringJourney;
  final String ifPlansChange;

  const PilgrimageDestination({
    required this.id,
    required this.title,
    required this.region,
    required this.introduction,
    required this.beforeDeparture,
    required this.duringJourney,
    required this.ifPlansChange,
  });

  MasterDestination get destination => findDestinationById(id)!;

  Map<String, String> get plannerArguments => {
    'destination': id,
    'purpose': 'spiritual',
  };
}

const pilgrimageDestinations = <PilgrimageDestination>[
  PilgrimageDestination(
    id: 'ujjain',
    title: 'Ujjain',
    region: 'Madhya Pradesh',
    introduction:
        'Our first field focus. Build your journey around darshan, comfortable transfers and time to pause.',
    beforeDeparture: [
      'Confirm Mahakaleshwar visiting arrangements, any booking requirements and the exact entrance with an official source.',
      'Agree on walking tolerance, rest stops and transport needs with everyone travelling.',
      'Confirm the stay address and arrival arrangements directly with the property.',
    ],
    duringJourney: [
      'Recheck visiting arrangements before setting out. Keep booking confirmations accessible.',
      'Leave room for queues, meals and rest rather than packing every hour.',
    ],
    ifPlansChange:
        'Reorder your saved plan around the confirmed visiting window. Confirm any replacement ride or stay before paying.',
  ),
  PilgrimageDestination(
    id: 'varanasi',
    title: 'Varanasi',
    region: 'Uttar Pradesh',
    introduction:
        'Make space for the ghats, temple visits and the practicalities of moving through the city.',
    beforeDeparture: [
      'Confirm temple visiting arrangements and the meeting point for any booked service.',
      'Ask your stay about vehicle access, luggage handling and the walk from the drop-off point.',
      'For a boat outing, confirm the operator, current operating conditions and the full price directly.',
    ],
    duringJourney: [
      'Check current local conditions before a river outing and allow time for crowded approaches.',
      'Keep a shared meeting point and a return route for your group.',
    ],
    ifPlansChange:
        'Keep a land-based alternative if a river outing cannot operate. Reconfirm transport rather than relying on an old quote.',
  ),
  PilgrimageDestination(
    id: 'mathura',
    title: 'Mathura–Vrindavan',
    region: 'Uttar Pradesh',
    introduction:
        'Begin your plan in Mathura. Arrange Vrindavan visits and the transfer between the two separately.',
    beforeDeparture: [
      'Choose the temples you want to visit and confirm their current visiting windows.',
      'Confirm the Mathura–Vrindavan transfer, drop-off point and return arrangement.',
      'Allow separate time for meals, walking and rest across the two places.',
    ],
    duringJourney: [
      'Recheck the next visiting window before travelling between Mathura and Vrindavan.',
      'Keep the group meeting point and transport contact accessible.',
    ],
    ifPlansChange:
        'Prioritise one confirmed visit and move the others. The generated starting-city plan does not guarantee a two-city transport connection.',
  ),
  PilgrimageDestination(
    id: 'dwarka',
    title: 'Dwarka',
    region: 'Gujarat',
    introduction:
        'Plan the main visit first, then confirm the details of any onward excursion.',
    beforeDeparture: [
      'Confirm Dwarkadhish visiting arrangements with a current official source.',
      'Check the exact address and contact for your stay; similar business names can refer to different properties.',
      'Confirm travel time, the full quote and return arrangements for any onward visit.',
    ],
    duringJourney: [
      'Recheck onward transport and local operating conditions before leaving your base.',
      'Keep time for the return journey and a rest break.',
    ],
    ifPlansChange:
        'Keep the main-city visit as a fallback. Reconfirm an onward excursion before making a new payment.',
  ),
  PilgrimageDestination(
    id: 'puri',
    title: 'Puri / Jagannath',
    region: 'Odisha',
    introduction:
        'Bring the temple visit, arrival transfer and family needs into one practical plan.',
    beforeDeparture: [
      'Confirm current Jagannath temple entry and visiting requirements through an official source.',
      'Check the stay location, arrival transfer and the walking distance your group can manage.',
      'Confirm meal arrangements and any assistance directly with the provider.',
    ],
    duringJourney: [
      'Recheck local visiting guidance and keep the group meeting point clear.',
      'Allow time for queues and rest; confirm any additional coastal outing separately.',
    ],
    ifPlansChange:
        'Move nonessential outings around the confirmed temple visit. Ask the provider to confirm the revised arrangement and cost.',
  ),
];

PilgrimageDestination? findPilgrimageDestination(String id) {
  for (final destination in pilgrimageDestinations) {
    if (destination.id == id) return destination;
  }
  return null;
}
