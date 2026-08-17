import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmProfileDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Obrisati korisnički profil?'),
        content: const Text(
          'Profil će biti trajno deaktiviran i više se nećete moći prijaviti '
          'ovim korisničkim računom. Historija rezervacija ostaje sačuvana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Obriši profil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthController>();
    final deleted = await auth.deactivateProfile();
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Profil trenutno nije moguće obrisati.',
          ),
        ),
      );
    }
  }

  Future<void> _selectProfileImage(BuildContext context) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (image == null || !context.mounted) return;
    final bytes = await image.readAsBytes();
    if (!context.mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slika ne smije biti veća od 5 MB.')),
      );
      return;
    }
    final extension = image.name.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => null,
    };
    if (contentType == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dozvoljeni formati su JPG, PNG i WebP.'),
          ),
        );
      }
      return;
    }
    final saved = await context.read<AuthController>().updateProfileImage(
      bytes: bytes,
      fileName: image.name,
      contentType: contentType,
    );
    if (!context.mounted) return;
    final message = saved
        ? 'Profilna slika je uspješno sačuvana.'
        : context.read<AuthController>().errorMessage ??
              'Profilnu sliku nije moguće sačuvati.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: user.resolvedProfileImageUrl == null
                          ? null
                          : NetworkImage(user.resolvedProfileImageUrl!),
                      child: user.resolvedProfileImageUrl == null
                          ? Text(
                              user.firstName.substring(0, 1).toUpperCase(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            )
                          : null,
                    ),
                    Positioned(
                      right: -8,
                      bottom: -6,
                      child: IconButton.filled(
                        tooltip: 'Promijeni profilnu sliku',
                        onPressed: auth.isLoading
                            ? null
                            : () => _selectProfileImage(context),
                        icon: const Icon(Icons.photo_camera_outlined, size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () => _selectProfileImage(context),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Odaberi profilnu sliku'),
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
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 10),
        Text(
          'Brisanje profila',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Ova radnja deaktivira korisnički račun i ne može se poništiti.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: auth.isLoading
              ? null
              : () => _confirmProfileDeletion(context),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Obriši korisnički profil'),
        ),
      ],
    );
  }
}
