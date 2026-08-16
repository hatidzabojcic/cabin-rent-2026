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
  }) async => _decode(
    await _client.post(
      _uri(path),
      headers: _headers(authenticated),
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Future<Map<String, dynamic>> getObject(
    String path, {
    bool authenticated = false,
  }) async =>
      _decode(await _client.get(_uri(path), headers: _headers(authenticated)));
  Future<List<dynamic>> getList(
    String path, {
    bool authenticated = false,
  }) async => _decodeList(
    await _client.get(_uri(path), headers: _headers(authenticated)),
  );
  Future<Map<String, dynamic>> put(
    String path, {
    required Object body,
    bool authenticated = false,
  }) async => _decode(
    await _client.put(
      _uri(path),
      headers: _headers(authenticated),
      body: jsonEncode(body),
    ),
  );
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async => _decode(
    await _client.patch(
      _uri(path),
      headers: _headers(authenticated),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');
  Map<String, String> _headers(bool authenticated) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (authenticated && accessToken != null)
      'Authorization': 'Bearer $accessToken',
  };
  Object? _json(http.Response response) => response.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(utf8.decode(response.bodyBytes));
  Map<String, dynamic> _decode(http.Response response) {
    final value = _json(response);
    if (_ok(response)) return value as Map<String, dynamic>;
    throw ApiException(_message(value), statusCode: response.statusCode);
  }

  List<dynamic> _decodeList(http.Response response) {
    final value = _json(response);
    if (_ok(response)) return value as List<dynamic>;
    throw ApiException(_message(value), statusCode: response.statusCode);
  }

  bool _ok(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;
  String _message(Object? value) {
    const fallback = 'Došlo je do greške pri komunikaciji sa serverom.';
    return value is Map<String, dynamic>
        ? (value['detail'] ?? value['title'] ?? fallback).toString()
        : fallback;
  }
}
