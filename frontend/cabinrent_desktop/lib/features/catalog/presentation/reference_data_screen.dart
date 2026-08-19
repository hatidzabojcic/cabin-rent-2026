import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/reference_data_repository.dart';
import '../domain/reference_data.dart';

class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen> {
  final _searchController = TextEditingController();
  ReferenceKind _kind = ReferenceKind.countries;
  ReferencePage? _data;
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<ReferenceDataRepository>().getPage(
        _kind,
        page: _page,
        search: _searchController.text,
      );
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _page = 1;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u0160ifrarnici',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text('Upravljanje referentnim podacima aplikacije.'),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _loading ? null : () => _openForm(),
              icon: const Icon(Icons.add),
              label: Text('Dodaj: ${_kind.label.toLowerCase()}'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReferenceKind.values
              .map(
                (kind) => ChoiceChip(
                  label: Text(kind.label),
                  selected: kind == _kind,
                  onSelected: (_) {
                    setState(() {
                      _kind = kind;
                      _page = 1;
                      _searchController.clear();
                    });
                    _load();
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 390,
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Pretra\u017ei po nazivu',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _content()),
      ],
    ),
  );

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Podatke nije mogu\u0107e u\u010ditati.\n$_error'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Poku\u0161aj ponovo'),
            ),
          ],
        ),
      );
    }
    final data = _data!;
    return Column(
      children: [
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: data.items.isEmpty
                ? const Center(child: Text('Nema podataka za odabrani filter.'))
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Naziv')),
                          DataColumn(label: Text('Dodatni podaci')),
                          DataColumn(label: Text('Akcije')),
                        ],
                        rows: data.items
                            .map(
                              (item) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(item.details)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Uredi',
                                          onPressed: () => _openForm(item),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Obri\u0161i',
                                          color: Colors.red.shade700,
                                          onPressed: () => _confirmDelete(item),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('${data.totalCount} zapisa'),
            const SizedBox(width: 18),
            IconButton(
              tooltip: 'Prethodna stranica',
              onPressed: data.page > 1
                  ? () {
                      _page--;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${data.page} / ${data.totalPages}'),
            IconButton(
              tooltip: 'Sljede\u0107a stranica',
              onPressed: data.page < data.totalPages
                  ? () {
                      _page++;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openForm([ReferenceItem? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReferenceFormDialog(kind: _kind, item: item),
    );
    if (saved == true) await _load();
  }

  Future<void> _confirmDelete(ReferenceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text(
          'Da li sigurno \u017eelite obrisati zapis „${item.name}“?\n\n'
          'Brisanje ne\u0107e biti dozvoljeno ako zapis koriste drugi podaci.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obri\u0161i'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ReferenceDataRepository>().delete(_kind, item.id);
      if (_data?.items.length == 1 && _page > 1) _page--;
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _ReferenceFormDialog extends StatefulWidget {
  const _ReferenceFormDialog({required this.kind, this.item});
  final ReferenceKind kind;
  final ReferenceItem? item;

  @override
  State<_ReferenceFormDialog> createState() => _ReferenceFormDialogState();
}

class _ReferenceFormDialogState extends State<_ReferenceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _secondary;
  List<ReferenceItem> _countries = [];
  int? _countryId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _secondary = TextEditingController(
      text: switch (widget.kind) {
        ReferenceKind.countries => item?.isoCode ?? '',
        ReferenceKind.cities => item?.postalCode ?? '',
        ReferenceKind.cabinTypes ||
        ReferenceKind.roles => item?.description ?? '',
        ReferenceKind.amenities => item?.icon ?? '',
      },
    );
    _countryId = item?.countryId;
    if (widget.kind == ReferenceKind.cities) _loadCountries();
  }

  @override
  void dispose() {
    _name.dispose();
    _secondary.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await context
          .read<ReferenceDataRepository>()
          .getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _countryId ??= countries.firstOrNull?.id;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Dodaj zapis' : 'Uredi zapis'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Naziv'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Naziv je obavezan.'
                  : null,
            ),
            const SizedBox(height: 14),
            if (widget.kind == ReferenceKind.cities) ...[
              DropdownButtonFormField<int>(
                initialValue: _countryId,
                decoration: const InputDecoration(labelText: 'Dr\u017eava'),
                items: _countries
                    .map(
                      (country) => DropdownMenuItem(
                        value: country.id,
                        child: Text(country.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _countryId = value),
                validator: (value) =>
                    value == null ? 'Odaberite dr\u017eavu.' : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _secondary,
              textCapitalization: widget.kind == ReferenceKind.countries
                  ? TextCapitalization.characters
                  : TextCapitalization.sentences,
              decoration: InputDecoration(labelText: _secondaryLabel),
              validator: widget.kind == ReferenceKind.countries
                  ? (value) => value?.trim().length == 2
                        ? null
                        : 'ISO oznaka mora imati dva slova.'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _loading ? null : () => Navigator.pop(context),
        child: const Text('Odustani'),
      ),
      FilledButton.icon(
        onPressed: _loading ? null : _save,
        icon: _loading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: const Text('Sa\u010duvaj'),
      ),
    ],
  );

  String get _secondaryLabel => switch (widget.kind) {
    ReferenceKind.countries => 'ISO oznaka',
    ReferenceKind.cities => 'Po\u0161tanski broj (opcionalno)',
    ReferenceKind.cabinTypes || ReferenceKind.roles => 'Opis (opcionalno)',
    ReferenceKind.amenities => 'Ikona (opcionalno)',
  };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final secondary = _secondary.text.trim();
      final body = <String, dynamic>{'name': _name.text.trim()};
      switch (widget.kind) {
        case ReferenceKind.countries:
          body['isoCode'] = secondary.toUpperCase();
        case ReferenceKind.cities:
          body['postalCode'] = secondary.isEmpty ? null : secondary;
          body['countryId'] = _countryId;
        case ReferenceKind.cabinTypes:
          body['description'] = secondary.isEmpty ? null : secondary;
        case ReferenceKind.amenities:
          body['icon'] = secondary.isEmpty ? null : secondary;
        case ReferenceKind.roles:
          body['description'] = secondary.isEmpty ? null : secondary;
      }
      final repository = context.read<ReferenceDataRepository>();
      if (widget.item == null) {
        await repository.create(widget.kind, body);
      } else {
        await repository.update(widget.kind, widget.item!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
