import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cabins/data/cabins_repository.dart';
import '../../cabins/domain/cabin.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/reports_repository.dart';
import '../domain/annual_report.dart';
import '../domain/top_guests_report.dart';
import '../services/report_pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  AnnualReport? _report;
  TopGuestsReport? _topGuestsReport;
  List<Cabin> _cabins = [];
  bool _loading = true;
  String? _error;
  int _year = DateTime.now().year;
  int? _cabinId;
  bool _showTopGuests = false;
  bool _exporting = false;

  final _pdfService = ReportPdfService();

  bool get _isAdmin => context.read<AuthController>().user?.isAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        context.read<ReportsRepository>().getAnnualReport(
          _year,
          cabinId: _cabinId,
        ),
        context.read<CabinsRepository>().getManagedCabins(),
        if (_isAdmin)
          context.read<ReportsRepository>().getTopGuests(
            _year,
            cabinId: _cabinId,
          )
        else
          Future<TopGuestsReport?>.value(),
      ]);
      if (!mounted) return;
      setState(() {
        _report = results[0] as AnnualReport;
        _cabins = results[1] as List<Cabin>;
        _topGuestsReport = results[2] as TopGuestsReport?;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(7, (index) => DateTime.now().year + 1 - index);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Izvještaji',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Godišnja posjećenost, ostvareni prihod i rang-lista vikendica.',
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _loading ? null : _load,
                tooltip: 'Osvježi',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_isAdmin) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.analytics_outlined),
                  label: Text('Godišnji pregled'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.people_alt_outlined),
                  label: Text('Najčešći gosti'),
                ),
              ],
              selected: {_showTopGuests},
              onSelectionChanged: (selection) =>
                  setState(() => _showTopGuests = selection.first),
            ),
            const SizedBox(height: 18),
          ],
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(labelText: 'Godina'),
                  items: years
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _year = value;
                      _load();
                    }
                  },
                ),
              ),
              SizedBox(
                width: 270,
                child: DropdownButtonFormField<int?>(
                  initialValue: _cabinId,
                  decoration: const InputDecoration(labelText: 'Vikendica'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sve vikendice'),
                    ),
                    ..._cabins.map(
                      (cabin) => DropdownMenuItem<int?>(
                        value: cabin.id,
                        child: Text(cabin.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _cabinId = value;
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_loading && _error == null) ...[
            _reportActions(),
            const SizedBox(height: 14),
          ],
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _reportActions() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      OutlinedButton.icon(
        onPressed: _exporting ? null : () => _exportReport(print: false),
        icon: const Icon(Icons.download_outlined),
        label: const Text('Preuzmi PDF'),
      ),
      const SizedBox(width: 10),
      FilledButton.tonalIcon(
        onPressed: _exporting ? null : () => _exportReport(print: true),
        icon: _exporting
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print_outlined),
        label: const Text('\u0160tampaj'),
      ),
    ],
  );

  Future<void> _exportReport({required bool print}) async {
    setState(() => _exporting = true);
    try {
      final cabinLabel = _selectedCabinLabel;
      final bytes = _showTopGuests && _isAdmin
          ? await _pdfService.buildTopGuestsReport(
              _topGuestsReport!,
              cabinLabel: cabinLabel,
            )
          : await _pdfService.buildAnnualReport(
              _report!,
              cabinLabel: cabinLabel,
            );
      final reportName = _showTopGuests && _isAdmin
          ? 'najcesci-gosti-$_year'
          : 'godisnji-izvjestaj-$_year';

      if (print) {
        await _pdfService.print(bytes, name: reportName);
      } else {
        final path = await _pdfService.save(bytes, fileName: '$reportName.pdf');
        if (path != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF izvje\u0161taj je sa\u010duvan: $path'),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF nije mogu\u0107e kreirati: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String get _selectedCabinLabel {
    if (_cabinId == null) return 'Sve vikendice';
    for (final cabin in _cabins) {
      if (cabin.id == _cabinId) return cabin.name;
    }
    return 'Odabrana vikendica';
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Izvještaj nije moguće učitati.\n$_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (_showTopGuests && _isAdmin) return _topGuestsContent();
    final report = _report!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MetricCard(
                icon: Icons.event_available,
                label: 'Rezervacije',
                value: report.totalReservations.toString(),
                hint: 'Potvrđene i završene',
              ),
              _MetricCard(
                icon: Icons.task_alt,
                label: 'Završeni boravci',
                value: report.completedStays.toString(),
                hint: 'Realizovane rezervacije',
              ),
              _MetricCard(
                icon: Icons.bedtime_outlined,
                label: 'Noćenja',
                value: report.totalNights.toString(),
                hint: '${report.totalGuests} gostiju',
              ),
              _MetricCard(
                icon: Icons.payments_outlined,
                label: 'Ostvareni prihod',
                value: '${report.revenue.toStringAsFixed(2)} KM',
                hint: 'Samo završeni boravci',
              ),
            ],
          ),
          const SizedBox(height: 22),
          _MonthlyChart(months: report.months),
          const SizedBox(height: 22),
          Text(
            'Posjećenost po vikendici – ${report.year}.',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _CabinRanking(cabins: report.cabins),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _topGuestsContent() {
    final report = _topGuestsReport;
    if (report == null) {
      return const Center(child: Text('Izvještaj nije dostupan.'));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Najčešći gosti – ${report.year}.',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rangiranje prema završenim boravcima, ostvarenim noćenjima i potrošnji.',
          ),
          const SizedBox(height: 14),
          _TopGuestsRanking(guests: report.guests),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 225,
    height: 130,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              hint,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months});
  final List<MonthlyReport> months;
  @override
  Widget build(BuildContext context) {
    final maxNights = months.fold<int>(
      0,
      (max, item) => item.nights > max ? item.nights : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Noćenja po mjesecima',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            ...months.map(
              (month) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 38,
                      child: Text(monthLabels[month.month - 1]),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final ratio = maxNights == 0
                              ? 0.0
                              : month.nights / maxNights;
                          return Stack(
                            children: [
                              Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: constraints.maxWidth * ratio,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .75),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${month.nights} noći',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabinRanking extends StatelessWidget {
  const _CabinRanking({required this.cabins});
  final List<CabinAnnualReport> cabins;
  @override
  Widget build(BuildContext context) {
    if (cabins.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nema vikendica za odabrani filter.'),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Vikendica')),
            DataColumn(label: Text('Vlasnik')),
            DataColumn(label: Text('Rezervacije')),
            DataColumn(label: Text('Završene')),
            DataColumn(label: Text('Noćenja')),
            DataColumn(label: Text('Gosti')),
            DataColumn(label: Text('Prihod')),
          ],
          rows: cabins.asMap().entries.map((entry) {
            final cabin = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${entry.key + 1}.')),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cabin.cabinName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        cabin.city,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(cabin.ownerName)),
                DataCell(Text(cabin.reservations.toString())),
                DataCell(Text(cabin.completedStays.toString())),
                DataCell(Text(cabin.nights.toString())),
                DataCell(Text(cabin.guests.toString())),
                DataCell(Text('${cabin.revenue.toStringAsFixed(2)} KM')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopGuestsRanking extends StatelessWidget {
  const _TopGuestsRanking({required this.guests});
  final List<TopGuest> guests;

  @override
  Widget build(BuildContext context) {
    if (guests.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nema gostiju za odabrani filter.'),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Gost')),
            DataColumn(label: Text('Rezervacije')),
            DataColumn(label: Text('Završeni boravci')),
            DataColumn(label: Text('Noćenja')),
            DataColumn(label: Text('Posjećene vikendice')),
            DataColumn(label: Text('Ukupna potrošnja')),
          ],
          rows: guests.asMap().entries.map((entry) {
            final guest = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${entry.key + 1}.')),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest.guestName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        guest.email,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(guest.reservations.toString())),
                DataCell(Text(guest.completedStays.toString())),
                DataCell(Text(guest.nights.toString())),
                DataCell(Text(guest.cabinsVisited.toString())),
                DataCell(Text('${guest.totalSpent.toStringAsFixed(2)} KM')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
