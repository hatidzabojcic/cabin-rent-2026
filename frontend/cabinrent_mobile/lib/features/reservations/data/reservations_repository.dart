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

  Future<Reservation> create({
    required int cabinId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    String? specialRequests,
  }) async => Reservation.fromJson(
    await _api.post(
      '/api/reservations',
      authenticated: true,
      body: {
        'cabinId': cabinId,
        'checkIn': _dateOnly(checkIn),
        'checkOut': _dateOnly(checkOut),
        'adults': adults,
        'children': children,
        'specialRequests': specialRequests?.trim().isEmpty == true
            ? null
            : specialRequests?.trim(),
      },
    ),
  );

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
