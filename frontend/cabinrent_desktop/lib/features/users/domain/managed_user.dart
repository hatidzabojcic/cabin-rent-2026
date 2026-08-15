class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userName,
    required this.isActive,
    required this.roles,
    required this.cabinCount,
    required this.reservationCount,
    this.phoneNumber,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    userName: json['userName'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    isActive: json['isActive'] as bool,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
    cabinCount: json['cabinCount'] as int,
    reservationCount: json['reservationCount'] as int,
  );

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String userName;
  final String? phoneNumber;
  final bool isActive;
  final List<String> roles;
  final int cabinCount;
  final int reservationCount;

  String get fullName => '$firstName $lastName';
  bool get isOwner => roles.contains('Owner');
}

String roleLabel(String role) => switch (role) {
  'Admin' => 'Administrator',
  'Owner' => 'Vlasnik',
  'Guest' => 'Gost',
  _ => role,
};
