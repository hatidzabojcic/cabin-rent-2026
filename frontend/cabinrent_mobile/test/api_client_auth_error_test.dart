import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uses login error returned by the public endpoint', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 401,
            'title': 'Pogrešno korisničko ime ili lozinka.',
          }),
          401,
          headers: {'content-type': 'application/problem+json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => api.post('/api/auth/login', body: const {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Pogrešno korisničko ime ili lozinka.',
        ),
      ),
    );
  });

  test('keeps the expired session message for protected endpoints', () async {
    final api = ApiClient(
      client: MockClient((_) async => http.Response('', 401)),
    )..accessToken = 'expired-token';

    expect(
      () => api.getObject('/api/auth/me', authenticated: true),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Sesija je istekla. Prijavite se ponovo.',
        ),
      ),
    );
  });
}
