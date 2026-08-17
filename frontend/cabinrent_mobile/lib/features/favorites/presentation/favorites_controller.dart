import 'package:flutter/foundation.dart';

import '../data/favorites_repository.dart';
import '../domain/favorite.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoritesRepository _repository;

  List<Favorite> favorites = [];
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;
  final Set<int> _updating = {};

  bool contains(int cabinId) =>
      favorites.any((favorite) => favorite.cabinId == cabinId);
  bool isUpdating(int cabinId) => _updating.contains(cabinId);

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      favorites = await _repository.getFavorites();
      hasLoaded = true;
    } catch (_) {
      errorMessage = 'Omiljene vikendice trenutno nije moguće učitati.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(int cabinId) async {
    if (_updating.contains(cabinId)) return false;
    _updating.add(cabinId);
    errorMessage = null;
    final existingIndex = favorites.indexWhere(
      (favorite) => favorite.cabinId == cabinId,
    );
    final removed = existingIndex < 0 ? null : favorites[existingIndex];
    if (removed != null) {
      favorites = [...favorites]..removeAt(existingIndex);
    }
    notifyListeners();
    try {
      if (removed == null) {
        final favorite = await _repository.add(cabinId);
        favorites = [...favorites, favorite];
      } else {
        await _repository.remove(cabinId);
      }
      return true;
    } catch (_) {
      if (removed != null) favorites = [...favorites, removed];
      errorMessage = removed == null
          ? 'Vikendicu nije moguće dodati u omiljene.'
          : 'Vikendicu nije moguće ukloniti iz omiljenih.';
      return false;
    } finally {
      _updating.remove(cabinId);
      notifyListeners();
    }
  }
}
