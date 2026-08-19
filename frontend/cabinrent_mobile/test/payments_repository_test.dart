import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/features/payments/data/payments_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'creates Stripe intent for the authenticated guest reservation',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'paymentId': 31,
            'reservationId': 21,
            'amount': 290,
            'currency': 'BAM',
            'status': 'requires_payment_method',
            'clientSecret': 'pi_test_secret_value',
            'publishableKey': 'pk_test_value',
          }),
          200,
        );
      });
      final api = ApiClient(client: client)..accessToken = 'guest-token';

      final intent = await PaymentsRepository(api).createIntent(21);

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/payments/reservations/21/intent');
      expect(capturedRequest.headers['Authorization'], 'Bearer guest-token');
      expect(intent.paymentId, 31);
      expect(intent.reservationId, 21);
      expect(intent.amount, 290);
      expect(intent.currency, 'BAM');
      expect(intent.clientSecret, 'pi_test_secret_value');
      expect(intent.publishableKey, 'pk_test_value');
    },
  );

  test('confirms Stripe intent through the backend', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'paymentId': 31,
          'reservationId': 21,
          'status': 'Paid',
          'paidAmount': 290,
          'currency': 'BAM',
        }),
        200,
      );
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';

    final status = await PaymentsRepository(api).confirmIntent(21);

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/payments/reservations/21/confirm');
    expect(capturedRequest.headers['Authorization'], 'Bearer guest-token');
    expect(status, 'Paid');
  });
}
