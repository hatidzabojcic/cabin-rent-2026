import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/reservation.dart';
import 'reservations_controller.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});
  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ReservationsController>();
      if (!c.hasLoaded) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReservationsController>();
    return RefreshIndicator(
      onRefresh: c.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Moje rezervacije',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Pregledajte svoje boravke i njihove statuse.'),
              ]),
            ),
          ),
          if (c.isLoading && c.reservations.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (c.errorMessage != null && c.reservations.isEmpty)
            SliverFillRemaining(
              child: _Empty(message: c.errorMessage!, retry: c.load),
            )
          else if (c.reservations.isEmpty)
            const SliverFillRemaining(
              child: _Empty(message: 'Još nemate rezervacija.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: c.reservations.length,
                itemBuilder: (_, i) =>
                    _ReservationCard(reservation: c.reservations[i]),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;
  @override
  Widget build(BuildContext context) {
    final c = context.read<ReservationsController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.cabinName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(label: Text(reservationStatus(reservation.status))),
              ],
            ),
            Text(
              reservation.confirmationCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 19),
                const SizedBox(width: 8),
                Text(
                  '${formatDate(reservation.checkIn)} – ${formatDate(reservation.checkOut)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 19),
                const SizedBox(width: 8),
                Text(
                  '${reservation.adults} odraslih, ${reservation.children} djece',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${reservation.totalPrice.toStringAsFixed(2)} KM',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (reservation.canCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Otkazati rezervaciju?'),
                        content: Text(
                          'Želite li otkazati ${reservation.confirmationCode}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Ne'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Da, otkaži'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final ok = await c.cancel(reservation.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Rezervacija je otkazana.'
                                  : c.errorMessage ?? 'Došlo je do greške.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Otkaži rezervaciju'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.retry});
  final String message;
  final Future<void> Function()? retry;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 120),
      const Icon(Icons.event_busy_outlined, size: 56),
      const SizedBox(height: 14),
      Text(message, textAlign: TextAlign.center),
      if (retry != null)
        Center(
          child: TextButton(
            onPressed: retry,
            child: const Text('Pokušaj ponovo'),
          ),
        ),
    ],
  );
}
