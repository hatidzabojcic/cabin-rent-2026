import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cabins/domain/cabin_summary.dart';
import '../../cabins/presentation/cabin_details_screen.dart';
import '../../cabins/presentation/cabins_controller.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({this.onReservationCreated, super.key});

  final VoidCallback? onReservationCreated;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<FavoritesController>();
      if (!controller.hasLoaded) controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FavoritesController>();
    final cabins = context.watch<CabinsController>().cabins;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            'Omiljene',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Vikendice koje ste sačuvali za kasnije.'),
          const SizedBox(height: 20),
          if (controller.isLoading && controller.favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.errorMessage != null &&
              controller.favorites.isEmpty)
            _EmptyState(
              icon: Icons.cloud_off_outlined,
              message: controller.errorMessage!,
              action: controller.load,
            )
          else if (controller.favorites.isEmpty)
            const _EmptyState(
              icon: Icons.favorite_border,
              message: 'Još niste sačuvali nijednu vikendicu.',
            )
          else
            ...controller.favorites.map((favorite) {
              final cabin = _findCabin(cabins, favorite.cabinId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    leading: const CircleAvatar(
                      child: Icon(Icons.cabin_outlined),
                    ),
                    title: Text(
                      favorite.cabinName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${favorite.pricePerNight.toStringAsFixed(2)} KM / noć',
                    ),
                    trailing: IconButton(
                      tooltip: 'Ukloni iz omiljenih',
                      onPressed: controller.isUpdating(favorite.cabinId)
                          ? null
                          : () => controller.toggle(favorite.cabinId),
                      icon: const Icon(Icons.favorite, color: Colors.red),
                    ),
                    onTap: cabin == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CabinDetailsScreen(
                                summary: cabin,
                                onReservationCreated:
                                    widget.onReservationCreated,
                              ),
                            ),
                          ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  CabinSummary? _findCabin(List<CabinSummary> cabins, int id) {
    for (final cabin in cabins) {
      if (cabin.id == id) return cabin;
    }
    return null;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 90),
    child: Column(
      children: [
        Icon(icon, size: 58),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        if (action != null)
          TextButton(onPressed: action, child: const Text('Pokušaj ponovo')),
      ],
    ),
  );
}
