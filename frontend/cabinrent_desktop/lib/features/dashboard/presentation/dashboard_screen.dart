import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pozdrav, ${user.firstName}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Prijavljeni ste kao ${user.roles.join(', ')}.'),
          const SizedBox(height: 28),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _OverviewCard(
                icon: Icons.cabin_outlined,
                title: 'Vikendice',
                description: 'Pregledajte ponudu i osnovne podatke.',
                onTap: () => onNavigate(1),
              ),
              _OverviewCard(
                icon: Icons.calendar_month_outlined,
                title: 'Rezervacije',
                description:
                    'Pregledajte rezervacije i mijenjajte njihove statuse.',
                onTap: () => onNavigate(2),
              ),
              _OverviewCard(
                icon: Icons.rate_review_outlined,
                title: 'Recenzije',
                description:
                    'Pregledajte ocjene gostiju i upravljajte njihovom vidljivošću.',
                onTap: () => onNavigate(3),
              ),
              _OverviewCard(
                icon: Icons.bar_chart_outlined,
                title: 'Izvještaji',
                description: 'Pratite godišnju posjećenost i ostvareni prihod.',
                onTap: () => onNavigate(4),
              ),
              _OverviewCard(
                icon: Icons.notifications_outlined,
                title: 'Obavijesti',
                description: 'Pratite novosti o rezervacijama i recenzijama.',
                onTap: () => onNavigate(5),
              ),
              if (user.isAdmin)
                _OverviewCard(
                  icon: Icons.people_outline,
                  title: 'Korisnici',
                  description: 'Administratorski pregled korisnika i uloga.',
                  onTap: () => onNavigate(6),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 270,
    height: 160,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(description, maxLines: 2),
            ],
          ),
        ),
      ),
    ),
  );
}
