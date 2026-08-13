import 'package:flutter/foundation.dart';

import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';

class FavoriteFoodActionResult {
  const FavoriteFoodActionResult({
    required this.isSuccess,
    required this.isFavorite,
    required this.message,
  });

  final bool isSuccess;
  final bool isFavorite;
  final String message;
}

/// Shared favorite state for every authenticated food screen.
///
/// The UI can update optimistically, but the mutation is rolled back whenever
/// the backend does not confirm it.
class FavoriteFoodProvider extends ChangeNotifier {
  FavoriteFoodProvider({
    FoodDiscoveryRepository? repository,
    Future<FavoriteFoodsLoadResult> Function()? fetchFavorites,
    Future<FavoriteFoodMutationResult> Function(String foodId)? addFavorite,
    Future<FavoriteFoodMutationResult> Function(String foodId)? removeFavorite,
    Future<void> Function(List<FavoriteFoodItem> items)? cacheFavorites,
  }) : _repository = repository ?? FoodDiscoveryRepository(),
       _fetchFavoritesOverride = fetchFavorites,
       _addFavoriteOverride = addFavorite,
       _removeFavoriteOverride = removeFavorite,
       _cacheFavoritesOverride = cacheFavorites;

  final FoodDiscoveryRepository _repository;
  final Future<FavoriteFoodsLoadResult> Function()? _fetchFavoritesOverride;
  final Future<FavoriteFoodMutationResult> Function(String foodId)?
  _addFavoriteOverride;
  final Future<FavoriteFoodMutationResult> Function(String foodId)?
  _removeFavoriteOverride;
  final Future<void> Function(List<FavoriteFoodItem> items)?
  _cacheFavoritesOverride;
  final List<FavoriteFoodItem> _items = [];
  final Set<String> _mutatingIds = {};

  bool _isLoading = false;
  bool _isFromCache = false;
  String? _message;

  List<FavoriteFoodItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isFromCache => _isFromCache;
  String? get message => _message;

  bool isFavorite(String foodId) => _items.any((item) => item.foodId == foodId);

  bool isMutating(String foodId) => _mutatingIds.contains(foodId);

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result =
        await (_fetchFavoritesOverride?.call() ?? _repository.fetchFavorites());
    _items
      ..clear()
      ..addAll(result.items);
    _isFromCache = result.isFromCache;
    _message = result.message;
    _isLoading = false;
    notifyListeners();
  }

  Future<FavoriteFoodActionResult> toggle(FavoriteFoodItem item) async {
    if (item.foodId.isEmpty) {
      return const FavoriteFoodActionResult(
        isSuccess: false,
        isFavorite: false,
        message: 'Món ăn không hợp lệ.',
      );
    }
    if (isMutating(item.foodId)) {
      return FavoriteFoodActionResult(
        isSuccess: false,
        isFavorite: isFavorite(item.foodId),
        message: 'Đang cập nhật món yêu thích. Vui lòng chờ.',
      );
    }

    final wasFavorite = isFavorite(item.foodId);
    final previousItems = List<FavoriteFoodItem>.from(_items);
    _mutatingIds.add(item.foodId);

    if (wasFavorite) {
      _items.removeWhere((saved) => saved.foodId == item.foodId);
    } else {
      _items.removeWhere((saved) => saved.foodId == item.foodId);
      _items.insert(0, item);
    }
    notifyListeners();

    final result = wasFavorite
        ? await (_removeFavoriteOverride?.call(item.foodId) ??
              _repository.removeFavoriteResult(item.foodId))
        : await (_addFavoriteOverride?.call(item.foodId) ??
              _repository.addFavorite(item.foodId));

    _mutatingIds.remove(item.foodId);
    if (!result.isSuccess) {
      _items
        ..clear()
        ..addAll(previousItems);
      notifyListeners();
      return FavoriteFoodActionResult(
        isSuccess: false,
        isFavorite: wasFavorite,
        message: 'Kh\u00f4ng th\u1ec3 c\u1eadp nh\u1eadt m\u00f3n y\u00eau th\u00edch. Vui l\u00f2ng th\u1eed l\u1ea1i.',
      );
    }

    if (result.isFavorite) {
      final confirmed = result.item ?? item;
      _items.removeWhere((saved) => saved.foodId == item.foodId);
      _items.insert(0, confirmed);
    } else {
      _items.removeWhere((saved) => saved.foodId == item.foodId);
    }
    _isFromCache = false;
    _message = null;
    await (_cacheFavoritesOverride?.call(_items) ??
        _repository.cacheFavorites(_items));
    notifyListeners();

    return FavoriteFoodActionResult(
      isSuccess: true,
      isFavorite: result.isFavorite,
      message: result.isFavorite
          ? '\u0110\u00e3 th\u00eam m\u00f3n v\u00e0o y\u00eau th\u00edch.'
          : '\u0110\u00e3 b\u1ecf m\u00f3n kh\u1ecfi y\u00eau th\u00edch.',
    );
  }

  Future<void> clearSession() async {
    _items.clear();
    _mutatingIds.clear();
    _isFromCache = false;
    _message = null;
    await _repository.clearFavoriteCache();
    notifyListeners();
  }
}
