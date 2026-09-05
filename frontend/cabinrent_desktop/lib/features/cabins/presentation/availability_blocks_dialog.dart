import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../data/cabins_repository.dart';
import '../domain/cabin.dart';

class AvailabilityBlocksDialog extends StatefulWidget {
  const AvailabilityBlocksDialog({super.key, required this.cabin});
  final Cabin cabin;

  @override
  State<AvailabilityBlocksDialog> createState() =>
      _AvailabilityBlocksDialogState();
}

class _AvailabilityBlocksDialogState extends State<AvailabilityBlocksDialog> {
  List<AvailabilityBlock> _blocks = [];
  bool _loading = true;
  String? _error;

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
      final blocks = await context
          .read<CabinsRepository>()
          .getAvailabilityBlocks(widget.cabin.id);
      if (mounted) setState(() => _blocks = blocks);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([AvailabilityBlock? block]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AvailabilityBlockFormDialog(
        cabinId: widget.cabin.id,
        block: block,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(AvailabilityBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uklanjanje blokiranog termina'),
        content: Text('Da li želite ukloniti termin „${block.reason}“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CabinsRepository>().deleteAvailabilityBlock(
        widget.cabin.id,
        block.id,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Blokirani termini – ${widget.cabin.name}'),
    content: SizedBox(
      width: 680,
      height: 430,
      child: _buildContent(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zatvori'),
      ),
      FilledButton.icon(
        onPressed: _loading ? null : () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj termin'),
      ),
    ],
  );

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Termine nije moguće učitati.\n$_error'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }
    if (_blocks.isEmpty) {
      return const Center(child: Text('Vikendica nema blokiranih termina.'));
    }
    return ListView.separated(
      itemCount: _blocks.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final block = _blocks[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.event_busy_outlined)),
          title: Text(block.reason),
          subtitle: Text('${_format(block.from)} – ${_format(block.to)}'),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: 'Uredi',
                onPressed: () => _openForm(block),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Ukloni',
                onPressed: () => _delete(block),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}.';
}

class _AvailabilityBlockFormDialog extends StatefulWidget {
  const _AvailabilityBlockFormDialog({required this.cabinId, this.block});
  final int cabinId;
  final AvailabilityBlock? block;

  @override
  State<_AvailabilityBlockFormDialog> createState() =>
      _AvailabilityBlockFormDialogState();
}

class _AvailabilityBlockFormDialogState
    extends State<_AvailabilityBlockFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  late DateTime _from;
  late DateTime _to;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));
    _from = widget.block?.from ?? tomorrow;
    _to = widget.block?.to ?? tomorrow.add(const Duration(days: 1));
    _reasonController = TextEditingController(text: widget.block?.reason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFrom() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value == null) return;
    setState(() {
      _from = value;
      if (!_to.isAfter(_from)) _to = _from.add(const Duration(days: 1));
    });
  }

  Future<void> _pickTo() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _to.isAfter(_from) ? _to : _from.add(const Duration(days: 1)),
      firstDate: _from.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _to = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = context.read<CabinsRepository>();
      if (widget.block == null) {
        await repository.createAvailabilityBlock(
          widget.cabinId,
          _from,
          _to,
          _reasonController.text,
        );
      } else {
        await repository.updateAvailabilityBlock(
          widget.cabinId,
          widget.block!.id,
          _from,
          _to,
          _reasonController.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.block == null ? 'Dodaj blokirani termin' : 'Uredi blokirani termin'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _DateField(label: 'Od', value: _from, onTap: _pickFrom)),
                const SizedBox(width: 12),
                Expanded(child: _DateField(label: 'Do', value: _to, onTap: _pickTo)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Razlog'),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Unesite najmanje 3 znaka.'
                  : null,
            ),
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Odustani'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Spremanje...' : 'Sačuvaj'),
      ),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
      child: Text(
        '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.',
      ),
    ),
  );
}
