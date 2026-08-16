import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  const SessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const _key = 'cabinrent_refresh_token';
  final FlutterSecureStorage _storage;
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _key, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);
}
