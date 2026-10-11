class RecommendationModel {
  final String id;
  final String name;
  final List<String> reasons;
  final String? pitch;

  const RecommendationModel({
    required this.id,
    required this.name,
    this.reasons = const [],
    this.pitch,
  });

  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      reasons:
          (map['reasons'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      pitch: map['pitch']?.toString(),
    );
  }
}
