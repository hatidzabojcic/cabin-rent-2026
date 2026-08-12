import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthController>().login(_userName.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final busy = auth.status == AuthStatus.loading;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(64),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.forest, Color(0xFF285F4F)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cabin_rounded, color: AppTheme.sand, size: 36),
                      SizedBox(width: 12),
                      Text(
                        'CabinRent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    'Upravljajte smještajem\nna jednom mjestu.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Desktop portal za administratore i vlasnike vikendica.',
                    style: TextStyle(color: Color(0xFFD8E6DF), fontSize: 17),
                  ),
                  Spacer(),
                  Text(
                    'CabinRent 2026',
                    style: TextStyle(color: Color(0xFFAAC6BA)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Dobro došli',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prijavite se svojim korisničkim podacima.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _userName,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Korisničko ime',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Unesite korisničko ime.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !busy,
                          obscureText: _obscurePassword,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Lozinka',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Unesite lozinku.'
                              : null,
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            auth.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: busy
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Prijavi se'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Test: admin / Admin123!  •  owner / Owner123!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
