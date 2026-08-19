import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../cabins/data/cabins_repository.dart';
import '../../cabins/domain/cabin.dart';
import '../data/reservations_repository.dart';
import '../domain/reservation.dart';
import 'reservation_details_dialog.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});
  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<Reservation> _reservations = [];
  List<Cabin> _cabins = [];
  bool _loading = true;
  String? _error;
  String? _status;
  int? _cabinId;

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
      final results = await Future.wait([
        context.read<ReservationsRepository>().getReservations(
          cabinId: _cabinId,
          status: _status,
        ),
        context.read<CabinsRepository>().getManagedCabins(),
      ]);
      if (!mounted) return;
      setState(() {
        _reservations = results[0] as List<Reservation>;
        _cabins = results[1] as List<Cabin>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(Reservation reservation, String status) async {
    final reasonController = TextEditingController();
    final requiresReason = status == 'Rejected';
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promjena statusa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promijeniti status rezervacije ${reservation.confirmationCode} u „${ReservationLabels.status(status)}“?',
            ),
            if (requiresReason) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Razlog odbijanja',
                  hintText: 'Navedite razlog koji će ostati evidentiran.',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (requiresReason && value.isEmpty) return;
              Navigator.pop(context, value);
            },
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    try {
      await context.read<ReservationsRepository>().updateStatus(
        reservation.id,
        status,
        reason: reason.isEmpty ? null : reason,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status rezervacije je promijenjen.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _showDetails(Reservation reservation) => showDialog<void>(
    context: context,
    builder: (_) => ReservationDetailsDialog(
      reservation: reservation,
      onStatusSelected: (status) => _changeStatus(reservation, status),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
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
                    'Rezervacije',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text('Pregled boravaka i upravljanje statusima rezervacija.'),
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
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String?>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Svi statusi'),
                  ),
                  ...ReservationLabels.statuses.entries.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (value) {
                  _status = value;
                  _load();
                },
              ),
            ),
            SizedBox(
              width: 280,
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
        Expanded(child: _content()),
      ],
    ),
  );

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rezervacije nije moguće učitati.\n$_error',
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
    if (_reservations.isEmpty) {
      return const Center(child: Text('Nema rezervacija za odabrane filtere.'));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Kod')),
              DataColumn(label: Text('Vikendica')),
              DataColumn(label: Text('Gost')),
              DataColumn(label: Text('Termin')),
              DataColumn(label: Text('Ukupno')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('')),
            ],
            rows: _reservations
                .map(
                  (reservation) => DataRow(
                    onSelectChanged: (_) => _showDetails(reservation),
                    cells: [
                      DataCell(
                        Text(
                          reservation.confirmationCode,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(reservation.cabinName)),
                      DataCell(Text(reservation.guestName)),
                      DataCell(
                        Text(
                          '${formatDate(reservation.checkIn)} – ${formatDate(reservation.checkOut)}',
                        ),
                      ),
                      DataCell(
                        Text('${reservation.totalPrice.toStringAsFixed(2)} KM'),
                      ),
                      DataCell(_StatusBadge(status: reservation.status)),
                      DataCell(
                        IconButton(
                          tooltip: 'Detalji',
                          onPressed: () => _showDetails(reservation),
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Confirmed' => Colors.blue,
      'Completed' => Colors.green,
      'Cancelled' => Colors.grey,
      'Rejected' => Colors.red,
      _ => Colors.orange,
    };
    return Chip(
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .10),
      label: Text(
        ReservationLabels.status(status),
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }
}
