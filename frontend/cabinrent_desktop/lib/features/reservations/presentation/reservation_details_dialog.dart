import 'package:flutter/material.dart';

import '../domain/reservation.dart';

class ReservationDetailsDialog extends StatelessWidget {
  const ReservationDetailsDialog({
    super.key,
    required this.reservation,
    required this.onStatusSelected,
  });

  final Reservation reservation;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Icon(Icons.event_note_outlined),
        const SizedBox(width: 12),
        Expanded(child: Text('Rezervacija ${reservation.confirmationCode}')),
      ],
    ),
    content: SizedBox(
      width: 650,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  icon: Icons.info_outline,
                  label: ReservationLabels.status(reservation.status),
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: ReservationLabels.payment(reservation.paymentStatus),
                ),
                _InfoChip(
                  icon: Icons.nights_stay_outlined,
                  label: '${reservation.nights} noćenja',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Boravak',
              rows: [
                ('Vikendica', reservation.cabinName),
                ('Dolazak', formatDate(reservation.checkIn)),
                ('Odlazak', formatDate(reservation.checkOut)),
                (
                  'Gosti',
                  '${reservation.adults} odraslih, ${reservation.children} djece',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Gost',
              rows: [
                ('Ime i prezime', reservation.guestName),
                ('Email', reservation.guestEmail),
                ('Telefon', reservation.guestPhoneNumber ?? 'Nije unesen'),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Cijena',
              rows: [
                (
                  'Po noći',
                  '${reservation.pricePerNight.toStringAsFixed(2)} KM',
                ),
                ('Ukupno', '${reservation.totalPrice.toStringAsFixed(2)} KM'),
              ],
            ),
            if (reservation.specialRequests?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 20),
              const Text(
                'Posebni zahtjevi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(reservation.specialRequests!),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zatvori'),
      ),
      if (reservation.allowedNextStatuses.isNotEmpty)
        PopupMenuButton<String>(
          onSelected: (status) {
            Navigator.pop(context);
            onStatusSelected(status);
          },
          itemBuilder: (_) => reservation.allowedNextStatuses
              .map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(ReservationLabels.status(status)),
                ),
              )
              .toList(),
          child: IgnorePointer(
            child: FilledButton(
              onPressed: () {},
              child: const Text('Promijeni status'),
            ),
          ),
        ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      ...rows.map(
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  row.$1,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              Expanded(
                child: Text(
                  row.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
