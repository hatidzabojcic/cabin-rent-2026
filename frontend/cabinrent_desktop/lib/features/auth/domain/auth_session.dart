import 'app_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAtUtc;
  final AppUser user;
}
