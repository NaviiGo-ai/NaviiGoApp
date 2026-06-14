import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final double rating;

  DestinationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.rating,
  });

  factory DestinationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DestinationModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }
}
