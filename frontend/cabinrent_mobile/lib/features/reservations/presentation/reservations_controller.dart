import 'package:flutter/foundation.dart';
import '../data/reservations_repository.dart';
import '../domain/reservation.dart';

class ReservationsController extends ChangeNotifier {
  ReservationsController(this._repository);
  final ReservationsRepository _repository;
  List<Reservation> reservations = [];
  bool isLoading = false, hasLoaded = false;
  String? errorMessage;
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      reservations = await _repository.getMine();
      hasLoaded = true;
    } catch (_) {
      errorMessage = 'Rezervacije trenutno nije moguće učitati.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancel(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.cancel(id);
      reservations = reservations.map((x) => x.id == id ? updated : x).toList();
      return true;
    } catch (_) {
      errorMessage = 'Rezervaciju nije moguće otkazati.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
