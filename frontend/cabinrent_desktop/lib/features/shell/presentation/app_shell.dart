import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cabins/presentation/cabins_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../reservations/presentation/reservations_screen.dart';
import '../../reviews/presentation/reviews_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../users/presentation/users_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user!;
    final unreadCount = context.watch<NotificationsController>().unreadCount;
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Početna'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.cabin_outlined),
        selectedIcon: Icon(Icons.cabin),
        label: Text('Vikendice'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: Text('Rezervacije'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.rate_review_outlined),
        selectedIcon: Icon(Icons.rate_review),
        label: Text('Recenzije'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: Text('Izvještaji'),
      ),
      NavigationRailDestination(
        icon: _NotificationIcon(count: unreadCount),
        selectedIcon: _NotificationIcon(count: unreadCount, selected: true),
        label: const Text('Obavijesti'),
      ),
      if (user.isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Korisnici'),
        ),
    ];
    final screens = <Widget>[
      const DashboardScreen(),
      const CabinsScreen(),
      const ReservationsScreen(),
      const ReviewsScreen(),
      const ReportsScreen(),
      const NotificationsScreen(),
      if (user.isAdmin) const UsersScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            color: AppTheme.forest,
            child: NavigationRail(
              backgroundColor: AppTheme.forest,
              indicatorColor: AppTheme.sand,
              selectedIconTheme: const IconThemeData(color: AppTheme.forest),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
              extended: true,
              minExtendedWidth: 220,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Row(
                  children: [
                    Icon(Icons.cabin_rounded, color: AppTheme.sand),
                    SizedBox(width: 10),
                    Text(
                      'CabinRent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: destinations,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => _selectedIndex = value),
              trailing: Expanded(
                child: SizedBox(
                  width: 220,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: ListTile(
                        textColor: Colors.white,
                        iconColor: Colors.white70,
                        leading: const Icon(Icons.account_circle_outlined),
                        title: Text(
                          user.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          user.roles.join(', '),
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: IconButton(
                          tooltip: 'Odjava',
                          onPressed: auth.logout,
                          icon: const Icon(Icons.logout),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: screens),
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
