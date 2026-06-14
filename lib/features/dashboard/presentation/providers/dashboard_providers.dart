import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/models/destination_model.dart';
import '../../domain/models/journal_article_model.dart';
import '../../domain/models/premium_itinerary_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(FirebaseFirestore.instance);
});

final topDestinationsProvider = StreamProvider<List<DestinationModel>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getTopDestinations();
});

final journalArticlesProvider = StreamProvider<List<JournalArticleModel>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getJournalArticles();
});

final premiumItinerariesProvider = StreamProvider<List<PremiumItineraryModel>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getPremiumItineraries();
});
