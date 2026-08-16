import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/cabin_search_criteria.dart';
import '../domain/cabin_summary.dart';
import 'cabin_details_screen.dart';
import 'cabins_controller.dart';

class CabinsScreen extends StatefulWidget {
  const CabinsScreen({super.key});
  @override
  State<CabinsScreen> createState() => _CabinsScreenState();
}

class _CabinsScreenState extends State<CabinsScreen> {
  final _search = TextEditingController();
  Timer? _timer;
  DateTimeRange? _selectedRange;
  int _guests = 2;
  bool _initializedFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<CabinsController>();
      if (!c.hasLoaded) c.load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFilters) return;
    final criteria = context.read<CabinsController>().criteria;
    if (criteria != null) {
      _selectedRange = DateTimeRange(
        start: criteria.checkIn,
        end: criteria.checkOut,
      );
      _guests = criteria.guests;
    }
    _initializedFilters = true;
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

  Future<void> _selectDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final initialRange =
        _selectedRange != null && !_selectedRange!.start.isBefore(today)
        ? _selectedRange
        : DateTimeRange(
            start: tomorrow,
            end: tomorrow.add(const Duration(days: 2)),
          );
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      initialDateRange: initialRange,
      helpText: 'Odaberite termin boravka',
      cancelText: 'Odustani',
      confirmText: 'Potvrdi',
      saveText: 'Sačuvaj',
    );
    if (range != null && mounted) setState(() => _selectedRange = range);
  }

  Future<void> _applyAvailability() async {
    final range = _selectedRange;
    if (range == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prvo odaberite datum dolaska i odlaska.'),
        ),
      );
      return;
    }
    await context.read<CabinsController>().applyAvailability(
      CabinSearchCriteria(
        checkIn: range.start,
        checkOut: range.end,
        guests: _guests,
      ),
    );
  }

  Future<void> _clearAvailability() async {
    setState(() {
      _selectedRange = null;
      _guests = 2;
    });
    await context.read<CabinsController>().clearAvailability();
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
                const SizedBox(height: 14),
                _AvailabilitySearch(
                  selectedRange: _selectedRange,
                  guests: _guests,
                  isApplied: controller.criteria != null,
                  isLoading: controller.isLoading,
                  onSelectDates: _selectDates,
                  onGuestsChanged: (value) => setState(() => _guests = value),
                  onApply: _applyAvailability,
                  onClear: _clearAvailability,
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
                itemBuilder: (_, i) => _CabinCard(
                  cabin: controller.cabins[i],
                  criteria: controller.criteria,
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _CabinCard extends StatelessWidget {
  const _CabinCard({required this.cabin, this.criteria});
  final CabinSummary cabin;
  final CabinSearchCriteria? criteria;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              CabinDetailsScreen(summary: cabin, searchCriteria: criteria),
        ),
      ),
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
                    if (cabin.averageRating != null) ...[
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      Text(cabin.averageRating!.toStringAsFixed(1)),
                    ],
                    const SizedBox(width: 5),
                    const Icon(Icons.chevron_right),
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
    ),
  );
}

class _AvailabilitySearch extends StatelessWidget {
  const _AvailabilitySearch({
    required this.selectedRange,
    required this.guests,
    required this.isApplied,
    required this.isLoading,
    required this.onSelectDates,
    required this.onGuestsChanged,
    required this.onApply,
    required this.onClear,
  });

  final DateTimeRange? selectedRange;
  final int guests;
  final bool isApplied;
  final bool isLoading;
  final VoidCallback onSelectDates;
  final ValueChanged<int> onGuestsChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}.';

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_outlined),
              const SizedBox(width: 8),
              Text(
                'Provjeri dostupnost',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 13),
          InkWell(
            onTap: isLoading ? null : onSelectDates,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Dolazak i odlazak',
                prefixIcon: Icon(Icons.date_range_outlined),
              ),
              child: Text(
                selectedRange == null
                    ? 'Odaberite termin'
                    : '${_date(selectedRange!.start)} – ${_date(selectedRange!.end)}',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD7DDD8)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 10),
                const Expanded(child: Text('Broj gostiju')),
                IconButton(
                  onPressed: isLoading || guests <= 1
                      ? null
                      : () => onGuestsChanged(guests - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Smanji broj gostiju',
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$guests',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: isLoading || guests >= 30
                      ? null
                      : () => onGuestsChanged(guests + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Povećaj broj gostiju',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isApplied) ...[
                TextButton(
                  onPressed: isLoading ? null : onClear,
                  child: const Text('Poništi'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onApply,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Prikaži slobodne vikendice'),
                ),
              ),
            ],
          ),
        ],
      ),
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
