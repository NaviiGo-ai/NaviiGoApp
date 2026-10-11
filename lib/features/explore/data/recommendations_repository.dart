import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/master_destinations.dart';
import '../domain/models/recommendation_model.dart';

class RecommendationsRepository {
  final ApiClient _apiClient;

  RecommendationsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<RecommendationModel>> getRecommendations({
    required User user,
    required List<String> interests,
    String? group,
  }) async {
    final preferences = <String, dynamic>{
      if (interests.isNotEmpty) 'interests': interests,
    };
    final response = await _apiClient.post(
      '/api/recommendations/',
      body: {
        // This Website route does not verify body UID ownership. Its stateless
        // mode uses explicit inputs only, without reading any stored account.
        if (group != null && group.isNotEmpty) 'group': group,
        if (preferences.isNotEmpty) 'preferences': preferences,
      },
      expectedAuthUid: user.uid,
    );
    if (response is! Map || response['recommendations'] is! List) {
      throw const FormatException('Recommendations unavailable');
    }
    return (response['recommendations'] as List)
        .whereType<Map>()
        .map(
          (item) =>
              RecommendationModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((item) => findDestinationById(item.id) != null)
        .toList();
  }
}
