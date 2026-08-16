import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/cabin_summary.dart';
import 'cabins_controller.dart';

class CabinsScreen extends StatefulWidget {
  const CabinsScreen({super.key});
  @override
  State<CabinsScreen> createState() => _CabinsScreenState();
}

class _CabinsScreenState extends State<CabinsScreen> {
  final _search = TextEditingController();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<CabinsController>();
      if (!c.hasLoaded) c.load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 450),
      () => context.read<CabinsController>().load(search: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CabinsController>();
    return RefreshIndicator(
      onRefresh: () => controller.load(search: _search.text),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Vikendice',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Pronađite smještaj za svoj sljedeći odmor.'),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  onChanged: _changed,
                  decoration: const InputDecoration(
                    hintText: 'Pretraži po nazivu ili gradu',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ]),
            ),
          ),
          if (controller.isLoading && controller.cabins.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.errorMessage != null && controller.cabins.isEmpty)
            SliverFillRemaining(
              child: _Message(
                message: controller.errorMessage!,
                onRetry: () => controller.load(search: _search.text),
              ),
            )
          else if (controller.cabins.isEmpty)
            const SliverFillRemaining(
              child: _Message(
                message: 'Nema vikendica koje odgovaraju pretrazi.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: controller.cabins.length,
                itemBuilder: (_, i) => _CabinCard(cabin: controller.cabins[i]),
                separatorBuilder: (_, _) => const SizedBox(height: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _CabinCard extends StatelessWidget {
  const _CabinCard({required this.cabin});
  final CabinSummary cabin;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: cabin.resolvedImageUrl == null
              ? const ColoredBox(
                  color: Color(0xFFE3EBE7),
                  child: Icon(Icons.cabin_outlined, size: 54),
                )
              : Image.network(
                  cabin.resolvedImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFE3EBE7),
                    child: Icon(Icons.broken_image_outlined, size: 42),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cabin.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (cabin.averageRating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        Text(cabin.averageRating!.toStringAsFixed(1)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text('${cabin.city}  •  do ${cabin.maxGuests} gostiju'),
              const SizedBox(height: 12),
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
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 110),
      const Icon(Icons.travel_explore, size: 58),
      const SizedBox(height: 14),
      Text(message, textAlign: TextAlign.center),
      if (onRetry != null)
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Pokušaj ponovo'),
          ),
        ),
    ],
  );
}
