import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cabins/presentation/cabins_screen.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reservations/presentation/reservations_controller.dart';
import '../../reservations/presentation/reservations_screen.dart';

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
      const _WelcomePage(),
      CabinsScreen(onReservationCreated: _showReservations),
      const ReservationsScreen(),
      NotificationsScreen(onOpenReservations: _showReservations),
      const _ProfilePage(),
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    return ListView(
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
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.landscape_outlined,
                  size: 38,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Pronađite idealnu vikendicu',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'U narednoj fazi ovdje povezujemo katalog, filtere, galeriju slika i preporuke prilagođene gostu.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>(), user = auth.user!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Text(
          'Moj profil',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  child: Text(
                    user.firstName.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text('@${user.userName}'),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Telefon'),
                  subtitle: Text(
                    user.phoneNumber?.isNotEmpty == true
                        ? user.phoneNumber!
                        : 'Nije unesen',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : auth.logout,
          icon: const Icon(Icons.logout),
          label: const Text('Odjavi se'),
        ),
      ],
    );
  }
}
