import 'package:cloud_firestore/cloud_firestore.dart';

class JournalArticleModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String tag;
  final String author;
  final String readTime;
  final String content;

  const JournalArticleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.tag,
    this.author = 'NaviiGo Editorial',
    this.readTime = '4 min read',
    this.content = '',
  });

  factory JournalArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return JournalArticleModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      image: data['image'] ?? '',
      tag: data['tag'] ?? 'CULTURE',
      author: data['author'] ?? 'NaviiGo Editorial',
      readTime: data['readTime'] ?? '4 min read',
      content: data['content'] ?? data['body'] ?? '',
    );
  }
}
