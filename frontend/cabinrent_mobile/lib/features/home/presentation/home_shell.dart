import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cabins/presentation/cabin_details_screen.dart';
import '../../cabins/presentation/cabins_screen.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reservations/presentation/reservations_controller.dart';
import '../../reservations/presentation/reservations_screen.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../recommendations/presentation/recommendations_controller.dart';
import '../../announcements/data/announcements_repository.dart';
import '../../announcements/domain/announcement.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final NotificationsController _notificationsController;

  @override
  void initState() {
    super.initState();
    _notificationsController = context.read<NotificationsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notificationsController.start();
      context.read<FavoritesController>().load();
      context.read<RecommendationsController>().load();
    });
  }

  @override
  void dispose() {
    _notificationsController.stop();
    super.dispose();
  }

  void _showReservations() {
    context.read<ReservationsController>().load();
    setState(() => _index = 2);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsController>().unreadCount;
    final pages = [
      _WelcomePage(
        onExplore: () => setState(() => _index = 1),
        onReservationCreated: _showReservations,
      ),
      CabinsScreen(onReservationCreated: _showReservations),
      const ReservationsScreen(),
      FavoritesScreen(onReservationCreated: _showReservations),
      NotificationsScreen(onOpenReservations: _showReservations),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Početna',
          ),
          const NavigationDestination(
            icon: Icon(Icons.cabin_outlined),
            selectedIcon: Icon(Icons.cabin),
            label: 'Vikendice',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Rezervacije',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Omiljene',
          ),
          NavigationDestination(
            icon: _NotificationIcon(count: unreadCount),
            selectedIcon: _NotificationIcon(count: unreadCount, selected: true),
            label: 'Obavijesti',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.count, this.selected = false});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 99 ? '99+' : count.toString()),
    child: Icon(selected ? Icons.notifications : Icons.notifications_outlined),
  );
}

class _WelcomePage extends StatefulWidget {
  const _WelcomePage({
    required this.onExplore,
    required this.onReservationCreated,
  });

  final VoidCallback onExplore;
  final VoidCallback onReservationCreated;

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage> {
  int? _favoriteRevision;
  Future<List<Announcement>>? _announcements;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcements ??= context.read<AnnouncementsRepository>().getPublished();
    final revision = context.watch<FavoritesController>().revision;
    if (_favoriteRevision == null) {
      _favoriteRevision = revision;
    } else if (_favoriteRevision != revision) {
      _favoriteRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<RecommendationsController>().load();
      });
    }
  }

  Future<void> _refresh() async {
    final announcements = context.read<AnnouncementsRepository>().getPublished();
    setState(() => _announcements = announcements);
    await Future.wait([
      announcements,
      context.read<RecommendationsController>().load(),
      context.read<FavoritesController>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    final controller = context.watch<RecommendationsController>();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
        const SizedBox(height: 12),
        Text(
          'Pozdrav, ${user.firstName}',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Vrijeme je za planiranje sljedećeg odmora.'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Novosti',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(onPressed: _refresh, tooltip: 'Osvježi', icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Announcement>>(
          future: _announcements,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()));
            }
            final items = snapshot.data ?? const <Announcement>[];
            return Column(children: items.take(3).map((item) => _AnnouncementCard(item: item)).toList());
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.isPersonalized
                    ? 'Preporučeno za vas'
                    : 'Izdvajamo za vas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: widget.onExplore,
              child: const Text('Sve vikendice'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          controller.isPersonalized
              ? 'Prijedlozi na osnovu vaših dosadašnjih odabira.'
              : 'Popularne i dobro ocijenjene vikendice za prvi odabir.',
        ),
        const SizedBox(height: 16),
        if (controller.isLoading && controller.recommendations.isEmpty)
          const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.errorMessage != null &&
            controller.recommendations.isEmpty)
          _RecommendationMessage(
            message: controller.errorMessage!,
            onRetry: controller.load,
          )
        else if (controller.recommendations.isEmpty)
          _RecommendationMessage(
            message:
                'Trenutno nema novih preporuka. Sačuvali ste, posjetili ili već rezervisali dostupne prijedloge.',
            onRetry: controller.load,
          )
        else
          ...controller.recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RecommendationCard(
                recommendation: recommendation,
                onReservationCreated: widget.onReservationCreated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        SizedBox(
          width: 80,
          height: 96,
          child: item.imageUrl == null
              ? const ColoredBox(color: Color(0xFFE3EBE7), child: Icon(Icons.campaign_outlined))
              : Image.network(item.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE3EBE7), child: Icon(Icons.campaign_outlined))),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(_announcementDate(item.publishedAtUtc), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ],
    ),
  );
}

String _announcementDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onReservationCreated,
  });

  final Recommendation recommendation;
  final VoidCallback onReservationCreated;

  @override
  Widget build(BuildContext context) {
    final cabin = recommendation.cabin;
    final favorites = context.watch<FavoritesController>();
    final isFavorite = favorites.contains(cabin.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CabinDetailsScreen(
              summary: cabin,
              onReservationCreated: onReservationCreated,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 155,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  cabin.resolvedImageUrl == null
                      ? const ColoredBox(
                          color: Color(0xFFE3EBE7),
                          child: Icon(Icons.cabin_outlined, size: 52),
                        )
                      : Image.network(
                          cabin.resolvedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFE3EBE7),
                            child: Icon(Icons.broken_image_outlined, size: 42),
                          ),
                        ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: isFavorite
                            ? 'Ukloni iz omiljenih'
                            : 'Dodaj u omiljene',
                        onPressed: favorites.isUpdating(cabin.id)
                            ? null
                            : () async {
                                final success = await favorites.toggle(
                                  cabin.id,
                                );
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(favorites.errorMessage!),
                                    ),
                                  );
                                }
                              },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cabin.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (cabin.averageRating != null) ...[
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(cabin.averageRating!.toStringAsFixed(1)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('${cabin.city} • do ${cabin.maxGuests} gostiju'),
                  const SizedBox(height: 10),
                  Text(
                    recommendation.reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${cabin.pricePerNight.toStringAsFixed(2)} KM / noć',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationMessage extends StatelessWidget {
  const _RecommendationMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.travel_explore, size: 48),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
        ],
      ),
    ),
  );
}
