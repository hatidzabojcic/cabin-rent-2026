import '../../../core/api/api_client.dart';
import '../domain/recommendation.dart';

class RecommendationsRepository {
  RecommendationsRepository(this._api);

  final ApiClient _api;

  Future<List<Recommendation>> getRecommendations({int limit = 6}) async =>
      (await _api.getPagedItems(
            '/api/recommendations?pageSize=$limit',
            authenticated: true,
          ))
          .map((item) => Recommendation.fromJson(item as Map<String, dynamic>))
          .toList();
}
