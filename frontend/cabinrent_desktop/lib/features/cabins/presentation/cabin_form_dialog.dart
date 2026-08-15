import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin.dart';

class CabinFormDialog extends StatefulWidget {
  const CabinFormDialog({super.key, this.cabin});
  final Cabin? cabin;
  @override
  State<CabinFormDialog> createState() => _CabinFormDialogState();
}

class _CabinFormDialogState extends State<CabinFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  List<CatalogOption> _cities = [];
  List<CatalogOption> _types = [];
  List<CatalogOption> _amenities = [];
  List<OwnerOption> _owners = [];
  late Set<int> _amenityIds;
  int? _cityId;
  int? _typeId;
  int? _ownerId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cabin = widget.cabin;
    _fields = {
      'name': TextEditingController(text: cabin?.name),
      'description': TextEditingController(text: cabin?.description),
      'address': TextEditingController(text: cabin?.address),
      'area': TextEditingController(text: cabin?.areaSquareMeters.toString()),
      'price': TextEditingController(text: cabin?.pricePerNight.toString()),
      'adults': TextEditingController(text: (cabin?.maxAdults ?? 1).toString()),
      'children': TextEditingController(
        text: (cabin?.maxChildren ?? 0).toString(),
      ),
      'bedrooms': TextEditingController(
        text: (cabin?.bedrooms ?? 1).toString(),
      ),
      'bathrooms': TextEditingController(
        text: (cabin?.bathrooms ?? 1).toString(),
      ),
      'latitude': TextEditingController(text: cabin?.latitude?.toString()),
      'longitude': TextEditingController(text: cabin?.longitude?.toString()),
    };
    _cityId = cabin?.cityId;
    _typeId = cabin?.cabinTypeId;
    _ownerId = cabin?.ownerId;
    _amenityIds = {...?cabin?.amenityIds};
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final repository = context.read<CabinsRepository>();
      final isAdmin = context.read<AuthController>().user!.isAdmin;
      final results = await Future.wait([
        repository.getCities(),
        repository.getCabinTypes(),
        repository.getAmenities(),
        if (isAdmin) repository.getOwners(),
      ]);
      if (!mounted) return;
      setState(() {
        _cities = results[0] as List<CatalogOption>;
        _types = results[1] as List<CatalogOption>;
        _amenities = results[2] as List<CatalogOption>;
        if (isAdmin) _owners = results[3] as List<OwnerOption>;
        _cityId ??= _cities.firstOrNull?.id;
        _typeId ??= _types.firstOrNull?.id;
        _ownerId ??= _owners.firstOrNull?.id;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;

  String? _positiveNumber(String? value) {
    final number = double.tryParse(value?.replaceAll(',', '.') ?? '');
    return number != null && number > 0 ? null : 'Unesite broj veći od 0.';
  }

  String? _nonNegativeInt(String? value) {
    final number = int.tryParse(value ?? '');
    return number != null && number >= 0
        ? null
        : 'Unesite cijeli broj 0 ili veći.';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _cityId == null ||
        _typeId == null) {
      return;
    }
    final isAdmin = context.read<AuthController>().user!.isAdmin;
    if (isAdmin && _ownerId == null) {
      setState(() => _error = 'Odaberite vlasnika vikendice.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = CabinFormData(
      name: _fields['name']!.text.trim(),
      description: _fields['description']!.text.trim(),
      address: _fields['address']!.text.trim(),
      areaSquareMeters: double.parse(
        _fields['area']!.text.replaceAll(',', '.'),
      ),
      pricePerNight: double.parse(_fields['price']!.text.replaceAll(',', '.')),
      maxAdults: int.parse(_fields['adults']!.text),
      maxChildren: int.parse(_fields['children']!.text),
      bedrooms: int.parse(_fields['bedrooms']!.text),
      bathrooms: int.parse(_fields['bathrooms']!.text),
      cityId: _cityId!,
      cabinTypeId: _typeId!,
      ownerId: isAdmin ? _ownerId : null,
      amenityIds: _amenityIds,
      latitude: double.tryParse(_fields['latitude']!.text.replaceAll(',', '.')),
      longitude: double.tryParse(
        _fields['longitude']!.text.replaceAll(',', '.'),
      ),
      coverImageUrl: null,
    );
    try {
      final repository = context.read<CabinsRepository>();
      if (widget.cabin == null) {
        await repository.create(data);
      } else {
        await repository.update(widget.cabin!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Podatke nije moguće sačuvati. Provjerite unesene vrijednosti.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthController>().user!.isAdmin;
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 720,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.cabin == null
                          ? 'Nova vikendica'
                          : 'Uredi vikendicu',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _cities.isEmpty
                  ? Center(child: Text(_error!))
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle('Osnovni podaci'),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'name',
                                    'Naziv',
                                    validator: _required,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _textField(
                                    'address',
                                    'Adresa',
                                    validator: _required,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fields['description'],
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Opis',
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Kategorija i vlasništvo'),
                            Row(
                              children: [
                                Expanded(
                                  child: _dropdown(
                                    'Grad',
                                    _cityId,
                                    _cities,
                                    (value) => setState(() => _cityId = value),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _dropdown(
                                    'Tip vikendice',
                                    _typeId,
                                    _types,
                                    (value) => setState(() => _typeId = value),
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _ownerId,
                                      decoration: const InputDecoration(
                                        labelText: 'Vlasnik',
                                      ),
                                      items: _owners
                                          .map(
                                            (item) => DropdownMenuItem(
                                              value: item.id,
                                              child: Text(item.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _ownerId = value),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Kapacitet i cijena'),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'area',
                                    'Površina (m²)',
                                    validator: _positiveNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    'price',
                                    'Cijena po noći (KM)',
                                    validator: _positiveNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    'adults',
                                    'Odrasli',
                                    validator: _positiveNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    'children',
                                    'Djeca',
                                    validator: _nonNegativeInt,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'bedrooms',
                                    'Spavaće sobe',
                                    validator: _nonNegativeInt,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _textField(
                                    'bathrooms',
                                    'Kupatila',
                                    validator: _positiveNumber,
                                  ),
                                ),
                                const Spacer(flex: 2),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Pogodnosti'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _amenities
                                  .map(
                                    (item) => FilterChip(
                                      label: Text(item.name),
                                      selected: _amenityIds.contains(item.id),
                                      onSelected: (selected) => setState(
                                        () => selected
                                            ? _amenityIds.add(item.id)
                                            : _amenityIds.remove(item.id),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Lokacija'),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    'latitude',
                                    'Latitude (opcionalno)',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _textField(
                                    'longitude',
                                    'Longitude (opcionalno)',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Fotografijama možete upravljati kroz opciju Galerija nakon čuvanja vikendice.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Odustani'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Sačuvaj'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String key,
    String label, {
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: _fields[key],
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
  Widget _dropdown(
    String label,
    int? value,
    List<CatalogOption> items,
    ValueChanged<int?> onChanged,
  ) => DropdownButtonFormField<int>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: items
        .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
        .toList(),
    onChanged: onChanged,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
