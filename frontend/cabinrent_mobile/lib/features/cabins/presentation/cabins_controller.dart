import 'package:flutter/foundation.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin_details.dart';
import '../domain/cabin_summary.dart';

class CabinsController extends ChangeNotifier {
  CabinsController(this._repository);
  final CabinsRepository _repository;
  List<CabinSummary> cabins = [];
  bool isLoading = false, hasLoaded = false;
  String? errorMessage;
  Future<void> load({String? search}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cabins = await _repository.getCabins(search: search);
      hasLoaded = true;
    } catch (_) {
      errorMessage = 'Vikendice trenutno nije moguće učitati.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<CabinDetails> getCabin(int id) => _repository.getCabin(id);
}
