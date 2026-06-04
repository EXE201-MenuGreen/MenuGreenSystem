import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/food_models.dart';

class FoodDiscoveryRepository {
  FoodDiscoveryRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<FoodItem>> searchFoods({
    String? keyword,
    String allergyMode = 'warn',
    FoodSearchFilters? filters,
  }) async {
    try {
      final params = <String, String>{
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'allergyMode': allergyMode,
        if (filters?.minCalories != null) 'minCalories': '${filters!.minCalories}',
        if (filters?.maxCalories != null) 'maxCalories': '${filters!.maxCalories}',
        if (filters?.proteinLevel != null && filters!.proteinLevel!.isNotEmpty)
          'proteinLevel': filters.proteinLevel!,
        if (filters?.maxPriceVnd != null) 'maxPriceVnd': '${filters!.maxPriceVnd}',
        if (filters?.category != null && filters!.category!.trim().isNotEmpty)
          'category': filters.category!.trim(),
      };
      final query = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final url = query.isEmpty ? ApiEndpoints.foods : '${ApiEndpoints.foods}?$query';
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) return [];
      return items.whereType<Map<String, dynamic>>().map(FoodItem.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<FoodItem?> getFoodById(String id, {String allergyMode = 'warn'}) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.foodById(id)}?allergyMode=${Uri.encodeQueryComponent(allergyMode)}',
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
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        'allergyMode': allergyMode,
      };
      final query = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final url = query.isEmpty ? ApiEndpoints.recipeSearch : '${ApiEndpoints.recipeSearch}?$query';
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) return [];
      return items.whereType<Map<String, dynamic>>().map(RecipeItem.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<RecipeItem?> getRecipeById(String id, {String allergyMode = 'warn'}) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.recipeById(id)}?allergyMode=${Uri.encodeQueryComponent(allergyMode)}',
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
    try {
      final response = await _api.get(ApiEndpoints.foodFavorites);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded.whereType<Map<String, dynamic>>().map(FavoriteFoodItem.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addFavorite(String foodId) async {
    try {
      final response = await _api.postJson(ApiEndpoints.foodFavorite(foodId), {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFavorite(String foodId) async {
    try {
      final response = await _api.delete(ApiEndpoints.foodFavorite(foodId));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<IngredientItem>> searchIngredients({
    String? keyword,
    String allergyMode = 'warn',
  }) async {
    try {
      final params = <String, String>{
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'allergyMode': allergyMode,
      };
      final query = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final url = query.isEmpty
          ? ApiEndpoints.ingredientSearch
          : '${ApiEndpoints.ingredientSearch}?$query';
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
        '${ApiEndpoints.ingredientById(id)}?allergyMode=${Uri.encodeQueryComponent(allergyMode)}',
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
