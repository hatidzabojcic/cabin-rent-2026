import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phoneNumber;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user!;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
    _email = TextEditingController(text: user.email);
    _phoneNumber = TextEditingController(text: user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phoneNumber.dispose();
    super.dispose();
  }

  String? _requiredName(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label je obavezno.';
    if (text.length > 100) return '$label može imati najviše 100 znakova.';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email adresa je obavezna.';
    if (text.length > 320) return 'Email adresa je preduga.';
    final format = RegExp(
      r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.[A-Za-z]{2,24}$",
    );
    if (!format.hasMatch(text)) return 'Unesite ispravnu email adresu.';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').replaceAll(' ', '');
    if (text.isEmpty) return null;
    if (!RegExp(r'^\+3876[0-7][0-9]{6}$').hasMatch(text)) {
      return 'Unesite BiH mobilni broj, npr. +387 61 123 456.';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final saved = await auth.updateProfile(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phoneNumber: _phoneNumber.text,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Podaci profila su uspješno sačuvani.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Uredi profil')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Osnovni podaci',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ažurirajte kontakt podatke koji se koriste uz vaše rezervacije.',
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _firstName,
              enabled: !auth.isLoading,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Ime',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => _requiredName(value, 'Ime'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _lastName,
              enabled: !auth.isLoading,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Prezime',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => _requiredName(value, 'Prezime'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              maxLength: 320,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneNumber,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 15,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Broj telefona',
                hintText: '+387 61 123 456',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 4),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Korisničko ime',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              child: Text(user.userName),
            ),
            const SizedBox(height: 6),
            Text(
              'Korisničko ime se ne može mijenjati.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: auth.isLoading ? null : _save,
              icon: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(auth.isLoading ? 'Spremanje...' : 'Sačuvaj izmjene'),
            ),
          ],
        ),
      ),
    );
  }
}
