import '../../../core/api/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage) {
    _api.refreshAccessToken = _refreshAccessToken;
  }
  final ApiClient _api;
  final SessionStorage _storage;

  Future<AuthSession> login(String userName, String password) async => _save(
    AuthSession.fromJson(
      await _api.post(
        '/api/auth/login',
        body: {'userName': userName, 'password': password},
      ),
    ),
  );
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    required String password,
    String? phoneNumber,
  }) async => _save(
    AuthSession.fromJson(
      await _api.post(
        '/api/auth/register',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'userName': userName,
          'password': password,
          'phoneNumber': phoneNumber?.trim().isEmpty == true
              ? null
              : phoneNumber?.replaceAll(' ', ''),
        },
      ),
    ),
  );
  Future<AuthSession?> restore() async {
    return _refreshSession();
  }

  Future<bool> _refreshAccessToken() async => await _refreshSession() != null;

  Future<AuthSession?> _refreshSession() async {
    final token = await _storage.readRefreshToken();
    if (token == null) return null;
    try {
      return _save(
        AuthSession.fromJson(
          await _api.post('/api/auth/refresh', body: {'refreshToken': token}),
        ),
      );
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> logout(String token) async {
    try {
      await _api.post(
        '/api/auth/logout',
        body: {'refreshToken': token},
        authenticated: true,
      );
    } finally {
      _api.accessToken = null;
      await _storage.clear();
    }
  }

  Future<void> deactivateProfile() async {
    await _api.delete('/api/auth/me', authenticated: true);
    _api.accessToken = null;
    await _storage.clear();
  }

  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
  }) async => AppUser.fromJson(
    await _api.put(
      '/api/auth/me',
      authenticated: true,
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber?.trim().isEmpty == true
            ? null
            : phoneNumber?.replaceAll(' ', ''),
      },
    ),
  );

  Future<AppUser> updateProfileImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async => AppUser.fromJson(
    await _api.postMultipart(
      '/api/auth/me/image',
      authenticated: true,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    ),
  );

  Future<AuthSession> _save(AuthSession session) async {
    _api.accessToken = session.accessToken;
    await _storage.saveRefreshToken(session.refreshToken);
    return session;
  }
}
