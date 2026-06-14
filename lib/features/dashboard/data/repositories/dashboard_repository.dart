import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/destination_model.dart';
import '../../domain/models/journal_article_model.dart';
import '../../domain/models/premium_itinerary_model.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository(this._firestore);

  Stream<List<DestinationModel>> getTopDestinations() {
    return _firestore.collection('destinations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DestinationModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<JournalArticleModel>> getJournalArticles() {
    return _firestore.collection('journal_articles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => JournalArticleModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<PremiumItineraryModel>> getPremiumItineraries() {
    return _firestore.collection('premium_itineraries').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PremiumItineraryModel.fromFirestore(doc)).toList();
    });
  }
}
