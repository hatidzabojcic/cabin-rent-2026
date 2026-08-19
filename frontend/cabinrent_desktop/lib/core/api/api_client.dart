import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required List<int> bytes,
    required String fileName,
    String? altText,
    bool authenticated = false,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers['Accept'] = 'application/json';
    if (authenticated && accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (altText != null && altText.trim().isNotEmpty) {
      request.fields['altText'] = altText.trim();
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: _imageMediaType(fileName),
      ),
    );
    return _decodeObject(
      await http.Response.fromStream(await _client.send(request)),
    );
  }

  Future<void> delete(String path, {bool authenticated = false}) async {
    final response = await _client.delete(
      _uri(path),
      headers: _headers(authenticated),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decodeObject(response);
    }
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
    } else if (decoded is String && decoded.trim().isNotEmpty) {
      message = decoded;
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
    } else if (decoded is String && decoded.trim().isNotEmpty) {
      message = decoded;
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Object? _decode(http.Response response) => response.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(utf8.decode(response.bodyBytes));

  MediaType _imageMediaType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('application', 'octet-stream'),
    };
  }
}
