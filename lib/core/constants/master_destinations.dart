/// Master Destination Registry
/// Single source of truth synchronized with Naviigo Website (Frontend/lib/constants/destinations.ts)
class MasterDestination {
  final String id;
  final String name;
  final String state;
  final String iata;
  final String station;
  final double lat;
  final double lng;
  final String image;
  final String category;
  final double rating;
  final String bestTime;
  final String description;

  const MasterDestination({
    required this.id,
    required this.name,
    required this.state,
    required this.iata,
    required this.station,
    required this.lat,
    required this.lng,
    required this.image,
    required this.category,
    required this.rating,
    required this.bestTime,
    this.description = '',
  });
}

const List<MasterDestination> kMasterDestinations = [
  MasterDestination(
    id: 'varanasi',
    name: 'Varanasi',
    state: 'Uttar Pradesh',
    iata: 'VNS',
    station: 'BSB',
    lat: 25.3176,
    lng: 82.9739,
    image: 'assets/brand/varanasi-dawn-hero.jpg',
    category: 'Spiritual',
    rating: 4.9,
    bestTime: 'Oct - Mar',
    description:
        'The world’s oldest living city. Twilight Ganga Aarti, sacred ghats, and labyrinthine silk-weaving alleys.',
  ),
  MasterDestination(
    id: 'jaipur',
    name: 'Jaipur',
    state: 'Rajasthan',
    iata: 'JAI',
    station: 'JP',
    lat: 26.9124,
    lng: 75.7873,
    image: 'assets/brand/jaipur-heritage.jpg',
    category: 'Heritage',
    rating: 4.8,
    bestTime: 'Nov - Feb',
    description:
        'The Pink City of royalty. Hawa Mahal, Amer Fort atop sunlit hills, and royal astronomical marvels.',
  ),
  MasterDestination(
    id: 'goa',
    name: 'Goa',
    state: 'Goa',
    iata: 'GOI',
    station: 'MAO',
    lat: 15.2993,
    lng: 74.1240,
    image: 'assets/brand/kerala-backwaters.jpg',
    category: 'Coastal',
    rating: 4.7,
    bestTime: 'Nov - Feb',
    description:
        'Golden palm-fringed coastlines, Portuguese colonial architecture, quiet spice plantations, and sea breezes.',
  ),
  MasterDestination(
    id: 'kochi',
    name: 'Kochi',
    state: 'Kerala',
    iata: 'COK',
    station: 'ERS',
    lat: 9.9312,
    lng: 76.2673,
    image: 'assets/brand/kerala-backwaters.jpg',
    category: 'Coastal',
    rating: 4.8,
    bestTime: 'Sep - Mar',
    description:
        'The Queen of the Arabian Sea. Cantilevered Chinese fishing nets, spice bazaars, and tranquil backwaters.',
  ),
  MasterDestination(
    id: 'udaipur',
    name: 'Udaipur',
    state: 'Rajasthan',
    iata: 'UDR',
    station: 'UDZ',
    lat: 24.5854,
    lng: 73.7125,
    image: 'assets/brand/jaipur-heritage.jpg',
    category: 'Heritage',
    rating: 4.9,
    bestTime: 'Oct - Mar',
    description:
        'City of shimmering lakes and marble palaces. Lake Pichola boat journeys and Jag Mandir courtyard sunsets.',
  ),
  MasterDestination(
    id: 'agra',
    name: 'Agra',
    state: 'Uttar Pradesh',
    iata: 'AGR',
    station: 'AGC',
    lat: 27.1767,
    lng: 78.0081,
    image: 'assets/brand/jaipur-heritage.jpg',
    category: 'Heritage',
    rating: 4.9,
    bestTime: 'Oct - Mar',
    description:
        'Mughal grandeur along the Yamuna River. Taj Mahal at dawn, Agra Fort red-sandstone corridors, and Mehtab Bagh.',
  ),
  MasterDestination(
    id: 'rishikesh',
    name: 'Rishikesh',
    state: 'Uttarakhand',
    iata: 'DED',
    station: 'HW',
    lat: 30.0869,
    lng: 78.2676,
    image: 'assets/brand/rishikesh-foothills.jpg',
    category: 'Adventure',
    rating: 4.8,
    bestTime: 'Sep - Apr',
    description:
        'Yoga capital cradled by Himalayan foothills. River rafting rapids, suspension bridges, and cliffside cafes.',
  ),
  MasterDestination(
    id: 'manali',
    name: 'Manali',
    state: 'Himachal Pradesh',
    iata: 'KUU',
    station: 'CDG',
    lat: 32.2432,
    lng: 77.1892,
    image: 'assets/brand/rishikesh-foothills.jpg',
    category: 'Mountains',
    rating: 4.7,
    bestTime: 'Oct - Jun',
    description:
        'Snow-clad peaks and fragrant pine forests. Solang Valley alpine meadows and old cedar temples.',
  ),
  MasterDestination(
    id: 'amritsar',
    name: 'Amritsar',
    state: 'Punjab',
    iata: 'ATQ',
    station: 'ASR',
    lat: 31.6340,
    lng: 74.8723,
    image: '',
    category: 'Spiritual',
    rating: 4.9,
    bestTime: 'Oct - Mar',
    description:
        'Golden serenity. The illuminated Harmandir Sahib, communal langar kitchen, and vibrant Punjabi streets.',
  ),
  MasterDestination(
    id: 'mumbai',
    name: 'Mumbai',
    state: 'Maharashtra',
    iata: 'BOM',
    station: 'CSMT',
    lat: 19.0760,
    lng: 72.8777,
    image: '',
    category: 'Metropolis',
    rating: 4.6,
    bestTime: 'Nov - Feb',
    description:
        'Colonial Gothic architecture, Marine Drive sunset promenades, seaside art deco, and bustling Irani cafes.',
  ),
  MasterDestination(
    id: 'delhi',
    name: 'Delhi',
    state: 'Delhi',
    iata: 'DEL',
    station: 'NDLS',
    lat: 28.6139,
    lng: 77.2090,
    image: '',
    category: 'Metropolis',
    rating: 4.7,
    bestTime: 'Oct - Mar',
    description:
        'Centuries of empire layered in stone. Humayun’s Tomb gardens, Chandni Chowk street food, and Lodhi art district.',
  ),
  MasterDestination(
    id: 'bangalore',
    name: 'Bangalore',
    state: 'Karnataka',
    iata: 'BLR',
    station: 'SBC',
    lat: 12.9716,
    lng: 77.5946,
    image: '',
    category: 'Metropolis',
    rating: 4.6,
    bestTime: 'Sep - Feb',
    description:
        'The Garden City of coffee and leafy canopy boulevards. Cubbon Park mornings and artisan craft breweries.',
  ),
  MasterDestination(
    id: 'chennai',
    name: 'Chennai',
    state: 'Tamil Nadu',
    iata: 'MAA',
    station: 'MAS',
    lat: 13.0827,
    lng: 80.2707,
    image: '',
    category: 'Heritage',
    rating: 4.5,
    bestTime: 'Nov - Feb',
    description:
        'Gateway to Southern culture. Filter coffee, classical Carnatic sabhas, and ancient Kapaleeshwarar Dravidian towers.',
  ),
  MasterDestination(
    id: 'kolkata',
    name: 'Kolkata',
    state: 'West Bengal',
    iata: 'CCU',
    station: 'HWH',
    lat: 22.5726,
    lng: 88.3639,
    image: '',
    category: 'Heritage',
    rating: 4.7,
    bestTime: 'Oct - Feb',
    description:
        'City of Joy. Victoria Memorial gardens, yellow ambassador cabs, Howrah Bridge silhouettes, and College Street bookstores.',
  ),
  MasterDestination(
    id: 'hyderabad',
    name: 'Hyderabad',
    state: 'Telangana',
    iata: 'HYD',
    station: 'SC',
    lat: 17.3850,
    lng: 78.4867,
    image: '',
    category: 'Heritage',
    rating: 4.7,
    bestTime: 'Oct - Mar',
    description:
        'City of Pearls and Nizami heritage. Charminar bazaars, Golconda acoustic fortresses, and fragrant dum biryani.',
  ),
  MasterDestination(
    id: 'madurai',
    name: 'Madurai',
    state: 'Tamil Nadu',
    iata: 'IXM',
    station: 'MDU',
    lat: 9.9252,
    lng: 78.1198,
    image: '',
    category: 'Spiritual',
    rating: 4.8,
    bestTime: 'Oct - Mar',
    description:
        'The Athens of the East. Meenakshi Amman Temple’s towering gopurams and midnight jasmine street markets.',
  ),
  MasterDestination(
    id: 'haridwar',
    name: 'Haridwar',
    state: 'Uttarakhand',
    iata: 'DED',
    station: 'HW',
    lat: 29.9457,
    lng: 78.1642,
    image: '',
    category: 'Spiritual',
    rating: 4.9,
    bestTime: 'Oct - Apr',
    description:
        'Gateway to the Gods. Har Ki Pauri stepped ghats, floating diyas on the sacred Ganga, and evening bell chimes.',
  ),
  MasterDestination(
    id: 'tirupati',
    name: 'Tirupati',
    state: 'Andhra Pradesh',
    iata: 'TIR',
    station: 'TPTY',
    lat: 13.6288,
    lng: 79.4192,
    image: '',
    category: 'Spiritual',
    rating: 4.9,
    bestTime: 'Sep - Mar',
    description:
        'Sacred Seven Hills of Venkatadri. Venkateswara Temple pilgrimage paths, dawn chants, and prasadam offerings.',
  ),
];

MasterDestination? findDestinationById(String idOrName) {
  final clean = idOrName.toLowerCase().trim();
  for (final d in kMasterDestinations) {
    if (d.id == clean || d.name.toLowerCase() == clean) {
      return d;
    }
  }
  return null;
}
