import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';

class ReviewsController extends ChangeNotifier {
  ReviewsController(this._repository);

  final ReviewsRepository _repository;

  bool isSubmitting = false;
  bool isLoadingMine = false;
  bool hasLoadedMine = false;
  String? errorMessage;
  final Map<int, Review> _mineByReservation = {};

  bool wasSubmitted(int reservationId) =>
      _mineByReservation.containsKey(reservationId);

  Review? reviewForReservation(int reservationId) =>
      _mineByReservation[reservationId];

  Future<List<Review>> getApprovedForCabin(int cabinId) =>
      _repository.getApprovedForCabin(cabinId);

  Future<void> loadMine() async {
    if (isLoadingMine) return;
    isLoadingMine = true;
    notifyListeners();
    try {
      final reviews = await _repository.getMine();
      _mineByReservation
        ..clear()
        ..addEntries(
          reviews.map((review) => MapEntry(review.reservationId, review)),
        );
      hasLoadedMine = true;
    } catch (_) {
      // Rezervacije ostaju dostupne i kada status dojmova nije moguće učitati.
    } finally {
      isLoadingMine = false;
      notifyListeners();
    }
  }

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
      _mineByReservation[reservationId] = review;
      hasLoadedMine = true;
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
