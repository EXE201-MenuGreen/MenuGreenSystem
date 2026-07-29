import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/middleware/logging_middleware.dart';
import '../../../core/middleware/query_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../models/food_models.dart';

class FavoriteFoodsLoadResult {
  const FavoriteFoodsLoadResult({
    required this.items,
    required this.isFromCache,
    this.message,
  });

  final List<FavoriteFoodItem> items;
  final bool isFromCache;
  final String? message;
}

class FavoriteFoodMutationResult {
  const FavoriteFoodMutationResult.success({
    required this.isFavorite,
    this.item,
    this.message,
  }) : isSuccess = true;

  const FavoriteFoodMutationResult.failure({required this.message})
    : isSuccess = false,
      isFavorite = false,
      item = null;

  final bool isSuccess;
  final bool isFavorite;
  final FavoriteFoodItem? item;
  final String? message;
}

class FoodDiscoveryRepository {
  FoodDiscoveryRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  final TokenStorage _tokenStorage = TokenStorage();
  static const String _favStorageKeyPrefix = 'favorite_foods_cache';

  Future<List<FoodItem>> searchFoods({
    String? keyword,
    String allergyMode = 'warn',
    FoodSearchFilters? filters,
    String? region,
  }) async {
    try {
      final params = <String, String>{
        if (QueryMiddleware.normalizeKeyword(keyword) != null)
          'keyword': QueryMiddleware.normalizeKeyword(keyword)!,
        'allergyMode': allergyMode,
        if (filters?.minCalories != null)
          'minCalories': '${filters!.minCalories}',
        if (filters?.maxCalories != null)
          'maxCalories': '${filters!.maxCalories}',
        if (filters?.proteinLevel != null && filters!.proteinLevel!.isNotEmpty)
          'proteinLevel': filters.proteinLevel!,
        if (filters?.maxPriceVnd != null)
          'maxPriceVnd': '${filters!.maxPriceVnd}',
        if (filters?.category != null && filters!.category!.trim().isNotEmpty)
          'category': filters.category!.trim(),
        if (region != null && region.isNotEmpty) 'region': region,
        if (region != null && region.isNotEmpty) 'sort': 'local-friendly',
      };
      final url = QueryMiddleware.buildUrl(ApiEndpoints.foods, params);
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) return [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(FoodItem.fromJson)
          .toList();
    } catch (e, stack) {
      AppLogger.error('FoodDiscoveryRepository.searchFoods', e, stack);
      return [];
    }
  }

