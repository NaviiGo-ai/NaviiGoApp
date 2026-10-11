import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPlaceModel {
  final String id;
  final String name;
  final String type;
  final String? image;
  final String? location;
  final DateTime? createdAt;

  /// In-memory stream provenance. Never persisted to Firestore.
  final String? sourceUserId;

  const SavedPlaceModel({
    required this.id,
    required this.name,
    required this.type,
    this.image,
    this.location,
    this.createdAt,
    this.sourceUserId,
  });

  factory SavedPlaceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SavedPlaceModel(
      id: doc.id,
      name: (data['name'] ?? 'Saved Place').toString(),
      type: (data['type'] ?? 'Destination').toString(),
      image: data['image'] as String?,
      location: data['location'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  SavedPlaceModel copyWith({String? sourceUserId}) => SavedPlaceModel(
    id: id,
    name: name,
    type: type,
    image: image,
    location: location,
    createdAt: createdAt,
    sourceUserId: sourceUserId ?? this.sourceUserId,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (image != null) 'image': image,
      if (location != null) 'location': location,
    };
  }
}
