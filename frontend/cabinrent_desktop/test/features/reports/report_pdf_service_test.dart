import 'dart:convert';

import 'package:cabinrent_desktop/features/reports/domain/annual_report.dart';
import 'package:cabinrent_desktop/features/reports/domain/top_guests_report.dart';
import 'package:cabinrent_desktop/features/reports/services/report_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ReportPdfService();

  test('generise validan godisnji PDF izvjestaj', () async {
    const report = AnnualReport(
      year: 2026,
      totalReservations: 4,
      completedStays: 2,
      totalNights: 8,
      totalGuests: 7,
      revenue: 1420,
      months: [
        MonthlyReport(
          month: 8,
          reservations: 4,
          completedStays: 2,
          nights: 8,
          revenue: 1420,
        ),
      ],
      cabins: [
        CabinAnnualReport(
          cabinId: 1,
          cabinName: 'Jahorinska idila',
          city: 'Sarajevo',
          ownerName: 'Demo Owner',
          reservations: 4,
          completedStays: 2,
          nights: 8,
          guests: 7,
          revenue: 1420,
        ),
      ],
    );

    final bytes = await service.buildAnnualReport(
      report,
      cabinLabel: 'Sve vikendice',
    );

    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('generise validan PDF izvjestaj o najcescim gostima', () async {
    const report = TopGuestsReport(
      year: 2026,
      guests: [
        TopGuest(
          guestId: 1,
          guestName: 'Demo Guest',
          email: 'guest@cabinrent.local',
          phoneNumber: '+387 61 123 456',
          reservations: 3,
          completedStays: 2,
          nights: 7,
          cabinsVisited: 2,
          totalSpent: 1200,
        ),
      ],
    );

    final bytes = await service.buildTopGuestsReport(
      report,
      cabinLabel: 'Sve vikendice',
    );

    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
