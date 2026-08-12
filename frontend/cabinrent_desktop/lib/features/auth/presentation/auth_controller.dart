import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/app_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;
  AuthStatus status = AuthStatus.initial;
  AuthSession? _session;
  String? errorMessage;

  AppUser? get user => _session?.user;

  Future<void> restoreSession() async {
    status = AuthStatus.loading;
    notifyListeners();
    _session = await _repository.restore();
    status = _session == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login(String userName, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await _repository.login(userName.trim(), password);
      if (!session.user.isAdmin && !session.user.isOwner) {
        await _repository.logout(session.refreshToken);
        errorMessage =
            'Desktop aplikaciji mogu pristupiti Admin i Owner korisnici.';
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
}
