import '../../../core/config/app_config.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userName,
    required this.isActive,
    required this.roles,
    this.phoneNumber,
    this.profileImageUrl,
  });
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    userName: json['userName'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    isActive: json['isActive'] as bool,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
  );
  final int id;
  final String firstName, lastName, email, userName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isActive;
  final List<String> roles;
  String get fullName => '$firstName $lastName';
  bool get isGuest => roles.contains('Guest');
  String? get resolvedProfileImageUrl {
    final value = profileImageUrl;
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '${AppConfig.apiBaseUrl}${value.startsWith('/') ? '' : '/'}$value';
  }
}
