import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _requested = false;
  bool _loading = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!_emailForm.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() => _requested = true);
      await _showMailpitInstructions();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Zahtjev trenutno nije moguće poslati.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showMailpitInstructions() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.mark_email_read_outlined, size: 42),
      title: const Text('Provjerite testni email'),
      content: const Text(
        'Za potrebe testiranja poruka je poslana u lokalni Mailpit inbox. '
        'Na računaru na kojem je pokrenut CabinRent otvorite web preglednik, '
        'unesite http://localhost:8025 i iz najnovije CabinRent poruke '
        'kopirajte token u ovu aplikaciju.',
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              const ClipboardData(text: 'http://localhost:8025'),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adresa inboxa je kopirana.')),
              );
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Kopiraj adresu'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nastavi'),
        ),
      ],
    ),
  );

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().resetPassword(
        token: _token.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lozinka je promijenjena'),
          content: const Text('Sada se možete prijaviti novom lozinkom.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('U redu'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Lozinku trenutno nije moguće promijeniti.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset lozinke')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _requested ? _buildReset() : _buildRequest(),
          ),
        ),
      ),
    ),
  );

  Widget _buildRequest() => Form(
    key: _emailForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Zaboravljena lozinka',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Unesite email računa. Poslat ćemo vam vremenski ograničen token za postavljanje nove lozinke.',
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) => value == null || !value.contains('@')
              ? 'Unesite ispravnu email adresu.'
              : null,
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _request,
          child: Text(_loading ? 'Slanje...' : 'Pošalji upute'),
        ),
      ],
    ),
  );

  Widget _buildReset() => Form(
    key: _resetForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Postavite novu lozinku',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text('Ako račun postoji, token je poslan na ${_email.text.trim()}.'),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.computer_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gdje se nalazi reset poruka?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SelectableText('http://localhost:8025'),
                const SizedBox(height: 6),
                const Text(
                  'Na računaru na kojem je pokrenut CabinRent otvorite ovu '
                  'adresu u web pregledniku. Zatim iz najnovije CabinRent '
                  'poruke kopirajte token u polje ispod.',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Clipboard.setData(
                      const ClipboardData(text: 'http://localhost:8025'),
                    ),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Kopiraj adresu'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _token,
          decoration: const InputDecoration(
            labelText: 'Token iz emaila',
            prefixIcon: Icon(Icons.key_outlined),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Unesite token.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _hidden,
          decoration: InputDecoration(
            labelText: 'Nova lozinka',
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
          validator: (value) => value == null || value.length < 8
              ? 'Lozinka mora imati najmanje 8 znakova.'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmPassword,
          obscureText: _hidden,
          decoration: const InputDecoration(
            labelText: 'Potvrdite novu lozinku',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
          validator: (value) =>
              value != _password.text ? 'Lozinke se ne podudaraju.' : null,
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _reset,
          child: Text(_loading ? 'Spremanje...' : 'Promijeni lozinku'),
        ),
        TextButton(
          onPressed: _loading ? null : () => setState(() => _requested = false),
          child: const Text('Pošalji novi token'),
        ),
      ],
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
