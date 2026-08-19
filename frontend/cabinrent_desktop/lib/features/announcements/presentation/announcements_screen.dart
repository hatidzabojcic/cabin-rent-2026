import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/announcements_repository.dart';
import '../domain/announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _search = TextEditingController();
  List<Announcement> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await context.read<AnnouncementsRepository>().get(search: _search.text.trim());
      if (mounted) setState(() => _items = items);
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _form([Announcement? current]) async {
    final changed = await showDialog<bool>(context: context, builder: (_) => _AnnouncementDialog(current: current));
    if (changed == true) _load();
  }

  Future<void> _delete(Announcement item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Brisanje novosti'), content: Text('Obrisati „${item.title}“?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Obriši'))],
    ));
    if (ok != true || !mounted) return;
    await context.read<AnnouncementsRepository>().delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Novosti', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 6), Text('Objave koje se prikazuju gostima u mobilnoj aplikaciji.'),
      ])), FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Dodaj novost'))]),
      const SizedBox(height: 20),
      SizedBox(width: 430, child: TextField(controller: _search, onSubmitted: (_) => _load(), decoration: InputDecoration(
        hintText: 'Pretraži naslov ili sadržaj', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward))))),
      const SizedBox(height: 18),
      if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_error != null) Expanded(child: Center(child: Text(_error!)))
      else if (_items.isEmpty) const Expanded(child: Center(child: Text('Nema evidentiranih novosti.')))
      else Expanded(child: ListView.separated(itemCount: _items.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) {
        final item = _items[i];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Icon(item.isActive ? Icons.campaign : Icons.campaign_outlined)),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${item.content}\n${_date(item.publishedAtUtc)} • ${item.isActive ? 'Aktivna' : 'Neaktivna'}', maxLines: 3, overflow: TextOverflow.ellipsis),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? _form(item) : _delete(item), itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Uredi')), PopupMenuItem(value: 'delete', child: Text('Obriši'))]),
        ));
      })),
    ]),
  );

  String _date(DateTime value) { final d = value.toLocal(); return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}.'; }
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({this.current}); final Announcement? current;
  @override State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _content, _image;
  late bool _active; bool _saving = false;
  @override void initState() { super.initState(); final x = widget.current;
    _title = TextEditingController(text: x?.title); _content = TextEditingController(text: x?.content);
    _image = TextEditingController(text: x?.imageUrl); _active = x?.isActive ?? true; }
  @override void dispose() { _title.dispose(); _content.dispose(); _image.dispose(); super.dispose(); }
  Future<void> _save() async { if (!_form.currentState!.validate()) return; setState(() => _saving = true);
    await context.read<AnnouncementsRepository>().save(current: widget.current, body: {
      'title': _title.text.trim(), 'content': _content.text.trim(), 'imageUrl': _image.text.trim().isEmpty ? null : _image.text.trim(),
      'publishedAtUtc': (widget.current?.publishedAtUtc ?? DateTime.now()).toUtc().toIso8601String(), 'isActive': _active,
    }); if (mounted) Navigator.pop(context, true); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text(widget.current == null ? 'Nova novost' : 'Uredi novost'),
    content: SizedBox(width: 520, child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _title, maxLength: 200, decoration: const InputDecoration(labelText: 'Naslov'), validator: _required),
      TextFormField(controller: _content, maxLength: 4000, maxLines: 5, decoration: const InputDecoration(labelText: 'Sadržaj'), validator: _required),
      TextFormField(controller: _image, decoration: const InputDecoration(labelText: 'URL slike (opcionalno)')),
      SwitchListTile(value: _active, onChanged: (v) => setState(() => _active = v), title: const Text('Aktivna objava')),
    ]))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Odustani')),
      FilledButton(onPressed: _saving ? null : _save, child: const Text('Sačuvaj'))]);
  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Polje je obavezno.' : null;
}
