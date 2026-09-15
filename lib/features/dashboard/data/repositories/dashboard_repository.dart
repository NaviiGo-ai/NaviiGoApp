import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/destination_model.dart';
import '../../domain/models/journal_article_model.dart';
import '../../domain/models/premium_itinerary_model.dart';
import '../../../../core/constants/master_destinations.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository(this._firestore);

  Stream<List<DestinationModel>> getTopDestinations() {
    return _firestore
        .collection('destinations')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs
                .map((doc) => DestinationModel.fromFirestore(doc))
                .toList();
          }
          return kMasterDestinations
              .take(8)
              .map((m) => DestinationModel.fromMaster(m))
              .toList();
        })
        .handleError((_) {
          return kMasterDestinations
              .take(8)
              .map((m) => DestinationModel.fromMaster(m))
              .toList();
        });
  }

  Stream<List<JournalArticleModel>> getJournalArticles() {
    return _firestore
        .collection('journal_articles')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs
                .map((doc) => JournalArticleModel.fromFirestore(doc))
                .toList();
          }
          return _defaultEditorialArticles();
        })
        .handleError((_) => _defaultEditorialArticles());
  }

  Stream<List<PremiumItineraryModel>> getPremiumItineraries() {
    return _firestore
        .collection('premium_itineraries')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PremiumItineraryModel.fromFirestore(doc))
              .toList();
        })
        .handleError((_) => <PremiumItineraryModel>[]);
  }

  List<JournalArticleModel> _defaultEditorialArticles() {
    return [
      JournalArticleModel(
        id: 'varanasi-dawn',
        title: 'Dawn on the Sacred Ghats of Varanasi',
        subtitle: 'Twilight chants and drifting boats along the sacred Ganga',
        tag: 'SPIRITUAL',
        author: 'Editorial Desk',
        readTime: '4 min read',
        image: kMasterDestinations.firstWhere((d) => d.id == 'varanasi').image,
        content:
            'As twilight breaks over the Ganga, wooden rowboats drift across the mist. The morning bells ring in rhythm with ancient Vedic chants.',
      ),
      JournalArticleModel(
        id: 'jaipur-terracotta',
        title: 'Beyond the Pink Facades of Jaipur',
        subtitle:
            'Secret courtyards and block-printing artisans of Johari Bazaar',
        tag: 'HERITAGE',
        author: 'Cultural Dispatch',
        readTime: '6 min read',
        image: kMasterDestinations.firstWhere((d) => d.id == 'jaipur').image,
        content:
            'Walking through Johari Bazaar at sunrise reveals block printers, gem polishers, and havelis untouched by modern hurry.',
      ),
    ];
  }
}
