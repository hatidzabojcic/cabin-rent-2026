import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cabins_repository.dart';
import '../domain/cabin.dart';

class CabinsScreen extends StatefulWidget {
  const CabinsScreen({super.key});
  @override
  State<CabinsScreen> createState() => _CabinsScreenState();
}

class _CabinsScreenState extends State<CabinsScreen> {
  late Future<List<Cabin>> _cabins;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _cabins = context.read<CabinsRepository>().getCabins(
    search: _search.text,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vikendice',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('Pregled smještajnih jedinica iz CabinRent baze.'),
        const SizedBox(height: 22),
        SizedBox(
          width: 420,
          child: TextField(
            controller: _search,
            onSubmitted: (_) => setState(() {
              _load();
            }),
            decoration: InputDecoration(
              hintText: 'Pretraži po nazivu ili gradu',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  _load();
                }),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: FutureBuilder<List<Cabin>>(
            future: _cabins,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Podatke nije moguće učitati.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final cabins = snapshot.data ?? [];
              if (cabins.isEmpty) {
                return const Center(child: Text('Nema pronađenih vikendica.'));
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: 215,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: cabins.length,
                itemBuilder: (_, index) => _CabinCard(cabin: cabins[index]),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _CabinCard extends StatelessWidget {
  const _CabinCard({required this.cabin});
  final Cabin cabin;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: const Icon(Icons.cabin_outlined)),
              const Spacer(),
              if (cabin.averageRating != null)
                Text('★ ${cabin.averageRating!.toStringAsFixed(1)}'),
            ],
          ),
          const Spacer(),
          Text(
            cabin.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('${cabin.city}  •  do ${cabin.maxGuests} gostiju'),
          const SizedBox(height: 14),
          Text(
            '${cabin.pricePerNight.toStringAsFixed(2)} KM / noć',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
