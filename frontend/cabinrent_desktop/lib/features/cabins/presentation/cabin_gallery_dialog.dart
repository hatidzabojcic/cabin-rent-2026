import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin.dart';

String cabinImageUrl(String url) =>
    url.startsWith('/') ? '${AppConfig.apiBaseUrl}$url' : url;

class CabinGalleryDialog extends StatefulWidget {
  const CabinGalleryDialog({super.key, required this.cabin});
  final Cabin cabin;
  @override
  State<CabinGalleryDialog> createState() => _CabinGalleryDialogState();
}

class _CabinGalleryDialogState extends State<CabinGalleryDialog> {
  late Cabin _cabin = widget.cabin;
  int _selectedIndex = 0;
  bool _working = false;
  String? _error;

  List<CabinImage> get _images =>
      [..._cabin.images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _reload() async {
    final cabin = await context.read<CabinsRepository>().getManagedCabin(
      _cabin.id,
    );
    if (!mounted) return;
    setState(() {
      _cabin = cabin;
      if (_selectedIndex >= _images.length) {
        _selectedIndex = (_images.length - 1).clamp(0, 1000);
      }
    });
  }

  Future<void> _upload() async {
    final repository = context.read<CabinsRepository>();
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (selection.isEmpty || !mounted) return;
    if (_images.length + selection.length > 12) {
      setState(() => _error = 'Vikendica može imati najviše 12 slika.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      for (final file in selection) {
        final bytes = await file.readAsBytes();
        await repository.uploadImage(_cabin.id, bytes, file.name);
      }
      await _reload();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _setCover(CabinImage image) async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await context.read<CabinsRepository>().updateImage(
        _cabin.id,
        image,
        isCover: true,
        sortOrder: image.sortOrder,
      );
      await _reload();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _move(CabinImage image, int direction) async {
    final images = _images;
    final index = images.indexWhere((item) => item.id == image.id);
    final targetIndex = index + direction;
    if (index < 0 || targetIndex < 0 || targetIndex >= images.length) return;
    final other = images[targetIndex];
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final repository = context.read<CabinsRepository>();
      await repository.updateImage(
        _cabin.id,
        image,
        isCover: image.isCover,
        sortOrder: other.sortOrder,
      );
      await repository.updateImage(
        _cabin.id,
        other,
        isCover: other.isCover,
        sortOrder: image.sortOrder,
      );
      await _reload();
      if (mounted) setState(() => _selectedIndex = targetIndex);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete(CabinImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje slike'),
        content: const Text(
          'Da li želite trajno obrisati ovu sliku iz galerije?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await context.read<CabinsRepository>().deleteImage(_cabin.id, image.id);
      await _reload();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final selected = images.isEmpty
        ? null
        : images[_selectedIndex.clamp(0, images.length - 1)];
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Galerija – ${_cabin.name}',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text('${images.length} / 12 slika'),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _working ? null : _upload,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Dodaj slike'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _working
                        ? null
                        : () => Navigator.pop(context, true),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_working) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: images.isEmpty
                  ? _emptyGallery()
                  : _galleryContent(context, images, selected!),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyGallery() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.photo_library_outlined,
          size: 60,
          color: Colors.black38,
        ),
        const SizedBox(height: 12),
        const Text('Galerija je prazna.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _upload,
          icon: const Icon(Icons.upload),
          label: const Text('Odaberi slike'),
        ),
      ],
    ),
  );

  Widget _galleryContent(
    BuildContext context,
    List<CabinImage> images,
    CabinImage selected,
  ) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              child: Image.network(
                cabinImageUrl(selected.url),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (selected.isCover)
              const Chip(
                avatar: Icon(Icons.star, size: 17),
                label: Text('Naslovna'),
              )
            else
              OutlinedButton.icon(
                onPressed: _working ? null : () => _setCover(selected),
                icon: const Icon(Icons.star_outline),
                label: const Text('Postavi kao naslovnu'),
              ),
            const Spacer(),
            IconButton(
              onPressed: _working || _selectedIndex == 0
                  ? null
                  : () => _move(selected, -1),
              tooltip: 'Pomjeri lijevo',
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              onPressed: _working || _selectedIndex == images.length - 1
                  ? null
                  : () => _move(selected, 1),
              tooltip: 'Pomjeri desno',
              icon: const Icon(Icons.arrow_forward),
            ),
            IconButton(
              onPressed: _working ? null : () => _delete(selected),
              tooltip: 'Obriši',
              color: Theme.of(context).colorScheme.error,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _thumbnail(context, images[index], index),
          ),
        ),
      ],
    ),
  );

  Widget _thumbnail(BuildContext context, CabinImage image, int index) =>
      InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: index == _selectedIndex
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                cabinImageUrl(image.url),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Colors.black12,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
              if (image.isCover)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    radius: 12,
                    child: Icon(Icons.star, size: 15),
                  ),
                ),
            ],
          ),
        ),
      );
}
