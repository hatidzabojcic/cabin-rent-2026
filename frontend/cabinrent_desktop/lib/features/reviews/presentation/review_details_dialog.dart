import 'package:flutter/material.dart';

import '../domain/review.dart';

class ReviewDetailsDialog extends StatelessWidget {
  const ReviewDetailsDialog({
    super.key,
    required this.review,
    required this.onApprovalChanged,
  });
  final Review review;
  final ValueChanged<bool> onApprovalChanged;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Row(
      children: [
        Icon(Icons.rate_review_outlined),
        SizedBox(width: 10),
        Text('Detalji recenzije'),
      ],
    ),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ApprovalChip(approved: review.isApproved),
              const SizedBox(width: 10),
              _Stars(rating: review.rating),
            ],
          ),
          const SizedBox(height: 22),
          _row('Vikendica', review.cabinName),
          _row('Gost', review.guestName),
          _row('Email', review.guestEmail),
          _row('Datum', formatReviewDate(review.createdAtUtc)),
          _row('Rezervacija', '#${review.reservationId}'),
          const SizedBox(height: 10),
          const Text('Komentar', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              review.comment?.trim().isNotEmpty == true
                  ? review.comment!
                  : 'Komentar nije unesen.',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zatvori'),
      ),
      FilledButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onApprovalChanged(!review.isApproved);
        },
        icon: Icon(
          review.isApproved
              ? Icons.visibility_off_outlined
              : Icons.check_circle_outline,
        ),
        label: Text(
          review.isApproved ? 'Sakrij recenziju' : 'Odobri recenziju',
        ),
      ),
    ],
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        SizedBox(
          width: 130,
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

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (index) => Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber.shade700,
        size: 21,
      ),
    ),
  );
}

class _ApprovalChip extends StatelessWidget {
  const _ApprovalChip({required this.approved});
  final bool approved;
  @override
  Widget build(BuildContext context) {
    final color = approved ? Colors.green : Colors.orange;
    return Chip(
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .1),
      label: Text(
        approved ? 'Objavljena' : 'Skrivena',
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }
}
