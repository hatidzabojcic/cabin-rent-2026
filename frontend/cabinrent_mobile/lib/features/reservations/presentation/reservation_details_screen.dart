import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../payments/presentation/payments_controller.dart';
import '../../reviews/presentation/review_form_screen.dart';
import '../../reviews/presentation/reviews_controller.dart';
import '../domain/reservation.dart';
import 'reservations_controller.dart';
import 'reservation_reschedule_screen.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({required this.reservation, super.key});

  final Reservation reservation;

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  late Reservation _reservation = widget.reservation;
  bool _isRefreshing = false;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Otkazati rezervaciju?'),
        content: Text(
          _reservation.paymentStatus == 'Paid'
              ? 'Otkazivanjem rezervacije ${_reservation.confirmationCode} puni uplaćeni iznos bit će vraćen putem Stripea.'
              : 'Želite li otkazati rezervaciju ${_reservation.confirmationCode}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Da, otkaži'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = context.read<ReservationsController>();
    final success = await controller.cancel(_reservation.id);
    if (!mounted) return;
    if (success) {
      setState(() {
        _reservation = controller.reservations.firstWhere(
          (reservation) => reservation.id == _reservation.id,
        );
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Rezervacija je otkazana.'
              : controller.errorMessage ?? 'Rezervaciju nije moguće otkazati.',
        ),
      ),
    );
  }

  Future<void> _review() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReviewFormScreen(reservation: _reservation),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dojam je poslan i čeka odobrenje.')),
      );
    }
  }

  Future<void> _reschedule() async {
    final updated = await Navigator.of(context).push<Reservation>(
      MaterialPageRoute<Reservation>(
        builder: (_) => ReservationRescheduleScreen(reservation: _reservation),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _reservation = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Novi termin je poslan vlasniku na potvrdu.'),
      ),
    );
  }

  Future<void> _pay() async {
    final payments = context.read<PaymentsController>();
    final result = await payments.pay(_reservation.id);
    if (!mounted) return;

    if (result == PaymentResult.succeeded) {
      final confirmation = await _waitForPaymentConfirmation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (confirmation) {
            _PaymentConfirmation.paid => 'Plaćanje je uspješno evidentirano.',
            _PaymentConfirmation.failed =>
              'Plaćanje nije uspjelo. Možete pokušati ponovo.',
            _PaymentConfirmation.pending =>
              'Plaćanje je prihvaćeno i čeka potvrdu servera.',
          }),
        ),
      );
      return;
    }

    final message = switch (result) {
      PaymentResult.succeeded => '',
      PaymentResult.canceled => 'Plaćanje je otkazano.',
      PaymentResult.failed =>
        payments.errorMessage ?? 'Plaćanje nije bilo uspješno.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_PaymentConfirmation> _waitForPaymentConfirmation() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return _PaymentConfirmation.pending;
      final updated = await context.read<ReservationsController>().refreshOne(
        _reservation.id,
      );
      if (!mounted) return _PaymentConfirmation.pending;
      if (updated != null) setState(() => _reservation = updated);
      if (updated?.paymentStatus == 'Paid') {
        context.read<PaymentsController>().resolveConfirmation(_reservation.id);
        return _PaymentConfirmation.paid;
      }
      if (updated?.paymentStatus == 'Failed') {
        context.read<PaymentsController>().resolveConfirmation(_reservation.id);
        return _PaymentConfirmation.failed;
      }
    }
    return _PaymentConfirmation.pending;
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    final updated = await context.read<ReservationsController>().refreshOne(
      _reservation.id,
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _reservation = updated);
      if (updated.paymentStatus == 'Paid' ||
          updated.paymentStatus == 'Failed') {
        context.read<PaymentsController>().resolveConfirmation(updated.id);
      }
    }
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsController>();
    final review = reviews.reviewForReservation(_reservation.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji rezervacije'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Osvježi podatke',
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            _reservation.cabinName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _reservation.confirmationCode,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.event_note_outlined,
                label: reservationStatus(_reservation.status),
              ),
              _StatusChip(
                icon: Icons.payments_outlined,
                label: paymentStatusLabel(_reservation.paymentStatus),
              ),
              _StatusChip(
                icon: Icons.nights_stay_outlined,
                label: '${_reservation.nights} noćenja',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DetailsSection(
            title: 'Boravak',
            icon: Icons.calendar_month_outlined,
            rows: [
              ('Dolazak', formatDate(_reservation.checkIn)),
              ('Odlazak', formatDate(_reservation.checkOut)),
              ('Odrasli', _reservation.adults.toString()),
              ('Djeca', _reservation.children.toString()),
            ],
          ),
          const SizedBox(height: 14),
          _PaymentSection(reservation: _reservation),
          if (_reservation.specialRequests?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _DetailsSection(
              title: 'Posebni zahtjevi',
              icon: Icons.notes_outlined,
              content: _reservation.specialRequests!.trim(),
            ),
          ],
          const SizedBox(height: 22),
          if (_reservation.canPay) ...[
            if (context.watch<PaymentsController>().isAwaitingConfirmation(
              _reservation.id,
            ))
              const _PaymentPendingNotice(),
            FilledButton.icon(
              onPressed:
                  context.watch<PaymentsController>().isProcessing ||
                      context
                          .watch<PaymentsController>()
                          .isAwaitingConfirmation(_reservation.id)
                  ? null
                  : _pay,
              icon: const Icon(Icons.credit_card_outlined),
              label: Text(
                context.watch<PaymentsController>().isAwaitingConfirmation(
                      _reservation.id,
                    )
                    ? 'Čeka potvrdu plaćanja'
                    : context.watch<PaymentsController>().isProcessing
                    ? 'Pokretanje plaćanja...'
                    : 'Plati rezervaciju',
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_reservation.canReschedule) ...[
            OutlinedButton.icon(
              onPressed: context.watch<ReservationsController>().isLoading
                  ? null
                  : _reschedule,
              icon: const Icon(Icons.event_repeat_outlined),
              label: const Text('Promijeni termin'),
            ),
            const SizedBox(height: 10),
          ],
          if (_reservation.canCancel)
            OutlinedButton.icon(
              onPressed: context.watch<ReservationsController>().isLoading
                  ? null
                  : _cancel,
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Otkaži rezervaciju'),
            ),
          if (_reservation.canReview) ...[
            if (review == null)
              FilledButton.tonalIcon(
                onPressed: reviews.isSubmitting ? null : _review,
                icon: const Icon(Icons.star_outline),
                label: const Text('Ostavi dojam'),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(
                    review.isApproved
                        ? Icons.check_circle_outline
                        : Icons.hourglass_top,
                    size: 18,
                  ),
                  label: Text(
                    review.isApproved
                        ? 'Dojam je objavljen'
                        : 'Dojam čeka odobrenje',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

enum _PaymentConfirmation { paid, failed, pending }

class _PaymentPendingNotice extends StatelessWidget {
  const _PaymentPendingNotice();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Stripe potvrda plaćanja je u toku.')),
          ],
        ),
      ),
    ),
  );
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.reservation});

  final Reservation reservation;

  String get _currency => reservation.paymentCurrency == 'BAM'
      ? 'KM'
      : reservation.paymentCurrency ?? 'KM';

  @override
  Widget build(BuildContext context) => _DetailsSection(
    title: 'Plaćanje',
    icon: Icons.account_balance_wallet_outlined,
    rows: [
      (
        'Cijena po noći',
        '${reservation.pricePerNight.toStringAsFixed(2)} $_currency',
      ),
      ('Broj noćenja', reservation.nights.toString()),
      ('Ukupno', '${reservation.totalPrice.toStringAsFixed(2)} $_currency'),
      ('Uplaćeno', '${reservation.paidAmount.toStringAsFixed(2)} $_currency'),
      (
        'Preostalo',
        '${reservation.remainingAmount.toStringAsFixed(2)} $_currency',
      ),
      ('Status', paymentStatusLabel(reservation.paymentStatus)),
      if (reservation.paidAtUtc != null)
        ('Datum uplate', formatDate(reservation.paidAtUtc!.toLocal())),
      if (reservation.paymentStatus == 'Refunded')
        (
          'Refundirano',
          '${reservation.refundedAmount.toStringAsFixed(2)} $_currency',
        ),
      if (reservation.refundedAtUtc != null)
        ('Datum povrata', formatDate(reservation.refundedAtUtc!.toLocal())),
    ],
  );
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    this.rows = const [],
    this.content,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;
  final String? content;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(height: 24),
          if (content != null)
            Text(content!, style: const TextStyle(height: 1.5)),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    row.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));
}
