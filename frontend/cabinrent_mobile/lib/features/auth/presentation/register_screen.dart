import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(),
      _last = TextEditingController(),
      _email = TextEditingController(),
      _user = TextEditingController(),
      _phone = TextEditingController(),
      _password = TextEditingController();
  bool _hidden = true;
  @override
  void dispose() {
    for (final c in [_first, _last, _email, _user, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await context.read<AuthController>().register(
      firstName: _first.text,
      lastName: _last.text,
      email: _email.text,
      userName: _user.text,
      password: _password.text,
      phoneNumber: _phone.text,
    );
    if (ok && mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Ovo polje je obavezno.' : null;

  String? _validateEmail(String? value) {
    final required = _required(value);
    if (required != null) return required;
    final format = RegExp(
      r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.[A-Za-z]{2,24}$",
    );
    return format.hasMatch(value!.trim())
        ? null
        : 'Unesite ispravnu email adresu.';
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').replaceAll(' ', '');
    if (phone.isEmpty) return null;
    return RegExp(r'^\+3876[0-7][0-9]{6}$').hasMatch(phone)
        ? null
        : 'Unesite BiH mobilni broj, npr. +387 61 123 456.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Registracija')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kreirajte račun',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Unesite podatke kako biste mogli rezervisati vikendice.',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _first,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Ime'),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _last,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Prezime'),
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _user,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Korisničko ime',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    final required = _required(v);
                    if (required != null) return required;
                    return v!.trim().length >= 3 ? null : 'Najmanje 3 znaka.';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 15,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Telefon (opcionalno)',
                    hintText: '+387 61 123 456',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _hidden,
                  decoration: InputDecoration(
                    labelText: 'Lozinka',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) {
                    final required = _required(v);
                    if (required != null) return required;
                    return v!.length >= 8
                        ? null
                        : 'Lozinka mora imati najmanje 8 znakova.';
                  },
                ),
                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      auth.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registruj se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
