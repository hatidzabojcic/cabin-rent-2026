class AnnualReport {
  const AnnualReport({
    required this.year,
    required this.totalReservations,
    required this.completedStays,
    required this.totalNights,
    required this.totalGuests,
    required this.revenue,
    required this.months,
    required this.cabins,
  });

  factory AnnualReport.fromJson(Map<String, dynamic> json) => AnnualReport(
    year: json['year'] as int,
    totalReservations: json['totalReservations'] as int,
    completedStays: json['completedStays'] as int,
    totalNights: json['totalNights'] as int,
    totalGuests: json['totalGuests'] as int,
    revenue: (json['revenue'] as num).toDouble(),
    months: (json['months'] as List<dynamic>)
        .map((item) => MonthlyReport.fromJson(item as Map<String, dynamic>))
        .toList(),
    cabins: (json['cabins'] as List<dynamic>)
        .map((item) => CabinAnnualReport.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  final int year;
  final int totalReservations;
  final int completedStays;
  final int totalNights;
  final int totalGuests;
  final double revenue;
  final List<MonthlyReport> months;
  final List<CabinAnnualReport> cabins;
}

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.reservations,
    required this.completedStays,
    required this.nights,
    required this.revenue,
  });
  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
    month: json['month'] as int,
    reservations: json['reservations'] as int,
    completedStays: json['completedStays'] as int,
    nights: json['nights'] as int,
    revenue: (json['revenue'] as num).toDouble(),
  );
  final int month;
  final int reservations;
  final int completedStays;
  final int nights;
  final double revenue;
}

class CabinAnnualReport {
  const CabinAnnualReport({
    required this.cabinId,
    required this.cabinName,
    required this.city,
    required this.ownerName,
    required this.reservations,
    required this.completedStays,
    required this.nights,
    required this.guests,
    required this.revenue,
  });
  factory CabinAnnualReport.fromJson(Map<String, dynamic> json) =>
      CabinAnnualReport(
        cabinId: json['cabinId'] as int,
        cabinName: json['cabinName'] as String,
        city: json['city'] as String,
        ownerName: json['ownerName'] as String,
        reservations: json['reservations'] as int,
        completedStays: json['completedStays'] as int,
        nights: json['nights'] as int,
        guests: json['guests'] as int,
        revenue: (json['revenue'] as num).toDouble(),
      );
  final int cabinId;
  final String cabinName;
  final String city;
  final String ownerName;
  final int reservations;
  final int completedStays;
  final int nights;
  final int guests;
  final double revenue;
}

const monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Maj',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Okt',
  'Nov',
  'Dec',
];
