import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
              const _OverviewCard(
                icon: Icons.cabin_outlined,
                title: 'Vikendice',
                description: 'Pregledajte ponudu i osnovne podatke.',
              ),
              const _OverviewCard(
                icon: Icons.calendar_month_outlined,
                title: 'Rezervacije',
                description:
                    'Pregledajte rezervacije i mijenjajte njihove statuse.',
              ),
              const _OverviewCard(
                icon: Icons.rate_review_outlined,
                title: 'Recenzije',
                description:
                    'Pregledajte ocjene gostiju i upravljajte njihovom vidljivošću.',
              ),
              const _OverviewCard(
                icon: Icons.bar_chart_outlined,
                title: 'Izvještaji',
                description: 'Pratite godišnju posjećenost i ostvareni prihod.',
              ),
              if (user.isAdmin)
                const _OverviewCard(
                  icon: Icons.people_outline,
                  title: 'Korisnici',
                  description: 'Administratorski pregled korisnika i uloga.',
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
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 270,
    height: 160,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(description, maxLines: 2),
          ],
        ),
      ),
    ),
  );
}