  Future<FoodItem?> getFoodById(
    String id, {
    String allergyMode = 'warn',
  }) async {
    try {
      final response = await _api.get(
        QueryMiddleware.buildUrl(ApiEndpoints.foodById(id), {
          'allergyMode': allergyMode,
        }),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return FoodItem.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<List<RecipeItem>> getFoodRecipes(String foodId) async {
    try {
      final response = await _api.get(ApiEndpoints.foodRecipes(foodId));
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RecipeItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RecipeItem>> searchRecipes({
    String? keyword,
    String allergyMode = 'warn',
  }) async {
    try {
      final params = <String, String>{
        if (QueryMiddleware.normalizeKeyword(keyword) != null)
          'keyword': QueryMiddleware.normalizeKeyword(keyword)!,
        'allergyMode': allergyMode,
      };
      final url = QueryMiddleware.buildUrl(ApiEndpoints.recipeSearch, params);
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) return [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(RecipeItem.fromJson)
          .toList();
    } catch (e, stack) {
      AppLogger.error('FoodDiscoveryRepository.searchRecipes', e, stack);
      return [];
    }
  }

  Future<RecipeItem?> getRecipeById(
    String id, {
    String allergyMode = 'warn',
  }) async {
    try {
      final response = await _api.get(
        QueryMiddleware.buildUrl(ApiEndpoints.recipeById(id), {
          'allergyMode': allergyMode,
        }),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return RecipeItem.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<List<FavoriteFoodItem>> getFavorites() async {
    return (await fetchFavorites()).items;
  }

  /// The API is authoritative. A user-scoped cache is used only on network failure.
  Future<FavoriteFoodsLoadResult> fetchFavorites({
    bool allowCacheFallback = true,
  }) async {
    try {
      final response = await _api.get(ApiEndpoints.foodFavorites);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          return const FavoriteFoodsLoadResult(
            items: [],
            isFromCache: false,
            message: 'Dá»¯ liá»‡u mÃ³n yÃªu thÃ­ch khÃ´ng há»£p lá»‡.',
          );
        }
        final items = decoded
            .whereType<Map<String, dynamic>>()
            .map(FavoriteFoodItem.fromJson)
            .toList();
        await cacheFavorites(items);
        return FavoriteFoodsLoadResult(items: items, isFromCache: false);
      }
      return _loadFavoriteCacheOrFailure(
        'KhÃ´ng thá»ƒ táº£i mÃ³n yÃªu thÃ­ch. Vui lÃ²ng thá»­ láº¡i.',
        allowCacheFallback,
      );
    } catch (error, stack) {
      AppLogger.error('FoodDiscoveryRepository.fetchFavorites', error, stack);
      return _loadFavoriteCacheOrFailure(
        'KhÃ´ng cÃ³ káº¿t ná»‘i máº¡ng. Vui lÃ²ng thá»­ láº¡i.',
        allowCacheFallback,
      );
    }
  }

  Future<FavoriteFoodMutationResult> addFavorite(String foodId) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.foodFavorite(foodId),
        {},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return FavoriteFoodMutationResult.failure(
          message: _favoriteErrorMessage(
            response.body,
            'KhÃ´ng thá»ƒ thÃªm mÃ³n vÃ o yÃªu thÃ­ch.',
          ),
        );
      }
      final decoded = _decodeMap(response.body);
      final rawItem = decoded?['item'] ?? decoded?['Item'];
      return FavoriteFoodMutationResult.success(
        isFavorite: true,
        item: rawItem is Map<String, dynamic>
            ? FavoriteFoodItem.fromJson(rawItem)
            : null,
        message: 'ÄÃ£ thÃªm mÃ³n vÃ o yÃªu thÃ­ch.',
      );
    } catch (error, stack) {
      AppLogger.error('FoodDiscoveryRepository.addFavorite', error, stack);
      return const FavoriteFoodMutationResult.failure(
        message:
            'KhÃ´ng cÃ³ káº¿t ná»‘i máº¡ng. KhÃ´ng thá»ƒ thÃªm mÃ³n vÃ o yÃªu thÃ­ch.',
      );
    }
  }

  Future<bool> legacyAddFavorite(String foodId) async {
    return saveFavoriteItem(
      FavoriteFoodItem(foodId: foodId, nameVi: 'Món ăn yêu thích'),
    );
  }

  Future<bool> removeFavorite(String foodId) async {
    return (await removeFavoriteResult(foodId)).isSuccess;
  }

  Future<FavoriteFoodMutationResult> removeFavoriteResult(String foodId) async {
    try {
      final response = await _api.delete(ApiEndpoints.foodFavorite(foodId));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return FavoriteFoodMutationResult.failure(
          message: _favoriteErrorMessage(
            response.body,
            'Kh\u00f4ng th\u1ec3 b\u1ecf m\u00f3n y\u00eau th\u00edch.',
          ),
        );
      }
      return const FavoriteFoodMutationResult.success(
        isFavorite: false,
        message: '\u0110\u00e3 b\u1ecf m\u00f3n kh\u1ecfi y\u00eau th\u00edch.',
      );
    } catch (error, stack) {
      AppLogger.error('FoodDiscoveryRepository.removeFavorite', error, stack);
      return const FavoriteFoodMutationResult.failure(
        message:
            'Kh\u00f4ng c\u00f3 k\u1ebft n\u1ed1i m\u1ea1ng. Kh\u00f4ng th\u1ec3 b\u1ecf m\u00f3n y\u00eau th\u00edch.',
      );
    }
  }

  Future<bool> saveFavoriteItem(FavoriteFoodItem item) async {
    return (await addFavorite(item.foodId)).isSuccess;
  }

  Future<void> cacheFavorites(List<FavoriteFoodItem> items) async {
    try {
      final key = await _favoriteCacheKey();
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        key,
        items.map((item) => jsonEncode(item.toJson())).toList(),
      );
    } catch (_) {}
  }

  Future<void> clearFavoriteCache() async {
    try {
      final key = await _favoriteCacheKey();
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  Future<FavoriteFoodsLoadResult> _loadFavoriteCacheOrFailure(
    String message,
    bool allowCacheFallback,
  ) async {
    if (!allowCacheFallback) {
      return FavoriteFoodsLoadResult(
        items: const [],
        isFromCache: false,
        message: message,
      );
    }
    try {
      final key = await _favoriteCacheKey();
      if (key == null) {
        return FavoriteFoodsLoadResult(
          items: const [],
          isFromCache: false,
          message: message,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(key) ?? const [];
      final items = raw
          .map(_decodeMap)
          .whereType<Map<String, dynamic>>()
          .map(FavoriteFoodItem.fromJson)
          .toList();
      if (items.isNotEmpty) {
        return FavoriteFoodsLoadResult(
          items: items,
          isFromCache: true,
          message: message,
        );
      }
    } catch (_) {}
    return FavoriteFoodsLoadResult(
      items: const [],
      isFromCache: false,
      message: message,
    );
  }

  Future<String?> _favoriteCacheKey() async {
    final userId = await _tokenStorage.getUserId();
    if (userId == null || userId.isEmpty) return null;
    return '$_favStorageKeyPrefix:$userId';
  }

  Map<String, dynamic>? _decodeMap(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {}
    return null;
  }

  String _favoriteErrorMessage(String raw, String fallback) {
    final decoded = _decodeMap(raw);
    final message = decoded?['message'] ?? decoded?['Message'];
    final value = message?.toString().trim();
    if (value == null || value.isEmpty) return fallback;
    final normalized = value.toLowerCase();
    if (normalized.contains('food not found')) {
      return 'M\u00f3n \u0103n kh\u00f4ng c\u00f2n t\u1ed3n t\u1ea1i.';
    }
    if (normalized.contains('inactive')) {
      return 'M\u00f3n \u0103n n\u00e0y hi\u1ec7n kh\u00f4ng th\u1ec3 \u0111\u01b0\u1ee3c l\u01b0u.';
    }
    if (normalized.contains('unauthorized')) {
      return 'Phi\u00ean \u0111\u0103ng nh\u1eadp \u0111\u00e3 h\u1ebft h\u1ea1n. Vui l\u00f2ng \u0111\u0103ng nh\u1eadp l\u1ea1i.';
    }
    return value;
  }

  Future<List<IngredientItem>> searchIngredients({
    String? keyword,
    String allergyMode = 'warn',
  }) async {
    try {
      final params = <String, String>{
        if (QueryMiddleware.normalizeKeyword(keyword) != null)
          'keyword': QueryMiddleware.normalizeKeyword(keyword)!,
        'allergyMode': allergyMode,
      };
      final url = QueryMiddleware.buildUrl(
        ApiEndpoints.ingredientSearch,
        params,
      );
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) return [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(IngredientItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<IngredientItem?> getIngredientById(
    String id, {
    String allergyMode = 'warn',
  }) async {
    try {
      final response = await _api.get(
        QueryMiddleware.buildUrl(ApiEndpoints.ingredientById(id), {
          'allergyMode': allergyMode,
        }),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return IngredientItem.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<List<IngredientRecipeLink>> getIngredientRecipes(
    String ingredientId,
  ) async {
    try {
      final response = await _api.get(
        ApiEndpoints.ingredientRecipes(ingredientId),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(IngredientRecipeLink.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ưu tiên danh sách dị ứng user đã lưu (`/api/Allergies`) — tránh banner sai khi summary timeout/lỗi.
  Future<bool> hasAllergiesConfigured() async {
    try {
      final response = await _api.get(ApiEndpoints.allergies);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final hasActive = decoded.whereType<Map<String, dynamic>>().any(
            (row) => (row['isActive'] ?? row['IsActive']) == true,
          );
          if (hasActive) return true;
        }
      }
    } catch (_) {
      // Tiếp tục thử summary.
    }

    try {
      final response = await _api.get(ApiEndpoints.profileSummary);
      if (response.statusCode != 200 || response.body.isEmpty) return false;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['hasAllergies'] == true || decoded['HasAllergies'] == true) {
        return true;
      }
      final count = decoded['allergyCount'] ?? decoded['AllergyCount'];
      if (count is int && count > 0) return true;
      if (count is num && count > 0) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}
