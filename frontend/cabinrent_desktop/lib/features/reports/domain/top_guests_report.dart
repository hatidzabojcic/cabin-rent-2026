class TopGuestsReport {
  const TopGuestsReport({
    required this.year,
    required this.guests,
    this.cabinId,
  });

  factory TopGuestsReport.fromJson(Map<String, dynamic> json) => TopGuestsReport(
    year: json['year'] as int,
    cabinId: json['cabinId'] as int?,
    guests: (json['guests'] as List<dynamic>)
        .map((item) => TopGuest.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  final int year;
  final int? cabinId;
  final List<TopGuest> guests;
}

class TopGuest {
  const TopGuest({
    required this.guestId,
    required this.guestName,
    required this.email,
    required this.reservations,
    required this.completedStays,
    required this.nights,
    required this.cabinsVisited,
    required this.totalSpent,
    this.phoneNumber,
  });

  factory TopGuest.fromJson(Map<String, dynamic> json) => TopGuest(
    guestId: json['guestId'] as int,
    guestName: json['guestName'] as String,
    email: json['email'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    reservations: json['reservations'] as int,
    completedStays: json['completedStays'] as int,
    nights: json['nights'] as int,
    cabinsVisited: json['cabinsVisited'] as int,
    totalSpent: (json['totalSpent'] as num).toDouble(),
  );

  final int guestId;
  final String guestName;
  final String email;
  final String? phoneNumber;
  final int reservations;
  final int completedStays;
  final int nights;
  final int cabinsVisited;
  final double totalSpent;
}
