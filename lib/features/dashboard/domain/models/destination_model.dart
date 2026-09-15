import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/master_destinations.dart';

class DestinationModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final double rating;
  final String category;
  final String bestTime;
  final String description;

  const DestinationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.rating,
    this.category = 'Heritage',
    this.bestTime = '',
    this.description = '',
  });

  factory DestinationModel.fromMaster(MasterDestination master) {
    return DestinationModel(
      id: master.id,
      title: master.name,
      subtitle: master.state,
      image: master.image,
      rating: master.rating,
      category: master.category,
      bestTime: master.bestTime,
      description: master.description,
    );
  }

  factory DestinationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DestinationModel(
      id: doc.id,
      title: data['title'] ?? data['name'] ?? '',
      subtitle: data['subtitle'] ?? data['state'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] is num)
          ? (data['rating'] as num).toDouble()
          : 4.8,
      category: data['category'] ?? 'Heritage',
      bestTime: data['bestTime'] ?? '',
      description: data['description'] ?? '',
    );
  }
}
