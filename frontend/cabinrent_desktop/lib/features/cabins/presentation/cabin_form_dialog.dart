import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../catalog/data/reference_data_repository.dart';
import '../../catalog/domain/reference_data.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin.dart';
import 'location_picker_dialog.dart';

class _ReverseGeocodeResult {
  const _ReverseGeocodeResult({
    required this.address,
    required this.localityCandidates,
  });

  final String address;
  final List<String> localityCandidates;

  String get detectedLocality => localityCandidates.firstOrNull ?? 'nepoznata';
}

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
  double? _latitude;
  double? _longitude;
  bool _loading = true;
  bool _saving = false;
  bool _resolvingAddress = false;
  String? _locationMessage;
  String? _detectedCityName;
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
    };
    _cityId = cabin?.cityId;
    _typeId = cabin?.cabinTypeId;
    _ownerId = cabin?.ownerId;
    _latitude = cabin?.latitude;
    _longitude = cabin?.longitude;
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
    if (!_formKey.currentState!.validate() || _typeId == null) {
      return;
    }
    if (_cityId == null) {
      setState(
        () => _error =
            'Odaberite grad. Ako prepoznati grad nije ponuđen, prvo ga dodajte kroz Šifrarnici > Gradovi.',
      );
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
      latitude: _latitude,
      longitude: _longitude,
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

  Future<void> _pickLocation() async {
    final selected = await showDialog<LocationSelection>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationPickerDialog(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _latitude = selected.latitude;
      _longitude = selected.longitude;
      _resolvingAddress = true;
      _locationMessage = null;
      _detectedCityName = null;
    });

    try {
      final result = await _reverseGeocode(selected);
      if (!mounted) return;
      if (result != null) {
        _fields['address']!.text = result.address;
        final matchedCity = _matchCity(result.localityCandidates);
        setState(() {
          _cityId = matchedCity?.id;
          _detectedCityName = matchedCity == null
              ? result.detectedLocality
              : null;
          _locationMessage = matchedCity == null
              ? 'Prepoznata lokacija: ${result.detectedLocality}. Grad nije u šifrarniku; dodajte ga kroz Šifrarnici > Gradovi.'
              : 'Grad je automatski prepoznat: ${matchedCity.name}.';
        });
      } else {
        setState(() {
          _cityId = null;
          _detectedCityName = null;
          _locationMessage =
              'Grad nije automatski prepoznat. Odaberite odgovarajući grad ili ga prvo dodajte u šifrarnik.';
        });
        _showAddressLookupWarning();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cityId = null;
          _detectedCityName = null;
          _locationMessage =
              'Lokacijski servis nije dostupan. Provjerite adresu i svjesno odaberite grad.';
        });
        _showAddressLookupWarning();
      }
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<_ReverseGeocodeResult?> _reverseGeocode(
    LocationSelection selected,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': selected.latitude.toString(),
      'lon': selected.longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': 'bs',
    });
    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'CabinRent seminar application',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final displayName = (json['display_name'] as String?)?.trim();
    if (displayName?.isNotEmpty != true) return null;

    final address = json['address'] as Map<String, dynamic>? ?? const {};
    final candidates = <String>{
      for (final key in const [
        'city',
        'town',
        'village',
        'municipality',
        'county',
      ])
        if ((address[key] as String?)?.trim().isNotEmpty == true)
          (address[key] as String).trim(),
    }.toList();
    return _ReverseGeocodeResult(
      address: displayName!,
      localityCandidates: candidates,
    );
  }

  CatalogOption? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeLocationName(candidate);
      for (final city in _cities) {
        if (_normalizeLocationName(city.name) == normalizedCandidate) {
          return city;
        }
      }
    }
    return null;
  }

  String _normalizeLocationName(String value) => value
      .toLowerCase()
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('đ', 'd')
      .replaceAll('š', 's')
      .replaceAll('ž', 'z')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  void _showAddressLookupWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Koordinate su sačuvane, ali adresu nije moguće automatski pronaći. Unesite je ručno.',
        ),
      ),
    );
  }

  Future<void> _addDetectedCity() async {
    final cityName = _detectedCityName;
    if (cityName == null) return;
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuickAddCityDialog(suggestedName: cityName),
    );
    if (created != true || !mounted) return;

    try {
      final cities = await context.read<CabinsRepository>().getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        final normalizedName = _normalizeLocationName(cityName);
        final match = cities
            .where(
              (city) => _normalizeLocationName(city.name) == normalizedName,
            )
            .firstOrNull;
        _cityId = match?.id;
        _detectedCityName = null;
        _locationMessage = match == null
            ? 'Grad je dodan, ali ga nije moguće automatski odabrati. Ponovo otvorite formu.'
            : 'Grad je dodan u šifrarnik i automatski odabran: ${match.name}.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
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
                    onPressed: _saving || _resolvingAddress
                        ? null
                        : () => Navigator.pop(context),
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
                                    (value) => setState(() {
                                      _cityId = value;
                                      if (value != null) {
                                        _locationMessage = null;
                                      }
                                    }),
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
                            _LocationField(
                              latitude: _latitude,
                              longitude: _longitude,
                              onPick: _pickLocation,
                              onClear: _latitude == null
                                  ? null
                                  : () => setState(() {
                                      _latitude = null;
                                      _longitude = null;
                                    }),
                            ),
                            if (_resolvingAddress) ...[
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Automatsko pronalaženje adrese...'),
                                ],
                              ),
                            ],
                            if (_locationMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _locationMessage!,
                                style: TextStyle(
                                  color: _cityId == null
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isAdmin && _detectedCityName != null) ...[
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _addDetectedCity,
                                  icon: const Icon(Icons.add_location_alt),
                                  label: Text(
                                    'Dodaj „$_detectedCityName“ u šifrarnik',
                                  ),
                                ),
                              ],
                            ],
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
                    onPressed: _saving || _resolvingAddress
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Odustani'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _saving || _resolvingAddress ? null : _save,
                    icon: _saving || _resolvingAddress
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

