import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/users_repository.dart';
import '../domain/managed_user.dart';
import 'user_details_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<ManagedUser> _users = [];
  bool _loading = true;
  String? _error;
  String? _role;
  bool? _isActive;
  String _search = '';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await context.read<UsersRepository>().getUsers(
        search: _search,
        role: _role,
        isActive: _isActive,
      );
      if (mounted) setState(() => _users = users);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchChanged(String value) {
    _search = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _toggleStatus(ManagedUser user) async {
    final activate = !user.isActive;
    final action = activate ? 'aktivirati' : 'deaktivirati';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          activate ? 'Aktivacija korisnika' : 'Deaktivacija korisnika',
        ),
        content: Text('Da li želite $action korisnika „${user.fullName}“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(activate ? 'Aktiviraj' : 'Deaktiviraj'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<UsersRepository>().setActive(user.id, activate);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activate ? 'Korisnik je aktiviran.' : 'Korisnik je deaktiviran.',
            ),
          ),
        );
      }
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
    final currentUserId = context.watch<AuthController>().user!.id;
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
                      'Korisnici',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pregled korisnika, vlasnika i upravljanje pristupom sistemu.',
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _loading ? null : _load,
                tooltip: 'Osvježi',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 340,
                child: TextField(
                  onChanged: _searchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Pretraži po imenu, emailu ili korisničkom imenu',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String?>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Uloga'),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sve uloge'),
                    ),
                    DropdownMenuItem(
                      value: 'Admin',
                      child: Text('Administratori'),
                    ),
                    DropdownMenuItem(value: 'Owner', child: Text('Vlasnici')),
                    DropdownMenuItem(value: 'Guest', child: Text('Gosti')),
                  ],
                  onChanged: (value) {
                    _role = value;
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<bool?>(
                  initialValue: _isActive,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('Svi statusi'),
                    ),
                    DropdownMenuItem(value: true, child: Text('Aktivni')),
                    DropdownMenuItem(value: false, child: Text('Neaktivni')),
                  ],
                  onChanged: (value) {
                    _isActive = value;
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _content(currentUserId)),
        ],
      ),
    );
  }

  Widget _content(int currentUserId) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Korisnike nije moguće učitati.\n$_error',
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
    if (_users.isEmpty) {
      return const Center(child: Text('Nema korisnika za odabrane filtere.'));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Korisnik')),
              DataColumn(label: Text('Kontakt')),
              DataColumn(label: Text('Uloga')),
              DataColumn(label: Text('Vikendice')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('')),
            ],
            rows: _users
                .map(
                  (user) => DataRow(
                    onSelectChanged: (_) => showDialog<void>(
                      context: context,
                      builder: (_) => UserDetailsDialog(user: user),
                    ),
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '@${user.userName}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(user.email)),
                      DataCell(Text(user.roles.map(roleLabel).join(', '))),
                      DataCell(
                        Text(user.isOwner ? user.cabinCount.toString() : '—'),
                      ),
                      DataCell(_UserStatusBadge(active: user.isActive)),
                      DataCell(
                        PopupMenuButton<String>(
                          tooltip: 'Akcije',
                          onSelected: (value) {
                            if (value == 'details') {
                              showDialog<void>(
                                context: context,
                                builder: (_) => UserDetailsDialog(user: user),
                              );
                            }
                            if (value == 'status') {
                              _toggleStatus(user);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Text('Prikaži detalje'),
                            ),
                            PopupMenuItem(
                              value: 'status',
                              enabled: user.id != currentUserId,
                              child: Text(
                                user.isActive ? 'Deaktiviraj' : 'Aktiviraj',
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
    );
  }
}

class _UserStatusBadge extends StatelessWidget {
  const _UserStatusBadge({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Chip(
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .10),
      label: Text(
        active ? 'Aktivan' : 'Neaktivan',
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }
}
