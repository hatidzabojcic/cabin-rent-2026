import '../../../core/api/api_client.dart';
import '../domain/review.dart';

class ReviewsRepository {
  ReviewsRepository(this._api);

  final ApiClient _api;

  Future<Review> create({
    required int reservationId,
    required int rating,
    String? comment,
  }) async => Review.fromJson(
    await _api.post(
      '/api/reviews',
      authenticated: true,
      body: {
        'reservationId': reservationId,
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      },
    ),
  );
}
