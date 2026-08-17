import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';

class ReviewsController extends ChangeNotifier {
  ReviewsController(this._repository);

  final ReviewsRepository _repository;

  bool isSubmitting = false;
  String? errorMessage;
  final Set<int> _submittedReservationIds = {};

  bool wasSubmitted(int reservationId) =>
      _submittedReservationIds.contains(reservationId);

  Future<Review?> create({
    required int reservationId,
    required int rating,
    String? comment,
  }) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final review = await _repository.create(
        reservationId: reservationId,
        rating: rating,
        comment: comment,
      );
      _submittedReservationIds.add(reservationId);
      return review;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Dojam trenutno nije moguće poslati.';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
