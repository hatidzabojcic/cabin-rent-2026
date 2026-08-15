import '../../../core/api/api_client.dart';
import '../domain/review.dart';

class ReviewsRepository {
  ReviewsRepository(this._api);
  final ApiClient _api;

  Future<List<Review>> getReviews({
    int? cabinId,
    int? rating,
    bool? approved,
    String? search,
  }) async {
    final parameters = <String, String>{
      if (cabinId != null) 'cabinId': cabinId.toString(),
      if (rating != null) 'rating': rating.toString(),
      if (approved != null) 'approved': approved.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    return (await _api.getList(
      '/api/reviews/management$query',
      authenticated: true,
    )).map((item) => Review.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Review> setApproval(int id, bool isApproved) async => Review.fromJson(
    await _api.patch(
      '/api/reviews/$id/approval',
      body: {'isApproved': isApproved},
      authenticated: true,
    ),
  );
}
