import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/middleware/query_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/food_models.dart';

class FoodDiscoveryRepository {
  FoodDiscoveryRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  static const String _favStorageKey = 'user_favorite_foods_cache';

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
        if (filters?.minCalories != null) 'minCalories': '${filters!.minCalories}',
        if (filters?.maxCalories != null) 'maxCalories': '${filters!.maxCalories}',
        if (filters?.proteinLevel != null && filters!.proteinLevel!.isNotEmpty)
          'proteinLevel': filters.proteinLevel!,
        if (filters?.maxPriceVnd != null) 'maxPriceVnd': '${filters!.maxPriceVnd}',
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
      return items.whereType<Map<String, dynamic>>().map(FoodItem.fromJson).toList();
    } catch (e, stack) {
      print('Error searchFoods: $e\n$stack');
      return [];
    }
  }

  Future<FoodItem?> getFoodById(String id, {String allergyMode = 'warn'}) async {
    try {
      final response = await _api.get(
        QueryMiddleware.buildUrl(
          ApiEndpoints.foodById(id),
          {'allergyMode': allergyMode},
        ),
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
      return decoded.whereType<Map<String, dynamic>>().map(RecipeItem.fromJson).toList();
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
      return items.whereType<Map<String, dynamic>>().map(RecipeItem.fromJson).toList();
    } catch (e, stack) {
      print('Error searchRecipes: $e\n$stack');
      return [];
    }
  }

  Future<RecipeItem?> getRecipeById(String id, {String allergyMode = 'warn'}) async {
    try {
      final response = await _api.get(
        QueryMiddleware.buildUrl(
          ApiEndpoints.recipeById(id),
          {'allergyMode': allergyMode},
        ),
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
    final List<FavoriteFoodItem> result = [];
    final Set<String> existingIds = {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_favStorageKey) ?? [];
      for (final s in raw) {
        final map = jsonDecode(s);
        if (map is Map<String, dynamic>) {
          final item = FavoriteFoodItem.fromJson(map);
          if (existingIds.add(item.foodId)) {
            result.add(item);
          }
        }
      }
    } catch (_) {}

    try {
      final response = await _api.get(ApiEndpoints.foodFavorites);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          for (final raw in decoded.whereType<Map<String, dynamic>>()) {
            final item = FavoriteFoodItem.fromJson(raw);
            if (existingIds.add(item.foodId)) {
              result.add(item);
            }
          }
        }
      }
    } catch (_) {}

    return result;
  }

  Future<bool> saveFavoriteItem(FavoriteFoodItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favStorageKey) ?? [];
      list.removeWhere((s) {
        try {
          final map = jsonDecode(s);
          return map['foodId'] == item.foodId;
        } catch (_) {
          return false;
        }
      });
      list.insert(0, jsonEncode(item.toJson()));
      await prefs.setStringList(_favStorageKey, list);
    } catch (_) {}

    try {
      await _api.postJson(ApiEndpoints.foodFavorite(item.foodId), {});
    } catch (_) {}
    return true;
  }

  Future<bool> addFavorite(String foodId) async {
    return saveFavoriteItem(FavoriteFoodItem(foodId: foodId, nameVi: 'Món ăn yêu thích'));
  }

  Future<bool> removeFavorite(String foodId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favStorageKey) ?? [];
      list.removeWhere((s) {
        try {
          final map = jsonDecode(s);
          return map['foodId'] == foodId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_favStorageKey, list);
    } catch (_) {}

    try {
      await _api.delete(ApiEndpoints.foodFavorite(foodId));
    } catch (_) {}
    return true;
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
      final url = QueryMiddleware.buildUrl(ApiEndpoints.ingredientSearch, params);
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) return [];
      return items.whereType<Map<String, dynamic>>().map(IngredientItem.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<IngredientItem?> getIngredientById(String id, {String allergyMode = 'warn'}) async {
    try {
      final response = await _api.get(
        QueryMiddleware.buildUrl(
          ApiEndpoints.ingredientById(id),
          {'allergyMode': allergyMode},
        ),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return IngredientItem.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<List<IngredientRecipeLink>> getIngredientRecipes(String ingredientId) async {
    try {
      final response = await _api.get(ApiEndpoints.ingredientRecipes(ingredientId));
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
