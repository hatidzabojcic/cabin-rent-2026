import 'package:flutter/material.dart';

import '../domain/managed_user.dart';

class UserDetailsDialog extends StatelessWidget {
  const UserDetailsDialog({super.key, required this.user});
  final ManagedUser user;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Icon(Icons.account_circle_outlined),
        const SizedBox(width: 10),
        Expanded(child: Text(user.fullName)),
      ],
    ),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _StatusChip(active: user.isActive),
              ...user.roles.map((role) => Chip(label: Text(roleLabel(role)))),
            ],
          ),
          const SizedBox(height: 18),
          _row('Korisničko ime', user.userName),
          _row('Email', user.email),
          _row(
            'Telefon',
            user.phoneNumber?.trim().isNotEmpty == true
                ? user.phoneNumber!
                : 'Nije unesen',
          ),
          if (user.isOwner) ...[
            const Divider(height: 30),
            _row('Broj vikendica', user.cabinCount.toString()),
            _row('Broj rezervacija', user.reservationCount.toString()),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zatvori'),
      ),
    ],
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 145,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.block,
        size: 17,
        color: color.shade700,
      ),
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .10),
      label: Text(
        active ? 'Aktivan' : 'Neaktivan',
        style: TextStyle(color: color.shade700),
      ),
    );
  }
}
