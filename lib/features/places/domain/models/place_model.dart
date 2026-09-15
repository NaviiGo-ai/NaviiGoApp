class PlaceModel {
  final String id;
  final String name;
  final double rating;
  final int userRatingsTotal;
  final int? priceLevel;
  final String vicinity;
  final double? lat;
  final double? lng;
  final bool? isOpen;
  final List<String> types;
  final String? photoUrl;
  final String? description;
  final String? phone;
  final String? website;

  const PlaceModel({
    required this.id,
    required this.name,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    this.priceLevel,
    this.vicinity = '',
    this.lat,
    this.lng,
    this.isOpen,
    this.types = const [],
    this.photoUrl,
    this.description,
    this.phone,
    this.website,
  });

  factory PlaceModel.fromBackendJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    String? resolvedPhoto = json['photo'] as String?;
    if (resolvedPhoto != null &&
        resolvedPhoto.startsWith('/') &&
        baseUrl != null) {
      resolvedPhoto = '$baseUrl$resolvedPhoto';
    }

    return PlaceModel(
      id: (json['id'] ?? json['placeId'] ?? json['place_id'] ?? '').toString(),
      name: (json['name'] ?? json['description'] ?? 'Unnamed Place').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingsTotal: (json['userRatingsTotal'] as num?)?.toInt() ?? 0,
      priceLevel: (json['priceLevel'] as num?)?.toInt(),
      vicinity:
          (json['vicinity'] ??
                  json['address'] ??
                  json['shortFormattedAddress'] ??
                  '')
              .toString(),
      lat:
          (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble(),
      lng:
          (json['lng'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble(),
      isOpen: json['isOpen'] as bool?,
      types:
          (json['types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photoUrl: resolvedPhoto,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'priceLevel': priceLevel,
      'vicinity': vicinity,
      'lat': lat,
      'lng': lng,
      'isOpen': isOpen,
      'types': types,
      'photoUrl': photoUrl,
      'description': description,
      'phone': phone,
      'website': website,
    };
  }
}
