import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/users_repository.dart';
import '../domain/managed_user.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});
  final ManagedUser? user;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _userName;
  late final TextEditingController _phone;
  final _password = TextEditingController();
  late String _role;
  late bool _isActive;
  bool _saving = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _userName = TextEditingController(text: user?.userName ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
    _role = user?.roles.firstOrNull ?? 'Owner';
    _isActive = user?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _userName.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.user == null ? 'Dodaj korisnika' : 'Uredi korisnika'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _requiredField(_firstName, 'Ime')),
                  const SizedBox(width: 12),
                  Expanded(child: _requiredField(_lastName, 'Prezime')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    RegExp(
                      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,24}$",
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Unesite ispravnu email adresu.',
              ),
              const SizedBox(height: 12),
              _requiredField(_userName, 'Korisni\u010dko ime'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon (opcionalno)',
                  hintText: '+38761123456',
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  return phone.isEmpty ||
                          RegExp(r'^\+3876[0-7]\d{6}$').hasMatch(phone)
                      ? null
                      : 'Koristite format +3876XXXXXXX.';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: widget.user == null
                      ? 'Lozinka'
                      : 'Nova lozinka (opcionalno)',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (widget.user == null && password.isEmpty) {
                    return 'Lozinka je obavezna.';
                  }
                  if (password.isNotEmpty && password.length < 8) {
                    return 'Lozinka mora imati najmanje 8 znakova.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Uloga'),
                items: const [
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text('Administrator'),
                  ),
                  DropdownMenuItem(value: 'Owner', child: Text('Vlasnik')),
                  DropdownMenuItem(value: 'Guest', child: Text('Gost')),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktivan korisni\u010dki nalog'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Odustani'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Sa\u010duvaj'),
      ),
    ],
  );

  TextFormField _requiredField(
    TextEditingController controller,
    String label,
  ) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    validator: (value) =>
        value == null || value.trim().isEmpty ? '$label je obavezan.' : null,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim(),
      'userName': _userName.text.trim(),
      'phoneNumber': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'password': _password.text.isEmpty ? null : _password.text,
      'role': _role,
      'isActive': _isActive,
    };
    try {
      final repository = context.read<UsersRepository>();
      if (widget.user == null) {
        await repository.create(body);
      } else {
        await repository.update(widget.user!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
