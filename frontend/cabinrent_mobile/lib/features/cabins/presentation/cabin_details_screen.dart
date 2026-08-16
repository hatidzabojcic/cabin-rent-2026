import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/cabin_details.dart';
import '../domain/cabin_summary.dart';
import 'cabins_controller.dart';

class CabinDetailsScreen extends StatefulWidget {
  const CabinDetailsScreen({required this.summary, super.key});

  final CabinSummary summary;

  @override
  State<CabinDetailsScreen> createState() => _CabinDetailsScreenState();
}

class _CabinDetailsScreenState extends State<CabinDetailsScreen> {
  late Future<CabinDetails> _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _details = context.read<CabinsController>().getCabin(widget.summary.id);
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalji vikendice')),
    body: FutureBuilder<CabinDetails>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _LoadError(onRetry: _retry);
        }
        return _DetailsContent(
          details: snapshot.data!,
          averageRating: widget.summary.averageRating,
        );
      },
    ),
  );
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.details, this.averageRating});

  final CabinDetails details;
  final double? averageRating;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 32),
    children: [
      _Gallery(images: details.images),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    details.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (averageRating != null) _Rating(value: averageRating!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 19),
                const SizedBox(width: 5),
                Expanded(child: Text('${details.address}, ${details.city}')),
              ],
            ),
            const SizedBox(height: 18),
            _Price(price: details.pricePerNight),
            const SizedBox(height: 22),
            _Facts(details: details),
            const SizedBox(height: 26),
            const _SectionTitle('O vikendici'),
            const SizedBox(height: 9),
            Text(details.description, style: const TextStyle(height: 1.55)),
            if (details.amenities.isNotEmpty) ...[
              const SizedBox(height: 26),
              const _SectionTitle('Pogodnosti'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.amenities
                    .map(
                      (amenity) => Chip(
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(amenity.name),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 26),
            const _SectionTitle('Domaćin'),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(details.ownerName),
              subtitle: Text(details.cabinType),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<CabinImage> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox(
        height: 265,
        child: ColoredBox(
          color: Color(0xFFE3EBE7),
          child: Center(child: Icon(Icons.cabin_outlined, size: 72)),
        ),
      );
    }

    return SizedBox(
      height: 265,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, index) => Image.network(
              widget.images[index].resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE3EBE7),
                child: Center(
                  child: Icon(Icons.broken_image_outlined, size: 52),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              right: 14,
              bottom: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.details});

  final CabinDetails details;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _Fact(icon: Icons.people_outline, label: '${details.maxGuests} gostiju'),
      _Fact(
        icon: Icons.bed_outlined,
        label: '${details.bedrooms} spavaćih soba',
      ),
      _Fact(
        icon: Icons.bathtub_outlined,
        label: '${details.bathrooms} kupatila',
      ),
      _Fact(
        icon: Icons.square_foot_outlined,
        label: '${details.areaSquareMeters.toStringAsFixed(0)} m²',
      ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 19), const SizedBox(width: 7), Text(label)],
    ),
  );
}

class _Price extends StatelessWidget {
  const _Price({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '${price.toStringAsFixed(2)} KM',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const TextSpan(text: ' / noć'),
      ],
    ),
  );
}

class _Rating extends StatelessWidget {
  const _Rating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 19),
        const SizedBox(width: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 58),
          const SizedBox(height: 14),
          const Text(
            'Detalje vikendice trenutno nije moguće učitati.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    ),
  );
}
