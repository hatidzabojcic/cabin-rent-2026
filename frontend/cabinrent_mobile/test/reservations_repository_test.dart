import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/features/reservations/data/reservations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('creates reservation using authenticated API payload', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'id': 12,
          'confirmationCode': 'CR-TEST-012',
          'cabinId': 2,
          'cabinName': 'Neretva retreat',
          'checkIn': '2026-09-10',
          'checkOut': '2026-09-14',
          'adults': 2,
          'children': 1,
          'pricePerNight': 220,
          'totalPrice': 880,
          'status': 'Pending',
          'paymentStatus': 'Pending',
          'paidAmount': 0,
          'paymentCurrency': 'BAM',
          'paidAtUtc': null,
          'specialRequests': 'Dječiji krevetić',
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';
    final repository = ReservationsRepository(api);

    final reservation = await repository.create(
      cabinId: 2,
      checkIn: DateTime(2026, 9, 10),
      checkOut: DateTime(2026, 9, 14),
      adults: 2,
      children: 1,
      specialRequests: 'Dječiji krevetić',
    );
    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/reservations');
    expect(capturedRequest.headers['Authorization'], 'Bearer guest-token');
    expect(body['cabinId'], 2);
    expect(body['checkIn'], '2026-09-10');
    expect(body['checkOut'], '2026-09-14');
    expect(body['adults'], 2);
    expect(body['children'], 1);
    expect(body['specialRequests'], 'Dječiji krevetić');
    expect(reservation.confirmationCode, 'CR-TEST-012');
    expect(reservation.nights, 4);
    expect(reservation.pricePerNight, 220);
    expect(reservation.totalPrice, 880);
    expect(reservation.paidAmount, 0);
    expect(reservation.remainingAmount, 880);
    expect(reservation.paymentCurrency, 'BAM');
  });

  test('refreshes expired access token and retries reservation once', () async {
    final authorizationHeaders = <String?>[];
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      authorizationHeaders.add(request.headers['Authorization']);
      if (requestCount == 1) return http.Response('', 401);
      return http.Response(
        jsonEncode({
          'id': 13,
          'confirmationCode': 'CR-TEST-013',
          'cabinName': 'Test Vikendica',
          'checkIn': '2026-09-20',
          'checkOut': '2026-09-22',
          'adults': 2,
          'children': 0,
          'totalPrice': 600,
          'status': 'Pending',
          'paymentStatus': 'Pending',
        }),
        201,
      );
    });
    final api = ApiClient(client: client)..accessToken = 'expired-token';
    var refreshCount = 0;
    api.refreshAccessToken = () async {
      refreshCount++;
      api.accessToken = 'renewed-token';
      return true;
    };

    final reservation = await ReservationsRepository(api).create(
      cabinId: 5,
      checkIn: DateTime(2026, 9, 20),
      checkOut: DateTime(2026, 9, 22),
      adults: 2,
      children: 0,
    );

    expect(refreshCount, 1);
    expect(requestCount, 2);
    expect(authorizationHeaders, [
      'Bearer expired-token',
      'Bearer renewed-token',
    ]);
    expect(reservation.confirmationCode, 'CR-TEST-013');
  });

  test('reschedules reservation using authenticated API payload', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'id': 13,
          'confirmationCode': 'CR-TEST-013',
          'cabinId': 5,
          'cabinName': 'Test Vikendica',
          'checkIn': '2026-10-02',
          'checkOut': '2026-10-05',
          'adults': 2,
          'children': 0,
          'pricePerNight': 300,
          'totalPrice': 900,
          'status': 'Pending',
          'paymentStatus': 'Pending',
          'paidAmount': 0,
          'paymentCurrency': 'BAM',
        }),
        200,
      );
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';

    final reservation = await ReservationsRepository(api).reschedule(
      id: 13,
      checkIn: DateTime(2026, 10, 2),
      checkOut: DateTime(2026, 10, 5),
    );
    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

    expect(capturedRequest.method, 'PATCH');
    expect(capturedRequest.url.path, '/api/reservations/13/reschedule');
    expect(capturedRequest.headers['Authorization'], 'Bearer guest-token');
    expect(body, {'checkIn': '2026-10-02', 'checkOut': '2026-10-05'});
    expect(reservation.status, 'Pending');
    expect(reservation.nights, 3);
    expect(reservation.totalPrice, 900);
  });
}
