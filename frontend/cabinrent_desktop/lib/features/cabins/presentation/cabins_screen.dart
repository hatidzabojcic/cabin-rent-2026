import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin.dart';
import 'cabin_form_dialog.dart';
import 'cabin_gallery_dialog.dart';

class CabinsScreen extends StatefulWidget {
  const CabinsScreen({super.key});
  @override
  State<CabinsScreen> createState() => _CabinsScreenState();
}

class _CabinsScreenState extends State<CabinsScreen> {
  List<Cabin> _cabins = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cabins = await context.read<CabinsRepository>().getManagedCabins();
      if (!mounted) return;
      setState(() => _cabins = cabins);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Cabin? cabin]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CabinFormDialog(cabin: cabin),
    );
    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cabin == null
                  ? 'Vikendica je uspješno dodana.'
                  : 'Podaci vikendice su sačuvani.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openGallery(Cabin cabin) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CabinGalleryDialog(cabin: cabin),
    );
    if (changed == true) await _load();
  }

  Future<void> _toggleActive(Cabin cabin) async {
    final verb = cabin.isActive ? 'deaktivirati' : 'aktivirati';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${cabin.isActive ? 'Deaktivacija' : 'Aktivacija'} vikendice',
        ),
        content: Text('Da li želite $verb vikendicu „${cabin.name}“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(cabin.isActive ? 'Deaktiviraj' : 'Aktiviraj'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CabinsRepository>().setActive(
        cabin.id,
        !cabin.isActive,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.toLowerCase().trim();
    final filtered = _cabins
        .where(
          (cabin) =>
              query.isEmpty ||
              cabin.name.toLowerCase().contains(query) ||
              cabin.city.toLowerCase().contains(query),
        )
        .toList();
    final isAdmin = context.watch<AuthController>().user!.isAdmin;

    return Padding(
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
                      'Vikendice',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Dodavanje, uređivanje i aktivacija smještajnih jedinica.',
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj vikendicu'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 420,
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Pretraži po nazivu ili gradu',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Expanded(child: _buildContent(filtered, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildContent(List<Cabin> cabins, bool isAdmin) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Podatke nije moguće učitati.\n$_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (cabins.isEmpty) {
      return const Center(child: Text('Nema pronađenih vikendica.'));
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 350,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: cabins.length,
      itemBuilder: (_, index) => _CabinCard(
        cabin: cabins[index],
        showOwner: isAdmin,
        onEdit: () => _openForm(cabins[index]),
        onGallery: () => _openGallery(cabins[index]),
        onToggleActive: () => _toggleActive(cabins[index]),
      ),
    );
  }
}

class _CabinCard extends StatelessWidget {
  const _CabinCard({
    required this.cabin,
    required this.showOwner,
    required this.onEdit,
    required this.onGallery,
    required this.onToggleActive,
  });
  final Cabin cabin;
  final bool showOwner;
  final VoidCallback onEdit;
  final VoidCallback onGallery;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onGallery,
          child: SizedBox(
            height: 95,
            width: double.infinity,
            child: cabin.coverImageUrl == null
                ? const ColoredBox(
                    color: Color(0xFFE8EFEA),
                    child: Icon(Icons.photo_library_outlined, size: 38),
                  )
                : Image.network(
                    cabinImageUrl(cabin.coverImageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Color(0xFFE8EFEA),
                          child: Icon(Icons.broken_image_outlined, size: 38),
                        ),
                  ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: const Icon(Icons.cabin_outlined)),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(cabin.isActive ? 'Aktivna' : 'Neaktivna'),
                      avatar: Icon(
                        cabin.isActive
                            ? Icons.check_circle
                            : Icons.pause_circle,
                        size: 17,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'gallery') onGallery();
                        if (value == 'active') onToggleActive();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Uredi'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'gallery',
                          child: ListTile(
                            leading: Icon(Icons.photo_library_outlined),
                            title: Text('Galerija'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'active',
                          child: ListTile(
                            leading: Icon(
                              cabin.isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            title: Text(
                              cabin.isActive ? 'Deaktiviraj' : 'Aktiviraj',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  cabin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${cabin.city}  •  ${cabin.cabinType}'),
                Text(
                  '${cabin.maxAdults + cabin.maxChildren} gostiju  •  ${cabin.bedrooms} spavaćih soba',
                ),
                if (showOwner)
                  Text(
                    'Vlasnik: ${cabin.ownerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
        ),
      ],
    ),
  );
}
