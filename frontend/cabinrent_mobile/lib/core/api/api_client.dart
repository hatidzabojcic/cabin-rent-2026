import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? accessToken;
  Future<bool> Function()? refreshAccessToken;
  Future<bool>? _refreshInProgress;

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async => _decode(
    await _send(
      authenticated,
      () => _client.post(
        _uri(path),
        headers: _headers(authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    ),
    authenticated: authenticated,
  );
  Future<Map<String, dynamic>> getObject(
    String path, {
    bool authenticated = false,
  }) async => _decode(
    await _send(
      authenticated,
      () => _client.get(_uri(path), headers: _headers(authenticated)),
    ),
    authenticated: authenticated,
  );
  Future<List<dynamic>> getList(
    String path, {
    bool authenticated = false,
  }) async => _decodeList(
    await _send(
      authenticated,
      () => _client.get(_uri(path), headers: _headers(authenticated)),
    ),
    authenticated: authenticated,
  );
  Future<List<dynamic>> getPagedItems(
    String path, {
    bool authenticated = false,
  }) async =>
      (await getObject(path, authenticated: authenticated))['items']
          as List<dynamic>;
  Future<Map<String, dynamic>> put(
    String path, {
    required Object body,
    bool authenticated = false,
  }) async => _decode(
    await _send(
      authenticated,
      () => _client.put(
        _uri(path),
        headers: _headers(authenticated),
        body: jsonEncode(body),
      ),
    ),
    authenticated: authenticated,
  );
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async => _decode(
    await _send(
      authenticated,
      () => _client.patch(
        _uri(path),
        headers: _headers(authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
    ),
    authenticated: authenticated,
  );

  Future<void> delete(String path, {bool authenticated = false}) async {
    final response = await _send(
      authenticated,
      () => _client.delete(_uri(path), headers: _headers(authenticated)),
    );
    if (_ok(response)) return;
    final value = _json(response);
    throw ApiException(
      _message(value, response.statusCode, authenticated: authenticated),
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required List<int> bytes,
    required String fileName,
    required String contentType,
    bool authenticated = false,
  }) async => _decode(
    await _send(authenticated, () async {
      final request = http.MultipartRequest('POST', _uri(path));
      request.headers['Accept'] = 'application/json';
      if (authenticated && accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
      return http.Response.fromStream(await _client.send(request));
    }),
    authenticated: authenticated,
  );

  Future<http.Response> _send(
    bool authenticated,
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    if (authenticated &&
        response.statusCode == 401 &&
        await _refreshAccessToken()) {
      response = await request();
    }
    return response;
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = refreshAccessToken;
    if (refresh == null) return false;
    final existing = _refreshInProgress;
    if (existing != null) return existing;
    final operation = refresh();
    _refreshInProgress = operation;
    try {
      return await operation;
    } finally {
      _refreshInProgress = null;
    }
  }

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
  Map<String, dynamic> _decode(
    http.Response response, {
    required bool authenticated,
  }) {
    final value = _json(response);
    if (_ok(response)) return value as Map<String, dynamic>;
    throw ApiException(
      _message(value, response.statusCode, authenticated: authenticated),
      statusCode: response.statusCode,
    );
  }

  List<dynamic> _decodeList(
    http.Response response, {
    required bool authenticated,
  }) {
    final value = _json(response);
    if (_ok(response)) return value as List<dynamic>;
    throw ApiException(
      _message(value, response.statusCode, authenticated: authenticated),
      statusCode: response.statusCode,
    );
  }

  bool _ok(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;
  String _message(
    Object? value,
    int statusCode, {
    required bool authenticated,
  }) {
    if (statusCode == 401 && authenticated) {
      return 'Sesija je istekla. Prijavite se ponovo.';
    }
    const fallback = 'Došlo je do greške pri komunikaciji sa serverom.';
    return value is Map<String, dynamic>
        ? (value['detail'] ?? value['title'] ?? fallback).toString()
        : fallback;
  }
}
