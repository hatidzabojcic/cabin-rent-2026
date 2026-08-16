import '../../../core/api/api_client.dart';
import '../domain/reservation.dart';

class ReservationsRepository {
  ReservationsRepository(this._api);
  final ApiClient _api;
  Future<List<Reservation>> getMine() async => (await _api.getList(
    '/api/reservations',
    authenticated: true,
  )).map((x) => Reservation.fromJson(x as Map<String, dynamic>)).toList();
  Future<Reservation> cancel(int id) async => Reservation.fromJson(
    await _api.patch('/api/reservations/$id/cancel', authenticated: true),
  );
}
