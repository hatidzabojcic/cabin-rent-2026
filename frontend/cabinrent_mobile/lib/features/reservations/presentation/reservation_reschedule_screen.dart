import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/reservation.dart';
import 'reservations_controller.dart';

class ReservationRescheduleScreen extends StatefulWidget {
  const ReservationRescheduleScreen({required this.reservation, super.key});

  final Reservation reservation;

  @override
  State<ReservationRescheduleScreen> createState() =>
      _ReservationRescheduleScreenState();
}

class _ReservationRescheduleScreenState
    extends State<ReservationRescheduleScreen> {
  DateTimeRange? _range;

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final currentRange = widget.reservation.checkIn.isBefore(firstDate)
        ? null
        : DateTimeRange(
            start: widget.reservation.checkIn,
            end: widget.reservation.checkOut,
          );
    final selected = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: _range ?? currentRange,
      helpText: 'Odaberite novi termin',
      saveText: 'Odaberi',
      cancelText: 'Odustani',
      confirmText: 'Potvrdi',
      fieldStartLabelText: 'Dolazak',
      fieldEndLabelText: 'Odlazak',
    );
    if (selected != null) setState(() => _range = selected);
  }

  Future<void> _submit() async {
    final range = _range;
    if (range == null) return;
    final controller = context.read<ReservationsController>();
    final updated = await controller.reschedule(
      id: widget.reservation.id,
      checkIn: range.start,
      checkOut: range.end,
    );
    if (!mounted) return;
    if (updated != null) {
      Navigator.pop(context, updated);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ??
              'Termin rezervacije trenutno nije moguće promijeniti.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ReservationsController>().isLoading;
    final range = _range;
    final nights = range?.duration.inDays ?? 0;
    final estimatedTotal = widget.reservation.pricePerNight * nights;
    return Scaffold(
      appBar: AppBar(title: const Text('Promjena termina')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.reservation.cabinName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(widget.reservation.confirmationCode),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trenutni termin',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatDate(widget.reservation.checkIn)} – '
                    '${formatDate(widget.reservation.checkOut)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _selectDates,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              range == null
                  ? 'Odaberi novi termin'
                  : '${formatDate(range.start)} – ${formatDate(range.end)}',
            ),
          ),
          if (range != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PriceRow(label: 'Broj noćenja', value: nights.toString()),
                    const SizedBox(height: 9),
                    _PriceRow(
                      label: 'Procijenjena cijena',
                      value: '${estimatedTotal.toStringAsFixed(2)} KM',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 21),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nakon promjene termina rezervacija se vraća na čekanje. '
                    'Vlasnik vikendice treba ponovo potvrditi rezervaciju. '
                    'Konačna cijena računa se prema trenutno važećoj cijeni.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: range == null || isLoading ? null : _submit,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_repeat_outlined),
            label: const Text('Pošalji zahtjev za novi termin'),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}
