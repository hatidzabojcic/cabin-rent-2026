import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/core/storage/session_storage.dart';
import 'package:cabinrent_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