class _QuickAddCityDialog extends StatefulWidget {
  const _QuickAddCityDialog({required this.suggestedName});

  final String suggestedName;

  @override
  State<_QuickAddCityDialog> createState() => _QuickAddCityDialogState();
}

class _QuickAddCityDialogState extends State<_QuickAddCityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _postalCode = TextEditingController();
  List<ReferenceItem> _countries = [];
  int? _countryId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.suggestedName);
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await context
          .read<ReferenceDataRepository>()
          .getCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countryId = countries
            .where((country) => country.isoCode?.toUpperCase() == 'BA')
            .firstOrNull
            ?.id;
        _countryId ??= countries.firstOrNull?.id;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context
          .read<ReferenceDataRepository>()
          .create(ReferenceKind.cities, {
            'name': _name.text.trim(),
            'postalCode': _postalCode.text.trim().isEmpty
                ? null
                : _postalCode.text.trim(),
            'countryId': _countryId,
          });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Dodaj prepoznati grad'),
    content: SizedBox(
      width: 430,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Naziv grada'),
                    validator: (value) => value?.trim().isNotEmpty == true
                        ? null
                        : 'Naziv grada je obavezan.',
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _countryId,
                    decoration: const InputDecoration(labelText: 'Država'),
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
                        value == null ? 'Odaberite državu.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _postalCode,
                    decoration: const InputDecoration(
                      labelText: 'Poštanski broj (opcionalno)',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
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
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Odustani'),
      ),
      FilledButton.icon(
        onPressed: _loading || _saving ? null : _save,
        icon: _saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Dodaj grad'),
      ),
    ],
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

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.latitude,
    required this.longitude,
    required this.onPick,
    required this.onClear,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final selected = latitude != null && longitude != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Icon(
              selected
                  ? Icons.location_on_outlined
                  : Icons.add_location_alt_outlined,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected ? 'Lokacija je odabrana' : 'Lokacija nije odabrana',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  selected
                      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
                      : 'Lokacija je opcionalna. Odaberite je klikom na kartu.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          if (onClear != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.location_off_outlined),
              label: const Text('Ukloni'),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.map_outlined),
            label: Text(selected ? 'Promijeni na karti' : 'Odaberi na karti'),
          ),
        ],
      ),
    );
  }
}
