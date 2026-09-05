import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage) {
    _api.refreshAccessToken = _refreshAccessToken;
  }

  final ApiClient _api;
  final TokenStorage _storage;
  AuthSession? _session;
  void Function(AuthSession? session)? onSessionChanged;

  Future<AuthSession> login(String userName, String password) async {
    final json = await _api.post(
      '/api/auth/login',
      body: {'userName': userName, 'password': password},
    );
    return _saveSession(AuthSession.fromJson(json));
  }

  Future<AuthSession?> restore() async {
    return _refreshSession();
  }

  Future<bool> _refreshAccessToken() async => await _refreshSession() != null;

  Future<AuthSession?> _refreshSession() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final json = await _api.post(
        '/api/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      return _saveSession(AuthSession.fromJson(json));
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken =
        _session?.refreshToken ?? await _storage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _api.post(
          '/api/auth/logout',
          body: {'refreshToken': refreshToken},
          authenticated: true,
        );
      }
    } finally {
      await _clearSession();
    }
  }

  Future<AuthSession> _saveSession(AuthSession session) async {
    _api.accessToken = session.accessToken;
    await _storage.saveRefreshToken(session.refreshToken);
    _session = session;
    onSessionChanged?.call(session);
    return session;
  }

  Future<void> _clearSession() async {
    _api.accessToken = null;
    await _storage.clear();
    _session = null;
    onSessionChanged?.call(null);
  }
}
