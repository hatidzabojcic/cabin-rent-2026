import 'package:flutter/material.dart';

import '../domain/reservation.dart';

Future<String?> showCancellationReasonDialog(
  BuildContext context,
  Reservation reservation,
) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();

  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Otkazati rezervaciju?'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reservation.paymentStatus == 'Paid'
                  ? 'Za rezervaciju ${reservation.confirmationCode} bit će pokrenut povrat punog uplaćenog iznosa.'
                  : 'Navedi razlog otkazivanja rezervacije ${reservation.confirmationCode}.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja',
                hintText: 'Npr. promijenjeni planovi putovanja',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.length < 3) {
                  return 'Unesite najmanje 3 znaka.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(dialogContext, controller.text.trim());
          },
          child: const Text('Potvrdi otkazivanje'),
        ),
      ],
    ),
  );

  controller.dispose();
  return reason;
}
