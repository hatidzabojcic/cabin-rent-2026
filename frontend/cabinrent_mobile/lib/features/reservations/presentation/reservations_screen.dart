import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/reservation.dart';
import 'reservations_controller.dart';
import 'reservation_details_screen.dart';
import 'cancellation_reason_dialog.dart';
import 'reservation_grouping.dart';
import '../../reviews/presentation/review_form_screen.dart';
import '../../reviews/presentation/reviews_controller.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});
  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  String? _selectedStatus;

  static const _statusFilters = <({String? status, String label})>[
    (status: null, label: 'Sve'),
    (status: 'Pending', label: 'Na čekanju'),
    (status: 'Confirmed', label: 'Potvrđene'),
    (status: 'Completed', label: 'Završene'),
    (status: 'Cancelled', label: 'Otkazane'),
    (status: 'Rejected', label: 'Odbijene'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ReservationsController>();
      if (!c.hasLoaded) c.load();
      final reviews = context.read<ReviewsController>();
      if (!reviews.hasLoadedMine) reviews.loadMine();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReservationsController>();
    final reviews = context.read<ReviewsController>();
    final groups = groupReservationsByCheckIn(
      c.reservations,
      status: _selectedStatus,
    );
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([c.load(), reviews.loadMine()]);
      },
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
          else ...[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _statusFilters[index];
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: _selectedStatus == filter.status,
                      onSelected: (_) =>
                          setState(() => _selectedStatus = filter.status),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (groups.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _FilteredEmpty(),
              )
            else
              ...groups.map(
                (group) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  sliver: SliverList.separated(
                    itemCount: group.reservations.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _DayHeader(
                          date: group.date,
                          reservationCount: group.reservations.length,
                        );
                      }
                      return _ReservationCard(
                        reservation: group.reservations[index - 1],
                      );
                    },
                    separatorBuilder: (_, index) =>
                        SizedBox(height: index == 0 ? 8 : 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.reservationCount});

  final DateTime date;
  final int reservationCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Dolazak — ${reservationDayLabel(date)}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      Text('$reservationCount', style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Nema rezervacija sa odabranim statusom.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;
  @override
  Widget build(BuildContext context) {
    final c = context.read<ReservationsController>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReservationDetailsScreen(reservation: reservation),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.cabinName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(reservationStatus(reservation.status))),
                  Chip(
                    avatar: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(paymentStatusLabel(reservation.paymentStatus)),
                  ),
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
              if (reservation.remainingAmount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Preostalo za uplatu: '
                  '${reservation.remainingAmount.toStringAsFixed(2)} KM',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (reservation.canCancel) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final reason = await showCancellationReasonDialog(
                        context,
                        reservation,
                      );
                      if (reason != null) {
                        final ok = await c.cancel(reservation.id, reason);
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
              if (reservation.canReview) ...[
                const SizedBox(height: 12),
                Consumer<ReviewsController>(
                  builder: (context, reviews, _) => Align(
                    alignment: Alignment.centerRight,
                    child: reviews.wasSubmitted(reservation.id)
                        ? Chip(
                            avatar: Icon(
                              reviews
                                      .reviewForReservation(reservation.id)!
                                      .isApproved
                                  ? Icons.check_circle_outline
                                  : Icons.hourglass_top,
                              size: 18,
                            ),
                            label: Text(
                              reviews
                                      .reviewForReservation(reservation.id)!
                                      .isApproved
                                  ? 'Dojam je objavljen'
                                  : 'Dojam čeka odobrenje',
                            ),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: () async {
                              final submitted = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute<bool>(
                                      builder: (_) => ReviewFormScreen(
                                        reservation: reservation,
                                      ),
                                    ),
                                  );
                              if (submitted == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Dojam je poslan i čeka odobrenje.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Ostavi dojam'),
                          ),
                  ),
                ),
              ],
            ],
          ),
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
