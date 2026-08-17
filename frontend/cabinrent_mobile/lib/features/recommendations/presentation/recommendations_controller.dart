import 'package:flutter/foundation.dart';

import '../data/recommendations_repository.dart';
import '../domain/recommendation.dart';

class RecommendationsController extends ChangeNotifier {
  RecommendationsController(this._repository);

  final RecommendationsRepository _repository;

  List<Recommendation> recommendations = [];
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;

  bool get isPersonalized =>
      recommendations.isNotEmpty && recommendations.first.isPersonalized;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      recommendations = await _repository.getRecommendations();
      hasLoaded = true;
    } catch (_) {
      errorMessage = 'Preporuke trenutno nije moguće učitati.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
