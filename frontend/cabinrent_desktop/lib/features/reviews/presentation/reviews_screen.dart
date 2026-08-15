import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../cabins/data/cabins_repository.dart';
import '../../cabins/domain/cabin.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';
import 'review_details_dialog.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> _reviews = [];
  List<Cabin> _cabins = [];
  bool _loading = true;
  String? _error;
  int? _cabinId;
  int? _rating;
  bool? _approved;
  String _search = '';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<ReviewsRepository>().getReviews(
          cabinId: _cabinId,
          rating: _rating,
          approved: _approved,
          search: _search,
        ),
        context.read<CabinsRepository>().getManagedCabins(),
      ]);
      if (!mounted) return;
      setState(() {
        _reviews = results[0] as List<Review>;
        _cabins = results[1] as List<Cabin>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchChanged(String value) {
    _search = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _changeApproval(Review review, bool approved) async {
    final action = approved ? 'objaviti' : 'sakriti';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Odobravanje recenzije' : 'Skrivanje recenzije'),
        content: Text(
          'Da li želite $action recenziju gosta „${review.guestName}“?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approved ? 'Odobri' : 'Sakrij'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ReviewsRepository>().setApproval(review.id, approved);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'Recenzija je objavljena.' : 'Recenzija je skrivena.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _showDetails(Review review) => showDialog<void>(
    context: context,
    builder: (_) => ReviewDetailsDialog(
      review: review,
      onApprovalChanged: (approved) => _changeApproval(review, approved),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recenzije',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pregled ocjena gostiju i upravljanje vidljivošću recenzija.',
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: _loading ? null : _load,
              tooltip: 'Osvježi',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: _searchChanged,
                decoration: const InputDecoration(
                  hintText: 'Pretraži gosta, vikendicu ili komentar',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<int?>(
                initialValue: _cabinId,
                decoration: const InputDecoration(labelText: 'Vikendica'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sve vikendice'),
                  ),
                  ..._cabins.map(
                    (cabin) => DropdownMenuItem<int?>(
                      value: cabin.id,
                      child: Text(cabin.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  _cabinId = value;
                  _load();
                },
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int?>(
                initialValue: _rating,
                decoration: const InputDecoration(labelText: 'Ocjena'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sve ocjene'),
                  ),
                  ...List.generate(
                    5,
                    (index) => DropdownMenuItem<int?>(
                      value: 5 - index,
                      child: Text('${5 - index} zvjezdica'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  _rating = value;
                  _load();
                },
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<bool?>(
                initialValue: _approved,
                decoration: const InputDecoration(labelText: 'Vidljivost'),
                items: const [
                  DropdownMenuItem<bool?>(
                    value: null,
                    child: Text('Sve recenzije'),
                  ),
                  DropdownMenuItem(value: true, child: Text('Objavljene')),
                  DropdownMenuItem(value: false, child: Text('Skrivene')),
                ],
                onChanged: (value) {
                  _approved = value;
                  _load();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(child: _content()),
      ],
    ),
  );

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recenzije nije moguće učitati.\n$_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return const Center(child: Text('Nema recenzija za odabrane filtere.'));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Vikendica')),
              DataColumn(label: Text('Gost')),
              DataColumn(label: Text('Ocjena')),
              DataColumn(label: Text('Komentar')),
              DataColumn(label: Text('Datum')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('')),
            ],
            rows: _reviews
                .map(
                  (review) => DataRow(
                    onSelectChanged: (_) => _showDetails(review),
                    cells: [
                      DataCell(
                        Text(
                          review.cabinName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(review.guestName)),
                      DataCell(_RatingStars(rating: review.rating)),
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            review.comment?.trim().isNotEmpty == true
                                ? review.comment!
                                : 'Bez komentara',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(formatReviewDate(review.createdAtUtc))),
                      DataCell(_ReviewStatus(approved: review.isApproved)),
                      DataCell(
                        PopupMenuButton<String>(
                          tooltip: 'Akcije',
                          onSelected: (value) {
                            if (value == 'details') {
                              _showDetails(review);
                            }
                            if (value == 'approval') {
                              _changeApproval(review, !review.isApproved);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Text('Prikaži detalje'),
                            ),
                            PopupMenuItem(
                              value: 'approval',
                              child: Text(
                                review.isApproved
                                    ? 'Sakrij recenziju'
                                    : 'Odobri recenziju',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});
  final int rating;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (index) => Icon(
        index < rating ? Icons.star : Icons.star_border,
        size: 18,
        color: Colors.amber.shade700,
      ),
    ),
  );
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({required this.approved});
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
