import 'dart:convert';

import 'package:cabinrent_desktop/core/api/api_client.dart';
import 'package:cabinrent_desktop/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'refreshes an expired access token and retries the request once',
    () async {
      final authorizationHeaders = <String?>[];
      var requestCount = 0;
      var refreshCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        authorizationHeaders.add(request.headers['Authorization']);
        if (requestCount == 1) return http.Response('', 401);
        return http.Response(jsonEncode({'id': 7}), 200);
      });
      final api = ApiClient(client: client)..accessToken = 'expired-token';
      api.refreshAccessToken = () async {
        refreshCount++;
        api.accessToken = 'renewed-token';
        return true;
      };

      final result = await api.getObject('/api/users/7', authenticated: true);

      expect(result['id'], 7);
      expect(refreshCount, 1);
      expect(requestCount, 2);
      expect(authorizationHeaders, [
        'Bearer expired-token',
        'Bearer renewed-token',
      ]);
    },
  );

  test(
    'does not retry indefinitely when refreshed token is rejected',
    () async {
      var requestCount = 0;
      var refreshCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('', 401);
      });
      final api = ApiClient(client: client)..accessToken = 'expired-token';
      api.refreshAccessToken = () async {
        refreshCount++;
        api.accessToken = 'rejected-token';
        return true;
      };

      await expectLater(
        api.getObject('/api/users/7', authenticated: true),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(refreshCount, 1);
      expect(requestCount, 2);
    },
  );
}
