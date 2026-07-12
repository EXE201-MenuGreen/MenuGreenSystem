import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Ingredient substitution preference provider — `2.18 Ingredient Substitution Preference`.
class IngredientSubstitutionProvider extends ChangeNotifier {
  IngredientSubstitutionProvider({
    IngredientSubstitutionPreferencesRepository? repository,
  }) : _repo = repository ?? IngredientSubstitutionPreferencesRepository();

  final IngredientSubstitutionPreferencesRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;

  List<IngredientSubstitutePreference> _items = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<IngredientSubstitutePreference> get items => _items;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.list();
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _items = const [];
      notifyListeners();
      return;
    }
    _items = result.data ?? const [];
    notifyListeners();
  }

  Future<bool> add({
    required String originalIngredientId,
    required String originalIngredientName,
    required String substituteIngredientId,
    required String substituteIngredientName,
    required String reason,
    int? maxPriceVnd,
    bool macroMatch = false,
  }) async {
    final result = await _repo.create({
      'originalIngredientId': originalIngredientId,
      'originalIngredientName': originalIngredientName,
      'substituteIngredientId': substituteIngredientId,
      'substituteIngredientName': substituteIngredientName,
      'reason': reason,
      'maxPriceVnd': ?maxPriceVnd,
      'macroMatch': macroMatch,
    });
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<bool> remove(String id) async {
    final result = await _repo.delete(id);
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _items = _items.where((e) => e.id != id).toList();
    notifyListeners();
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
