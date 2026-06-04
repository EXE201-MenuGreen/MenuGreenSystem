import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class NutritionTrackingRepository {
  NutritionTrackingRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<MealDaySummary?> getDailySummary(DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await _api.get('${ApiEndpoints.nutritionDaily}?date=$dateStr');
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return MealDaySummary.fromJson(decoded);
  }

  Future<NutritionDashboard?> getDashboard({
    String range = 'week',
  }) async {
    final response =
        await _api.get('${ApiEndpoints.nutritionDashboard}?range=$range');
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return NutritionDashboard.fromJson(decoded);
  }

  Future<bool> createWeightLog({
    required double weightKg,
    double? bodyFatPercent,
    DateTime? recordedAt,
  }) async {
    final response = await _api.postJson(ApiEndpoints.nutritionWeightLogs, {
      'weightKg': weightKg,
      'bodyFatPercent': bodyFatPercent,
      'recordedAt': recordedAt?.toUtc().toIso8601String(),
    });
    return response.statusCode == 200;
  }

  Future<bool> deleteMealLog(String mealLogId) async {
    final response = await _api.delete(ApiEndpoints.nutritionMealLogById(mealLogId));
    return response.statusCode == 200;
  }

  Future<bool> createMealLog({
    String? foodId,
    String? recipeId,
    required String mealType,
    required double quantityG,
    String? notes,
    DateTime? loggedAt,
  }) async {
    final response = await _api.postJson(ApiEndpoints.nutritionMealLogs, {
      'foodId': foodId,
      'recipeId': recipeId,
      'mealType': mealType,
      'quantityG': quantityG,
      'notes': notes,
      'loggedAt': loggedAt?.toUtc().toIso8601String(),
    });
    return response.statusCode == 200;
  }

  Future<List<CatalogItem>> getFoods({String? keyword}) async {
    final query = (keyword != null && keyword.trim().isNotEmpty)
        ? '?keyword=${Uri.encodeQueryComponent(keyword.trim())}'
        : '';
    final response = await _api.get('${ApiEndpoints.foods}$query');
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final items = decoded['items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => CatalogItem.fromJson(e, fallbackNameKey: 'nameVi'))
        .toList();
  }

  Future<List<CatalogItem>> getRecipes({String? keyword}) async {
    final query = (keyword != null && keyword.trim().isNotEmpty)
        ? '?keyword=${Uri.encodeQueryComponent(keyword.trim())}'
        : '';
    final response = await _api.get('${ApiEndpoints.recipeSearch}$query');
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final items = decoded['items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => CatalogItem.fromJson(e, fallbackNameKey: 'title'))
        .toList();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class NutritionDashboard {
  NutritionDashboard({
    required this.range,
    required this.days,
    required this.weightLogs,
  });

  final String range;
  final List<MealDaySummary> days;
  final List<WeightLogItem> weightLogs;

  factory NutritionDashboard.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final rawWeightLogs = json['weightLogs'];
    return NutritionDashboard(
      range: (json['range'] ?? '').toString(),
      days: rawDays is List
          ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(MealDaySummary.fromJson)
              .toList()
          : [],
      weightLogs: rawWeightLogs is List
          ? rawWeightLogs
              .whereType<Map<String, dynamic>>()
              .map(WeightLogItem.fromJson)
              .toList()
          : [],
    );
  }
}

class MealDaySummary {
  MealDaySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.mealLogs,
  });

  final String date;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final List<MealLogItem> mealLogs;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  factory MealDaySummary.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['mealLogs'];
    return MealDaySummary(
      date: (json['date'] ?? '').toString(),
      totalCalories: _asDouble(json['totalCalories']),
      totalProteinG: _asDouble(json['totalProteinG']),
      totalCarbsG: _asDouble(json['totalCarbsG']),
      totalFatG: _asDouble(json['totalFatG']),
      targetCalories: _asDouble(json['targetCalories']),
      targetProteinG: _asDouble(json['targetProteinG']),
      targetCarbsG: _asDouble(json['targetCarbsG']),
      targetFatG: _asDouble(json['targetFatG']),
      mealLogs: rawLogs is List
          ? rawLogs
              .whereType<Map<String, dynamic>>()
              .map(MealLogItem.fromJson)
              .toList()
          : [],
    );
  }
}

class MealLogItem {
  MealLogItem({
    required this.id,
    required this.mealType,
    required this.quantityG,
    required this.caloriesKcal,
    required this.loggedAt,
    required this.displayName,
  });

  final String id;
  final String mealType;
  final double quantityG;
  final double caloriesKcal;
  final DateTime? loggedAt;
  final String displayName;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  factory MealLogItem.fromJson(Map<String, dynamic> json) {
    final loggedAtRaw = json['loggedAt']?.toString();
    final foodName = json['foodName']?.toString().trim();
    final recipeTitle = json['recipeTitle']?.toString().trim();
    final displayName = json['displayName']?.toString().trim();
    final resolvedName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (foodName != null && foodName.isNotEmpty)
            ? foodName
            : (recipeTitle != null && recipeTitle.isNotEmpty)
                ? recipeTitle
                : 'Món đã ghi';

    return MealLogItem(
      id: (json['id'] ?? '').toString(),
      mealType: (json['mealType'] ?? 'snack').toString(),
      quantityG: _asDouble(json['quantityG']),
      caloriesKcal: _asDouble(json['caloriesKcal']),
      loggedAt: loggedAtRaw == null ? null : DateTime.tryParse(loggedAtRaw)?.toLocal(),
      displayName: resolvedName,
    );
  }
}

class WeightLogItem {
  WeightLogItem({
    required this.id,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.recordedAt,
  });

  final String id;
  final double weightKg;
  final double? bodyFatPercent;
  final DateTime? recordedAt;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  factory WeightLogItem.fromJson(Map<String, dynamic> json) {
    final recordedAtRaw = json['recordedAt']?.toString();
    return WeightLogItem(
      id: (json['id'] ?? '').toString(),
      weightKg: _asDouble(json['weightKg']),
      bodyFatPercent: _asNullableDouble(json['bodyFatPercent']),
      recordedAt:
          recordedAtRaw == null ? null : DateTime.tryParse(recordedAtRaw)?.toLocal(),
    );
  }
}

class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CatalogItem.fromJson(
    Map<String, dynamic> json, {
    required String fallbackNameKey,
  }) {
    final name = (json[fallbackNameKey] ??
            json['nameVi'] ??
            json['title'] ??
            json['name'] ??
            '')
        .toString();
    return CatalogItem(
      id: (json['id'] ?? '').toString(),
      name: name.isEmpty ? 'Không tên' : name,
    );
  }
}
