import 'package:flutter/foundation.dart';

@immutable
class RouteApprovalMeal {
  const RouteApprovalMeal({
    required this.mealType,
    required this.name,
    required this.calories,
  });

  final String mealType;
  final String name;
  final int calories;

  factory RouteApprovalMeal.fromJson(Map<String, dynamic> json) {
    final foodName = _string(json, 'foodName');
    final recipeName = _string(json, 'recipeName');
    return RouteApprovalMeal(
      mealType: _string(json, 'mealType') ?? 'snack',
      name: foodName?.isNotEmpty == true
          ? foodName!
          : recipeName?.isNotEmpty == true
          ? recipeName!
          : _string(json, 'name') ?? 'Món ăn',
      calories: _int(json, 'targetCalories') ?? _int(json, 'calories') ?? 0,
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
    required this.weekStartDate,
    required this.status,
    required this.ptComment,
    required this.days,
    this.suggestedCalorieTarget,
    this.suggestedProteinTarget,
  });

  final String requestId;
  final DateTime weekStartDate;
  final String status;
  final String ptComment;
  final int? suggestedCalorieTarget;
  final int? suggestedProteinTarget;
  final List<RouteApprovalDay> days;

  RouteApprovalDetail copyWith({List<RouteApprovalDay>? days}) {
    return RouteApprovalDetail(
      requestId: requestId,
      weekStartDate: weekStartDate,
      status: status,
      ptComment: ptComment,
      suggestedCalorieTarget: suggestedCalorieTarget,
      suggestedProteinTarget: suggestedProteinTarget,
      days: days ?? this.days,
    );
  }

  factory RouteApprovalDetail.fromJson(Map<String, dynamic> json) {
    final rawReport = _value(json, 'reportData');
    final report = rawReport is Map
        ? Map<String, dynamic>.from(rawReport)
        : const <String, dynamic>{};
    final rawDays = _value(report, 'dailyMeals');
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
      weekStartDate:
          DateTime.tryParse(_string(json, 'weekStartDate') ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _string(json, 'status') ?? '',
      ptComment: _string(json, 'ptComment') ?? '',
      suggestedCalorieTarget: _int(json, 'suggestedCalorieTarget'),
      suggestedProteinTarget: _int(json, 'suggestedProteinTarget'),
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
