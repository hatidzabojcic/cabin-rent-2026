import 'package:flutter/foundation.dart';
import '../../../core/api/api_exception.dart';
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

  Future<bool> cancel(int id, String reason) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.cancel(id, reason);
      reservations = reservations.map((x) => x.id == id ? updated : x).toList();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Rezervaciju nije moguće otkazati.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Reservation?> refreshOne(int id) async {
    try {
      final updated = await _repository.getById(id);
      reservations = reservations
          .map((reservation) => reservation.id == id ? updated : reservation)
          .toList();
      notifyListeners();
      return updated;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      errorMessage = 'Podatke o rezervaciji trenutno nije moguće osvježiti.';
      notifyListeners();
      return null;
    }
  }

  Future<Reservation?> reschedule({
    required int id,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.reschedule(
        id: id,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      reservations = reservations
          .map((reservation) => reservation.id == id ? updated : reservation)
          .toList();
      return updated;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Termin rezervacije trenutno nije moguće promijeniti.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Reservation?> create({
    required int cabinId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    String? specialRequests,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final reservation = await _repository.create(
        cabinId: cabinId,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
        specialRequests: specialRequests,
      );
      reservations = [reservation, ...reservations];
      hasLoaded = true;
      return reservation;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Rezervaciju trenutno nije moguće kreirati.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
