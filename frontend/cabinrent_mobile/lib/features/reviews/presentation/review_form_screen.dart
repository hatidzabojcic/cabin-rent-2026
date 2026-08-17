import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../reservations/domain/reservation.dart';
import 'reviews_controller.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({required this.reservation, super.key});

  final Reservation reservation;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comment = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite ocjenu od 1 do 5.')),
      );
      return;
    }
    final controller = context.read<ReviewsController>();
    final review = await controller.create(
      reservationId: widget.reservation.id,
      rating: _rating,
      comment: _comment.text,
    );
    if (!mounted) return;
    if (review != null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Dojam trenutno nije moguće poslati.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<ReviewsController>().isSubmitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Ostavi dojam')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.reservation.cabinName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${formatDate(widget.reservation.checkIn)} – '
                '${formatDate(widget.reservation.checkOut)}',
              ),
              const SizedBox(height: 28),
              Text(
                'Kako biste ocijenili boravak?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: _rating == 0
                    ? 'Ocjena nije odabrana'
                    : 'Odabrana ocjena $_rating od 5',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: 'Ocjena $value',
                      onPressed: isSubmitting
                          ? null
                          : () => setState(() => _rating = value),
                      iconSize: 42,
                      icon: Icon(
                        value <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber.shade700,
                      ),
                    );
                  }),
                ),
              ),
              if (_rating > 0)
                Text(
                  _ratingLabel(_rating),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _comment,
                enabled: !isSubmitting,
                minLines: 5,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Komentar (opcionalno)',
                  hintText: 'Podijelite iskustvo i prijedloge za poboljšanje.',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value != null && value.length > 2000
                    ? 'Komentar može sadržavati najviše 2000 znakova.'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isSubmitting ? null : _submit,
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_outlined),
                label: const Text('Pošalji dojam'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dojam će biti vidljiv drugim gostima nakon odobrenja.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) => const {
    1: 'Vrlo loše',
    2: 'Loše',
    3: 'Dobro',
    4: 'Vrlo dobro',
    5: 'Odlično',
  }[rating]!;
}
