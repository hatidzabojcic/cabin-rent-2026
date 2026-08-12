import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? accessToken;

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> getObject(
    String path, {
    bool authenticated = false,
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: _headers(authenticated),
    );
    return _decodeObject(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    bool authenticated = false,
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: _headers(authenticated),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Object body,
    bool authenticated = false,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers(authenticated),
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Object body,
    bool authenticated = false,
  }) async {
    final response = await _client.patch(
      _uri(path),
      headers: _headers(authenticated),
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> _headers(bool authenticated) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (authenticated && accessToken != null)
      'Authorization': 'Bearer $accessToken',
  };

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }

    var message = 'Došlo je do greške pri komunikaciji sa serverom.';
    if (decoded is Map<String, dynamic>) {
      message = (decoded['title'] ?? decoded['detail'] ?? message).toString();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  List<dynamic> _decodeList(http.Response response) {
    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as List<dynamic>;
    }
    var message = 'Došlo je do greške pri komunikaciji sa serverom.';
    if (decoded is Map<String, dynamic>) {
      message = (decoded['title'] ?? decoded['detail'] ?? message).toString();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Object? _decode(http.Response response) => response.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(utf8.decode(response.bodyBytes));
}
