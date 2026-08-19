import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Promijeni lozinku')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Sigurnost profila',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nakon promjene bit \u0107ete odjavljeni sa svih aktivnih sesija.',
            ),
            const SizedBox(height: 24),
            _passwordField(_current, 'Trenutna lozinka'),
            const SizedBox(height: 14),
            _passwordField(
              _password,
              'Nova lozinka',
              validator: (value) => (value?.length ?? 0) < 8
                  ? 'Lozinka mora imati najmanje 8 znakova.'
                  : null,
            ),
            const SizedBox(height: 14),
            _passwordField(
              _confirmation,
              'Potvrdi novu lozinku',
              validator: (value) =>
                  value != _password.text ? 'Lozinke se ne podudaraju.' : null,
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: auth.isLoading ? null : _save,
              icon: const Icon(Icons.password_outlined),
              label: const Text('Promijeni lozinku'),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _passwordField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: _hidden,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator:
        validator ??
        (value) => value == null || value.isEmpty ? 'Polje je obavezno.' : null,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await context.read<AuthController>().changePassword(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
    if (!saved || !mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
