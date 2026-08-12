import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  Future<AuthSession> login(String userName, String password) async {
    final json = await _api.post(
      '/api/auth/login',
      body: {'userName': userName, 'password': password},
    );
    return _saveSession(AuthSession.fromJson(json));
  }

  Future<AuthSession?> restore() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final json = await _api.post(
        '/api/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      return _saveSession(AuthSession.fromJson(json));
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _api.post(
        '/api/auth/logout',
        body: {'refreshToken': refreshToken},
        authenticated: true,
      );
    } finally {
      _api.accessToken = null;
      await _storage.clear();
    }
  }

  Future<AuthSession> _saveSession(AuthSession session) async {
    _api.accessToken = session.accessToken;
    await _storage.saveRefreshToken(session.refreshToken);
    return session;
  }
}
