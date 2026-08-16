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
  });
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    userName: json['userName'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    isActive: json['isActive'] as bool,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
  );
  final int id;
  final String firstName, lastName, email, userName;
  final String? phoneNumber;
  final bool isActive;
  final List<String> roles;
  String get fullName => '$firstName $lastName';
  bool get isGuest => roles.contains('Guest');
}
