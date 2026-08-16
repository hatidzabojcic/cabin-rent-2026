import 'package:flutter/foundation.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin_details.dart';
import '../domain/cabin_search_criteria.dart';
import '../domain/cabin_summary.dart';

class CabinsController extends ChangeNotifier {
  CabinsController(this._repository);
  final CabinsRepository _repository;
  List<CabinSummary> cabins = [];
  bool isLoading = false, hasLoaded = false;
  String? errorMessage;
  String _search = '';
  CabinSearchCriteria? criteria;

  Future<void> load({String? search}) async {
    if (search != null) _search = search;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cabins = await _repository.getCabins(
        search: _search,
        checkIn: criteria?.checkIn,
        checkOut: criteria?.checkOut,
        guests: criteria?.guests,
      );
      hasLoaded = true;
    } catch (_) {
      errorMessage = 'Vikendice trenutno nije moguće učitati.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyAvailability(CabinSearchCriteria value) async {
    criteria = value;
    await load();
  }

  Future<void> clearAvailability() async {
    criteria = null;
    await load();
  }

  Future<CabinDetails> getCabin(int id) => _repository.getCabin(id);
}
