import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cabins/domain/cabin_details.dart';
import '../../cabins/domain/cabin_search_criteria.dart';
import '../domain/reservation.dart';
import 'reservations_controller.dart';

class ReservationFormScreen extends StatefulWidget {
  const ReservationFormScreen({
    required this.cabin,
    this.initialCriteria,
    this.onReservationCreated,
    super.key,
  });

  final CabinDetails cabin;
  final CabinSearchCriteria? initialCriteria;
  final VoidCallback? onReservationCreated;

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _specialRequests = TextEditingController();
  DateTimeRange? _range;
  int _adults = 1;
  int _children = 0;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final criteria = widget.initialCriteria;
    if (criteria != null) {
      _range = DateTimeRange(start: criteria.checkIn, end: criteria.checkOut);
      _adults = criteria.guests <= widget.cabin.maxAdults
          ? criteria.guests
          : widget.cabin.maxAdults;
      _children = criteria.guests - _adults;
    }
  }

  @override
  void dispose() {
    _specialRequests.dispose();
    super.dispose();
  }

  int get _nights => _range?.duration.inDays ?? 0;
  double get _totalPrice => widget.cabin.pricePerNight * _nights;

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}.';

  Future<void> _selectDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final current = _range != null && !_range!.start.isBefore(today)
        ? _range
        : DateTimeRange(
            start: tomorrow,
            end: tomorrow.add(const Duration(days: 2)),
          );
    final result = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      initialDateRange: current,
      helpText: 'Odaberite termin rezervacije',
      cancelText: 'Odustani',
      confirmText: 'Potvrdi',
      saveText: 'Sačuvaj',
    );
    if (result != null && mounted) {
      setState(() {
        _range = result;
        _dateError = null;
      });
    }
  }

  Future<void> _submit() async {
    final range = _range;
    if (range == null || range.duration.inDays < 1) {
      setState(() => _dateError = 'Odaberite datum dolaska i odlaska.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Potvrda rezervacije'),
        content: Text(
          '${widget.cabin.name}\n'
          '${_date(range.start)} – ${_date(range.end)}\n'
          '${_adults + _children} gostiju, $_nights noćenja\n\n'
          'Ukupno: ${_totalPrice.toStringAsFixed(2)} KM',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = context.read<ReservationsController>();
    final reservation = await controller.create(
      cabinId: widget.cabin.id,
      checkIn: range.start,
      checkOut: range.end,
      adults: _adults,
      children: _children,
      specialRequests: _specialRequests.text,
    );
    if (!mounted) return;
    if (reservation == null) {
      setState(() {});
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SuccessDialog(reservation: reservation),
    );
    if (!mounted) return;
    widget.onReservationCreated?.call();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReservationsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nova rezervacija')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            widget.cabin.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text('${widget.cabin.city}  •  ${widget.cabin.cabinType}'),
          const SizedBox(height: 22),
          const _SectionTitle('Termin boravka'),
          const SizedBox(height: 10),
          InkWell(
            onTap: controller.isLoading ? null : _selectDates,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Dolazak i odlazak',
                prefixIcon: const Icon(Icons.date_range_outlined),
                errorText: _dateError,
              ),
              child: Text(
                _range == null
                    ? 'Odaberite datume'
                    : '${_date(_range!.start)} – ${_date(_range!.end)}',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Broj gostiju'),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  _GuestCounter(
                    label: 'Odrasli',
                    helper: 'Najviše ${widget.cabin.maxAdults}',
                    value: _adults,
                    canDecrease: _adults > 1 && !controller.isLoading,
                    canIncrease:
                        _adults < widget.cabin.maxAdults &&
                        _adults + _children < widget.cabin.maxGuests &&
                        !controller.isLoading,
                    onDecrease: () => setState(() => _adults--),
                    onIncrease: () => setState(() => _adults++),
                  ),
                  const Divider(),
                  _GuestCounter(
                    label: 'Djeca',
                    helper: 'Najviše ${widget.cabin.maxChildren}',
                    value: _children,
                    canDecrease: _children > 0 && !controller.isLoading,
                    canIncrease:
                        _children < widget.cabin.maxChildren &&
                        _adults + _children < widget.cabin.maxGuests &&
                        !controller.isLoading,
                    onDecrease: () => setState(() => _children--),
                    onIncrease: () => setState(() => _children++),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Posebni zahtjevi'),
          const SizedBox(height: 10),
          TextField(
            controller: _specialRequests,
            enabled: !controller.isLoading,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Npr. dječiji krevetić ili kasniji dolazak',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          _PriceSummary(
            pricePerNight: widget.cabin.pricePerNight,
            nights: _nights,
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: controller.isLoading ? null : _submit,
            icon: controller.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              controller.isLoading ? 'Kreiranje...' : 'Potvrdi rezervaciju',
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCounter extends StatelessWidget {
  const _GuestCounter({
    required this.label,
    required this.helper,
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String helper;
  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(helper, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      IconButton(
        onPressed: canDecrease ? onDecrease : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 28,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        onPressed: canIncrease ? onIncrease : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.pricePerNight, required this.nights});

  final double pricePerNight;
  final int nights;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pricePerNight.toStringAsFixed(2)} KM × $nights noćenja'),
              Text('${(pricePerNight * nights).toStringAsFixed(2)} KM'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ukupno',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${(pricePerNight * nights).toStringAsFixed(2)} KM',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Icon(
      Icons.check_circle,
      size: 52,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: const Text('Rezervacija je kreirana'),
    content: Text(
      'Kod rezervacije: ${reservation.confirmationCode}\n'
      'Ukupno: ${reservation.totalPrice.toStringAsFixed(2)} KM\n\n'
      'Rezervacija je poslana vlasniku i trenutno je na čekanju.',
      textAlign: TextAlign.center,
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Moje rezervacije'),
      ),
    ],
  );
}
