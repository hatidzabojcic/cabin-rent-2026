import 'package:cabinrent_desktop/features/reports/domain/annual_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('annual report parses summary data', () {
    final report = AnnualReport.fromJson({
      'year': 2026,
      'totalReservations': 2,
      'completedStays': 1,
      'totalNights': 7,
      'totalGuests': 6,
      'revenue': 540.0,
      'months': <dynamic>[],
      'cabins': <dynamic>[],
    });
    expect(report.year, 2026);
    expect(report.revenue, 540);
    expect(report.totalNights, 7);
  });
}
