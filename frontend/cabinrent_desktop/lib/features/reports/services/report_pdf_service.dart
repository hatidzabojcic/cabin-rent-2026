import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/annual_report.dart';
import '../domain/top_guests_report.dart';

class ReportPdfService {
  static const _primary = PdfColor.fromInt(0xff124c3f);

  Future<Uint8List> buildAnnualReport(
    AnnualReport report, {
    required String cabinLabel,
  }) async {
    final document = pw.Document(
      title: 'Godisnji izvjestaj ${report.year}',
      author: 'CabinRent',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(
          title: 'Godisnji izvjestaj',
          subtitle: '${report.year}. | $cabinLabel',
        ),
        footer: _footer,
        build: (context) => [
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metric('Rezervacije', report.totalReservations.toString()),
              _metric('Zavrseni boravci', report.completedStays.toString()),
              _metric('Nocenja', report.totalNights.toString()),
              _metric('Gosti', report.totalGuests.toString()),
              _metric('Prihod', _money(report.revenue)),
            ],
          ),
          pw.SizedBox(height: 24),
          _sectionTitle('Pregled po mjesecima'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Mjesec',
              'Rezervacije',
              'Zavrseni boravci',
              'Nocenja',
              'Prihod',
            ],
            data: report.months
                .map(
                  (month) => [
                    monthLabels[month.month - 1],
                    month.reservations,
                    month.completedStays,
                    month.nights,
                    _money(month.revenue),
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 6,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
          ),
          pw.SizedBox(height: 24),
          _sectionTitle('Pregled po vikendicama'),
          if (report.cabins.isEmpty)
            pw.Text('Nema podataka za odabrani filter.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Vikendica',
                'Grad',
                'Vlasnik',
                'Rez.',
                'Zavrsene',
                'Nocenja',
                'Gosti',
                'Prihod',
              ],
              data: report.cabins.asMap().entries.map((entry) {
                final cabin = entry.value;
                return [
                  entry.key + 1,
                  _safe(cabin.cabinName),
                  _safe(cabin.city),
                  _safe(cabin.ownerName),
                  cabin.reservations,
                  cabin.completedStays,
                  cabin.nights,
                  cabin.guests,
                  _money(cabin.revenue),
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(color: _primary),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
            ),
        ],
      ),
    );
    return document.save();
  }

  Future<Uint8List> buildTopGuestsReport(
    TopGuestsReport report, {
    required String cabinLabel,
  }) async {
    final document = pw.Document(
      title: 'Najcesci gosti ${report.year}',
      author: 'CabinRent',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(
          title: 'Izvjestaj o najcescim gostima',
          subtitle: '${report.year}. | $cabinLabel',
        ),
        footer: _footer,
        build: (context) => [
          pw.Text(
            'Rangiranje prema zavrsenim boravcima, nocenjima i ukupnoj potrosnji.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          if (report.guests.isEmpty)
            pw.Text('Nema podataka za odabrani filter.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Gost',
                'Email',
                'Telefon',
                'Rez.',
                'Zavrseni boravci',
                'Nocenja',
                'Vikendice',
                'Potrosnja',
              ],
              data: report.guests.asMap().entries.map((entry) {
                final guest = entry.value;
                return [
                  entry.key + 1,
                  _safe(guest.guestName),
                  _safe(guest.email),
                  _safe(guest.phoneNumber ?? '-'),
                  guest.reservations,
                  guest.completedStays,
                  guest.nights,
                  guest.cabinsVisited,
                  _money(guest.totalSpent),
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(color: _primary),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 6,
              ),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
            ),
        ],
      ),
    );
    return document.save();
  }

  Future<String?> save(Uint8List bytes, {required String fileName}) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Sacuvaj PDF izvjestaj',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      mimeType: 'application/pdf',
      bytes: bytes,
    );
    return uri?.toFilePath(windows: true);
  }

  Future<bool> print(Uint8List bytes, {required String name}) =>
      Printing.layoutPdf(name: name, onLayout: (_) async => bytes);

  pw.Widget _header({
    required String title,
    required String subtitle,
  }) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    margin: const pw.EdgeInsets.only(bottom: 18),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CabinRent',
              style: pw.TextStyle(
                color: _primary,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 3),
            pw.Text(
              'Kreirano: ${_date(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    ),
  );

  pw.Widget _metric(String label, String value) => pw.Container(
    width: 132,
    height: 64,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(5),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  pw.Widget _sectionTitle(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      value,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _footer(pw.Context context) => pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 12),
    child: pw.Text(
      'Stranica ${context.pageNumber} / ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
    ),
  );

  static String _money(double value) => '${value.toStringAsFixed(2)} KM';

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}.';

  // Ugradjeni PDF fontovi nemaju sve bosanske znakove. Transliteracija
  // osigurava da dokument ostane potpuno citljiv i bez vanjskih fontova.
  static String _safe(String value) => value
      .replaceAll('\u010d', 'c')
      .replaceAll('\u0107', 'c')
      .replaceAll('\u0161', 's')
      .replaceAll('\u017e', 'z')
      .replaceAll('\u0111', 'dj')
      .replaceAll('\u010c', 'C')
      .replaceAll('\u0106', 'C')
      .replaceAll('\u0160', 'S')
      .replaceAll('\u017d', 'Z')
      .replaceAll('\u0110', 'Dj');
}
