import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/core/storage/session_storage.dart';
import 'package:cabinrent_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'logout revokes the latest refresh token after token rotation',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'cabinrent_refresh_token': 'refresh-token-1',
      });
      var refreshCount = 0;
      var protectedRequestCount = 0;
      String? logoutRefreshToken;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshCount++;
          final nextToken = 'refresh-token-${refreshCount + 1}';
          return http.Response(
            jsonEncode({
              'accessToken': 'access-token-$refreshCount',
              'refreshToken': nextToken,
              'expiresAtUtc': '2026-09-05T12:00:00Z',
              'user': {
                'id': 4,
                'firstName': 'Demo',
                'lastName': 'Guest',
                'email': 'guest@cabinrent.local',
                'userName': 'guest',
                'phoneNumber': null,
                'isActive': true,
                'roles': ['Guest'],
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/protected') {
          protectedRequestCount++;
          return protectedRequestCount == 1
              ? http.Response('', 401)
              : http.Response(jsonEncode({'ok': true}), 200);
        }
        if (request.url.path == '/api/auth/logout') {
          logoutRefreshToken =
              (jsonDecode(request.body) as Map<String, dynamic>)['refreshToken']
                  as String;
          return http.Response('', 204);
        }
        return http.Response('', 404);
      });
      final api = ApiClient(client: client);
      const storage = SessionStorage();
      final repository = AuthRepository(api, storage);
      final synchronizedSessions = <String>[];
      repository.onSessionChanged = (session) {
        if (session != null) synchronizedSessions.add(session.refreshToken);
      };

      await repository.restore();
      await api.getObject('/api/protected', authenticated: true);
      await repository.logout();

      expect(refreshCount, 2);
      expect(synchronizedSessions, ['refresh-token-2', 'refresh-token-3']);
      expect(logoutRefreshToken, 'refresh-token-3');
      expect(await storage.readRefreshToken(), isNull);
      expect(api.accessToken, isNull);
    },
  );

  test('deactivates profile and clears the saved session', () async {
    FlutterSecureStorage.setMockInitialValues({
      'cabinrent_refresh_token': 'refresh-token',
    });
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response('', 204);
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';
    const storage = SessionStorage();
    final repository = AuthRepository(api, storage);

    await repository.deactivateProfile();

    expect(capturedRequest.method, 'DELETE');
    expect(capturedRequest.url.path, '/api/auth/me');
    expect(capturedRequest.headers['Authorization'], 'Bearer guest-token');
    expect(api.accessToken, isNull);
    expect(await storage.readRefreshToken(), isNull);
  });

  test('updates authenticated guest profile', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'id': 3,
          'firstName': 'Hana',
          'lastName': 'Hadžić',
          'email': 'hana@example.com',
          'userName': 'guest',
          'phoneNumber': '+38761123456',
          'isActive': true,
          'roles': ['Guest'],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';
    final repository = AuthRepository(api, const SessionStorage());

    final user = await repository.updateProfile(
      firstName: ' Hana ',
      lastName: ' Hadžić ',
      email: ' hana@example.com ',
      phoneNumber: ' +387 61 123 456 ',
    );
    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

    expect(capturedRequest.method, 'PUT');
    expect(capturedRequest.url.path, '/api/auth/me');
    expect(capturedRequest.headers['Authorization'], 'Bearer guest-token');
    expect(body['firstName'], 'Hana');
    expect(body['lastName'], 'Hadžić');
    expect(body['email'], 'hana@example.com');
    expect(body['phoneNumber'], '+38761123456');
    expect(user.fullName, 'Hana Hadžić');
  });
}
