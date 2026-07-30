import 'package:flutter/foundation.dart';

@immutable
class RouteApprovalMeal {
  const RouteApprovalMeal({
    required this.id,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.isCompleted,
    this.foodId,
    this.recipeId,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String id;
  final String mealType;
  final String name;
  final int calories;
  final bool isCompleted;
  final String? foodId;
  final String? recipeId;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;

  RouteApprovalMeal copyWith({bool? isCompleted}) {
    return RouteApprovalMeal(
      id: id,
      mealType: mealType,
      name: name,
      calories: calories,
      isCompleted: isCompleted ?? this.isCompleted,
      foodId: foodId,
      recipeId: recipeId,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  }

  factory RouteApprovalMeal.fromJson(Map<String, dynamic> json) {
    final foodName = _string(json, 'foodName');
    final recipeName = _string(json, 'recipeName');
    return RouteApprovalMeal(
      id: _string(json, 'id') ?? '',
      mealType: _string(json, 'mealType') ?? 'snack',
      name: foodName?.isNotEmpty == true
          ? foodName!
          : recipeName?.isNotEmpty == true
          ? recipeName!
          : _string(json, 'name') ?? 'Món ăn',
      calories: _int(json, 'targetCalories') ?? _int(json, 'calories') ?? 0,
      isCompleted: _bool(json, 'isCompleted'),
      foodId: _string(json, 'foodId'),
      recipeId: _string(json, 'recipeId'),
      proteinG: _int(json, 'proteinG'),
      carbsG: _int(json, 'carbsG'),
      fatG: _int(json, 'fatG'),
    );
  }
}

@immutable
class RouteApprovalDay {
  const RouteApprovalDay({required this.date, required this.meals});

  final DateTime date;
  final List<RouteApprovalMeal> meals;

  factory RouteApprovalDay.fromJson(Map<String, dynamic> json) {
    final rawMeals =
        _value(json, 'plannedItems') ?? _value(json, 'meals') ?? const [];
    final meals = rawMeals is List
        ? rawMeals
              .whereType<Map>()
              .map(
                (item) =>
                    RouteApprovalMeal.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <RouteApprovalMeal>[];
    return RouteApprovalDay(
      date:
          DateTime.tryParse(_string(json, 'date') ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      meals: meals,
    );
  }
}

@immutable
class RouteApprovalDetail {
  const RouteApprovalDetail({
    required this.requestId,
    required this.requestType,
    required this.weekStartDate,
    required this.createdAt,
    required this.status,
    required this.ptComment,
    required this.studentNote,
    required this.days,
    this.suggestedCalorieTarget,
    this.suggestedProteinTarget,
    this.configuredCalorieTarget,
    this.configuredMinCalories,
    this.configuredMaxCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
  });

  final String requestId;
  final String requestType;
  final DateTime weekStartDate;
  final DateTime? createdAt;
  final String status;
  final String ptComment;
  final String studentNote;
  final int? suggestedCalorieTarget;
  final int? suggestedProteinTarget;
  final int? configuredCalorieTarget;
  final int? configuredMinCalories;
  final int? configuredMaxCalories;
  final int? targetProteinG;
  final int? targetCarbsG;
  final int? targetFatG;
  final List<RouteApprovalDay> days;

  RouteApprovalDetail copyWith({List<RouteApprovalDay>? days}) {
    return RouteApprovalDetail(
      requestId: requestId,
      requestType: requestType,
      weekStartDate: weekStartDate,
      createdAt: createdAt,
      status: status,
      ptComment: ptComment,
      studentNote: studentNote,
      suggestedCalorieTarget: suggestedCalorieTarget,
      suggestedProteinTarget: suggestedProteinTarget,
      configuredCalorieTarget: configuredCalorieTarget,
      configuredMinCalories: configuredMinCalories,
      configuredMaxCalories: configuredMaxCalories,
      targetProteinG: targetProteinG,
      targetCarbsG: targetCarbsG,
      targetFatG: targetFatG,
      days: days ?? this.days,
    );
  }

  factory RouteApprovalDetail.fromJson(Map<String, dynamic> json) {
    final rawReport = _value(json, 'reportData');
    final report = rawReport is Map
        ? Map<String, dynamic>.from(rawReport)
        : const <String, dynamic>{};
    final rawDays = _value(report, 'dailyMeals');
    final rawHealth = _value(report, 'studentHealthProfile');
    final health = rawHealth is Map
        ? Map<String, dynamic>.from(rawHealth)
        : const <String, dynamic>{};
    final days = rawDays is List
        ? rawDays
              .whereType<Map>()
              .map(
                (item) =>
                    RouteApprovalDay.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <RouteApprovalDay>[];

    return RouteApprovalDetail(
      requestId: _string(json, 'reportId') ?? '',
      requestType:
          _string(json, 'requestType') ??
          _string(report, 'requestType') ??
          'WeeklyReport',
      weekStartDate:
          DateTime.tryParse(_string(json, 'weekStartDate') ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: DateTime.tryParse(_string(json, 'createdAt') ?? ''),
      status: _string(json, 'status') ?? '',
      ptComment: _string(json, 'ptComment') ?? '',
      studentNote:
          _string(json, 'studentNote') ?? _string(report, 'studentNote') ?? '',
      suggestedCalorieTarget: _int(json, 'suggestedCalorieTarget'),
      suggestedProteinTarget: _int(json, 'suggestedProteinTarget'),
      configuredCalorieTarget:
          _int(json, 'configuredCalorieTarget') ??
          _int(report, 'targetCaloriesDaily'),
      configuredMinCalories:
          _int(json, 'configuredMinCalories') ?? _int(report, 'minCalories'),
      configuredMaxCalories:
          _int(json, 'configuredMaxCalories') ?? _int(report, 'maxCalories'),
      targetProteinG:
          _int(health, 'targetProteinG') ??
          _int(json, 'suggestedProteinTarget'),
      targetCarbsG: _int(health, 'targetCarbsG'),
      targetFatG: _int(health, 'targetFatG'),
      days: days,
    );
  }
}

dynamic _value(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
  return json[pascal];
}

String? _string(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  return value?.toString();
}

int? _int(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}
