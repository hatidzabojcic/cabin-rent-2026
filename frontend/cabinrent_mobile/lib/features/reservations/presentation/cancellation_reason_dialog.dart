import 'package:flutter/material.dart';

import '../domain/reservation.dart';

Future<String?> showCancellationReasonDialog(
  BuildContext context,
  Reservation reservation,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CancellationReasonDialog(reservation: reservation),
  );
}

class _CancellationReasonDialog extends StatefulWidget {
  const _CancellationReasonDialog({required this.reservation});

  final Reservation reservation;

  @override
  State<_CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<_CancellationReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Otkazati rezervaciju?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reservation.paymentStatus == 'Paid'
                  ? 'Za rezervaciju ${widget.reservation.confirmationCode} bit će pokrenut povrat punog uplaćenog iznosa.'
                  : 'Navedi razlog otkazivanja rezervacije ${widget.reservation.confirmationCode}.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text('Potvrdi otkazivanje'),
        ),
      ],
    );
  }
}
