import '../../../core/api/api_client.dart';
import '../domain/reservation.dart';

class ReservationsRepository {
  ReservationsRepository(this._api);
  final ApiClient _api;

  Future<List<Reservation>> getReservations({
    int? cabinId,
    String? status,
  }) async {
    final parameters = <String, String>{
      if (cabinId != null) 'cabinId': cabinId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    return (await _api.getList('/api/reservations$query', authenticated: true))
        .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Reservation> updateStatus(int id, String status) async =>
      Reservation.fromJson(
        await _api.patch(
          '/api/reservations/$id/status',
          body: {'status': status},
          authenticated: true,
        ),
      );
}
