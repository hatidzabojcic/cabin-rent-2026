import 'package:flutter/foundation.dart';
import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);
  final AuthRepository _repository;
  AuthStatus status = AuthStatus.initial;
  AuthSession? _session;
  String? errorMessage;
  AppUser? get user => _session?.user;
  bool get isLoading => status == AuthStatus.loading;

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    status = AuthStatus.loading;
    notifyListeners();
    _session = await _repository.restore();
    if (_session != null && !_session!.user.isGuest) {
      await _repository.logout(_session!.refreshToken);
      _session = null;
    }
    status = _session == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login(String userName, String password) =>
      _authenticate(() => _repository.login(userName.trim(), password));
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    required String password,
    String? phoneNumber,
  }) => _authenticate(
    () => _repository.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      userName: userName.trim(),
      password: password,
      phoneNumber: phoneNumber?.trim().isEmpty == true
          ? null
          : phoneNumber?.trim(),
    ),
  );
  Future<bool> _authenticate(Future<AuthSession> Function() action) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await action();
      if (!session.user.isGuest) {
        await _repository.logout(session.refreshToken);
        errorMessage = 'Mobilna aplikacija je namijenjena gostima.';
        status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _session = session;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage =
          'API nije dostupan. Provjerite da li su Docker servisi pokrenuti.';
    }
    status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final session = _session;
    status = AuthStatus.loading;
    notifyListeners();
    if (session != null) await _repository.logout(session.refreshToken);
    _session = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> deactivateProfile() async {
    if (_session == null || status == AuthStatus.loading) return false;
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.deactivateProfile();
      _session = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Profil trenutno nije moguće obrisati.';
    }
    status = AuthStatus.authenticated;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
  }) async {
    final session = _session;
    if (session == null) return false;
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      );
      _session = AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAtUtc: session.expiresAtUtc,
        user: updatedUser,
      );
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Profil trenutno nije moguće ažurirati.';
    }
    status = AuthStatus.authenticated;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfileImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final session = _session;
    if (session == null) return false;
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final updatedUser = await _repository.updateProfileImage(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      _session = AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAtUtc: session.expiresAtUtc,
        user: updatedUser,
      );
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Profilnu sliku trenutno nije moguće sačuvati.';
    }
    status = AuthStatus.authenticated;
    notifyListeners();
    return false;
  }
}
