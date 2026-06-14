import 'package:cloud_firestore/cloud_firestore.dart';

class JournalArticleModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String tag;

  JournalArticleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.tag,
  });

  factory JournalArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalArticleModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      image: data['image'] ?? '',
      tag: data['tag'] ?? '',
    );
  }
}
