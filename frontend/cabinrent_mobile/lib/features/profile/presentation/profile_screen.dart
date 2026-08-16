import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Moj profil',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Uredi profil',
              onPressed: auth.isLoading
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  child: Text(
                    user.firstName.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text('@${user.userName}'),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Telefon'),
                  subtitle: Text(
                    user.phoneNumber?.isNotEmpty == true
                        ? user.phoneNumber!
                        : 'Nije unesen',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: auth.isLoading
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditProfileScreen(),
                  ),
                ),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Uredi podatke profila'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : auth.logout,
          icon: const Icon(Icons.logout),
          label: const Text('Odjavi se'),
        ),
      ],
    );
  }
}
