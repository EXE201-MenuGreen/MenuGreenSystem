// Vietnam-local feature data models.
//
// Endpoint schemas are described in `docs/features/10-vietnam-local-features.md`.
// Keep field names aligned with the backend DTOs under
// `backend/MenuGreen.BusinessLogicLayer/DTOs/Responses`.
import 'package:flutter/foundation.dart';

/// DailyStarter /today response (DailyStarterTodayResponse.cs).
@immutable
class DailyStarterToday {
  const DailyStarterToday({
    this.welcomeMessage = '',
    this.quote = '',
    this.author = '',
    this.caloriesTarget = 0,
    this.isOnboardingComplete = false,
    this.hasLoggedToday = false,
    this.currentWeightKg,
  });

  final String welcomeMessage;
  final String quote;
  final String author;
  final double caloriesTarget;
  final bool isOnboardingComplete;
  final bool hasLoggedToday;
  final double? currentWeightKg;

  factory DailyStarterToday.fromJson(Map<String, dynamic> json) {
    return DailyStarterToday(
      welcomeMessage: _string(json, 'welcomeMessage') ?? _string(json, 'WelcomeMessage') ?? '',
      quote: _string(json, 'quote') ?? _string(json, 'Quote') ?? '',
      author: _string(json, 'author') ?? _string(json, 'Author') ?? '',
      caloriesTarget: _double(json, 'caloriesTarget') ?? _double(json, 'CaloriesTarget') ?? 0,
      isOnboardingComplete: _bool(json, 'isOnboardingComplete') ?? _bool(json, 'IsOnboardingComplete') ?? false,
      hasLoggedToday: _bool(json, 'hasLoggedToday') ?? _bool(json, 'HasLoggedToday') ?? false,
      currentWeightKg: _double(json, 'currentWeightKg') ?? _double(json, 'CurrentWeightKg'),
    );
  }
}

/// DailyStarter/start-log response (DailyStarterStartLogResponse.cs).
@immutable
class DailyStarterStartLog {
  const DailyStarterStartLog({
    this.suggestedMealType = 'Breakfast',
    this.suggestedFoods = const [],
  });

  final String suggestedMealType;
  final List<DailyStarterFood> suggestedFoods;

  factory DailyStarterStartLog.fromJson(Map<String, dynamic> json) {
    return DailyStarterStartLog(
      suggestedMealType: _string(json, 'suggestedMealType') ?? _string(json, 'SuggestedMealType') ?? 'Breakfast',
      suggestedFoods: _listFromJson(
        json,
        'suggestedFoods',
        (e) => DailyStarterFood.fromJson(e),
      ),
    );
  }
}

@immutable
class DailyStarterFood {
  const DailyStarterFood({
    required this.id,
    required this.name,
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String name;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? imageUrl;
  final String? description;

  factory DailyStarterFood.fromJson(Map<String, dynamic> json) {
    return DailyStarterFood(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: _firstString(json, const [
            'nameVi',
            'nameVI',
            'nameVN',
            'name_vi',
            'NameVi',
            'NameVI',
            'NameVN',
            'foodNameVi',
            'foodName',
            'name',
            'Name',
            'title',
          ]) ??
          '',
      caloriesKcal: _double(json, 'caloriesKcal') ?? _double(json, 'CaloriesKcal') ?? 0,
      proteinG: _double(json, 'proteinG') ?? _double(json, 'ProteinG') ?? 0,
      carbsG: _double(json, 'carbsG') ?? _double(json, 'CarbsG') ?? 0,
      fatG: _double(json, 'fatG') ?? _double(json, 'FatG') ?? 0,
      imageUrl: _string(json, 'imageUrl') ?? _string(json, 'ImageUrl'),
      description: _string(json, 'description') ?? _string(json, 'Description'),
    );
  }
}

/// DailyStarter/personalization response (DailyStarterPersonalizationResponse.cs).
@immutable
class DailyStarterPersonalization {
  const DailyStarterPersonalization({
    this.heightCm,
    this.weightKg,
    this.targetCalories,
    this.dietaryPreference,
    this.allergenKeys = const [],
    this.allergens = const [],
  });

  final double? heightCm;
  final double? weightKg;
  final double? targetCalories;
  final String? dietaryPreference;
  final List<String> allergenKeys;
  final List<AllergenProfileItem> allergens;

  factory DailyStarterPersonalization.fromJson(Map<String, dynamic> json) {
    return DailyStarterPersonalization(
      heightCm: _double(json, 'heightCm') ?? _double(json, 'HeightCm'),
      weightKg: _double(json, 'weightKg') ?? _double(json, 'WeightKg'),
      targetCalories: _double(json, 'targetCalories') ?? _double(json, 'TargetCalories'),
      dietaryPreference: _string(json, 'dietaryPreference') ?? _string(json, 'DietaryPreference'),
      allergenKeys: _listFromJson(json, 'allergenKeys', (e) => e.toString()),
      allergens: _listFromJson(json, 'allergens', (e) => AllergenProfileItem.fromJson(e)),
    );
  }
}

@immutable
class AllergenProfileItem {
  const AllergenProfileItem({required this.key, required this.name, this.severity});

  final String key;
  final String name;
  final String? severity;

  factory AllergenProfileItem.fromJson(Map<String, dynamic> json) {
    return AllergenProfileItem(
      key: (_string(json, 'key') ?? _string(json, 'Key') ?? '').toString(),
      name: _string(json, 'name') ?? _string(json, 'Name') ?? '',
      severity: _string(json, 'severity') ?? _string(json, 'Severity'),
    );
  }
}

/// Gym/PT goal profile (decoded from UserAiProfileResponse.Preferences JSON).
@immutable
class GymGoalProfile {
  const GymGoalProfile({
    this.goalMode = 'maintain',
    this.weeklyTrainingSchedule = '',
    this.trainingDaysPerWeek,
    this.restDaysPerWeek,
    this.trainingDayTargetCalories,
    this.restDayTargetCalories,
    this.minCalories,
    this.maxCalories,
    this.minProteinG,
    this.maxProteinG,
    this.notes,
  });

  final String goalMode; // cut | bulk | maintain | recomp
  final String weeklyTrainingSchedule; // e.g. "Monday,Wednesday,Friday"
  final int? trainingDaysPerWeek;
  final int? restDaysPerWeek;
  final int? trainingDayTargetCalories;
  final int? restDayTargetCalories;
  final int? minCalories;
  final int? maxCalories;
  final int? minProteinG;
  final int? maxProteinG;
  final String? notes;

  GymGoalProfile copyWith({
    String? goalMode,
    String? weeklyTrainingSchedule,
    int? trainingDaysPerWeek,
    int? restDaysPerWeek,
    int? trainingDayTargetCalories,
    int? restDayTargetCalories,
    int? minCalories,
    int? maxCalories,
    int? minProteinG,
    int? maxProteinG,
    String? notes,
  }) {
    return GymGoalProfile(
      goalMode: goalMode ?? this.goalMode,
      weeklyTrainingSchedule: weeklyTrainingSchedule ?? this.weeklyTrainingSchedule,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      restDaysPerWeek: restDaysPerWeek ?? this.restDaysPerWeek,
      trainingDayTargetCalories: trainingDayTargetCalories ?? this.trainingDayTargetCalories,
      restDayTargetCalories: restDayTargetCalories ?? this.restDayTargetCalories,
      minCalories: minCalories ?? this.minCalories,
      maxCalories: maxCalories ?? this.maxCalories,
      minProteinG: minProteinG ?? this.minProteinG,
      maxProteinG: maxProteinG ?? this.maxProteinG,
      notes: notes ?? this.notes,
    );
  }

  factory GymGoalProfile.fromJson(Map<String, dynamic> json) {
    return GymGoalProfile(
      goalMode: _string(json, 'goalMode') ?? 'maintain',
      weeklyTrainingSchedule: _string(json, 'weeklyTrainingSchedule') ?? '',
      trainingDaysPerWeek: _int(json, 'trainingDaysPerWeek'),
      restDaysPerWeek: _int(json, 'restDaysPerWeek'),
      trainingDayTargetCalories: _int(json, 'trainingDayTargetCalories'),
      restDayTargetCalories: _int(json, 'restDayTargetCalories'),
      minCalories: _int(json, 'minCalories'),
      maxCalories: _int(json, 'maxCalories'),
      minProteinG: _int(json, 'minProteinG'),
      maxProteinG: _int(json, 'maxProteinG'),
      notes: _string(json, 'notes'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalMode': goalMode,
      'weeklyTrainingSchedule': weeklyTrainingSchedule,
      'trainingDaysPerWeek': trainingDaysPerWeek,
      'restDaysPerWeek': restDaysPerWeek,
      'trainingDayTargetCalories': trainingDayTargetCalories,
      'restDayTargetCalories': restDayTargetCalories,
      'minCalories': minCalories,
      'maxCalories': maxCalories,
      'minProteinG': minProteinG,
      'maxProteinG': maxProteinG,
      'notes': notes,
    };
  }
}

@immutable
class GymRecalibrationResult {
  const GymRecalibrationResult({
    required this.currentTargetCalories,
    required this.suggestedTargetCalories,
    required this.reason,
  });

  final int currentTargetCalories;
  final int suggestedTargetCalories;
  final String reason;

  factory GymRecalibrationResult.fromJson(Map<String, dynamic> json) {
    return GymRecalibrationResult(
      currentTargetCalories: _int(json, 'currentTargetCalories') ?? 0,
      suggestedTargetCalories: _int(json, 'suggestedTargetCalories') ?? 0,
      reason: _string(json, 'reason') ?? '',
    );
  }
}

/// Safety disclaimer response.
@immutable
class SafetyDisclaimer {
  const SafetyDisclaimer({
    required this.version,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String version;
  final String title;
  final String content;
  final DateTime? updatedAt;

  factory SafetyDisclaimer.fromJson(Map<String, dynamic> json) {
    return SafetyDisclaimer(
      version: _string(json, 'version') ?? _string(json, 'Version') ?? '1.0',
      title: _string(json, 'title') ?? _string(json, 'Title') ?? '',
      content: _string(json, 'content') ?? _string(json, 'Content') ?? '',
      updatedAt: _parseDate(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }
}

@immutable
class SafetyConsent {
  const SafetyConsent({
    required this.analytics,
    required this.notification,
    required this.marketing,
  });

  final bool analytics;
  final bool notification;
  final bool marketing;

  factory SafetyConsent.fromJson(Map<String, dynamic> json) {
    return SafetyConsent(
      analytics: _bool(json, 'analytics') ?? _bool(json, 'Analytics') ?? true,
      notification: _bool(json, 'notification') ?? _bool(json, 'Notification') ?? true,
      marketing: _bool(json, 'marketing') ?? _bool(json, 'Marketing') ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'Analytics': analytics,
        'Notification': notification,
        'Marketing': marketing,
      };
}

@immutable
class SafetyAlerts {
  const SafetyAlerts({
    required this.riskLevel,
    required this.alerts,
    this.bmi,
    this.allergiesCount = 0,
  });

  final String riskLevel; // low | medium | high
  final List<String> alerts;
  final double? bmi;
  final int allergiesCount;

  factory SafetyAlerts.fromJson(Map<String, dynamic> json) {
    return SafetyAlerts(
      riskLevel: _string(json, 'riskLevel') ?? 'low',
      alerts: _listFromJson(json, 'alerts', (e) => e.toString()),
      bmi: _double(json, 'bmi'),
      allergiesCount: _int(json, 'allergiesCount') ?? 0,
    );
  }
}

/// User AI Profile for LocalPreferences (UserAiProfileResponse.cs).
@immutable
class LocalPreferencesProfile {
  const LocalPreferencesProfile({
    this.preferences,
    this.dislikedFoods,
    this.eatingPattern,
    this.vietnamRegion,
    this.mealContext,
    this.budgetPerMealVnd,
    this.preferredPortionUnits,
    this.allergiesAcknowledged = false,
    this.updatedAt,
  });

  final String? preferences;
  final String? dislikedFoods;
  final String? eatingPattern;
  final String? vietnamRegion; // north | central | south
  final String? mealContext; // eat-out | home-cooked | mixed
  final int? budgetPerMealVnd;
  final String? preferredPortionUnits;
  final bool allergiesAcknowledged;
  final DateTime? updatedAt;

  factory LocalPreferencesProfile.fromJson(Map<String, dynamic> json) {
    return LocalPreferencesProfile(
      preferences: _string(json, 'preferences') ?? _string(json, 'Preferences'),
      dislikedFoods: _string(json, 'dislikedFoods') ?? _string(json, 'DislikedFoods'),
      eatingPattern: _string(json, 'eatingPattern') ?? _string(json, 'EatingPattern'),
      vietnamRegion: _string(json, 'vietnamRegion') ?? _string(json, 'VietnamRegion'),
      mealContext: _string(json, 'mealContext') ?? _string(json, 'MealContext'),
      budgetPerMealVnd: _int(json, 'budgetPerMealVnd') ?? _int(json, 'BudgetPerMealVnd'),
      preferredPortionUnits:
          _string(json, 'preferredPortionUnits') ?? _string(json, 'PreferredPortionUnits'),
      allergiesAcknowledged:
          _bool(json, 'allergiesAcknowledged') ?? _bool(json, 'AllergiesAcknowledged') ?? false,
      updatedAt: _parseDate(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }
}

/// Recommendation item (RecommendationItemResponse.cs).
@immutable
class LocalRecommendationItem {
  const LocalRecommendationItem({
    required this.id,
    required this.name,
    this.type = 'Food',
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.estimatedPriceVnd = 0,
    this.cookingTimeMin = 0,
    this.score = 0,
    this.instructions,
  });

  final String id;
  final String name;
  final String type;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int estimatedPriceVnd;
  final int cookingTimeMin;
  final double score;
  final String? instructions;

  factory LocalRecommendationItem.fromJson(Map<String, dynamic> json) {
    return LocalRecommendationItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: _string(json, 'name') ?? _string(json, 'Name') ?? '',
      type: _string(json, 'type') ?? _string(json, 'Type') ?? 'Food',
      caloriesKcal: _double(json, 'caloriesKcal') ?? _double(json, 'CaloriesKcal') ?? 0,
      proteinG: _double(json, 'proteinG') ?? _double(json, 'ProteinG') ?? 0,
      carbsG: _double(json, 'carbsG') ?? _double(json, 'CarbsG') ?? 0,
      fatG: _double(json, 'fatG') ?? _double(json, 'FatG') ?? 0,
      estimatedPriceVnd:
          _int(json, 'estimatedPriceVnd') ?? _int(json, 'EstimatedPriceVnd') ?? 0,
      cookingTimeMin: _int(json, 'cookingTimeMin') ?? _int(json, 'CookingTimeMin') ?? 0,
      score: _double(json, 'score') ?? _double(json, 'Score') ?? 0,
      instructions: _string(json, 'instructions') ?? _string(json, 'Instructions'),
    );
  }
}

/// Planned vs Actual (2.17, PlannedVsActualResponseDTOs.cs).
@immutable
class PlannedVsActualSummary {
  const PlannedVsActualSummary({
    required this.from,
    required this.to,
    required this.totalPlanned,
    required this.totalActual,
    required this.details,
  });

  final DateTime from;
  final DateTime to;
  final PlannedNutrition totalPlanned;
  final PlannedNutrition totalActual;
  final List<PlannedVsActualDay> details;

  factory PlannedVsActualSummary.fromJson(Map<String, dynamic> json) {
    return PlannedVsActualSummary(
      from: _parseDate(json['from'] ?? json['From']) ?? DateTime.now(),
      to: _parseDate(json['to'] ?? json['To']) ?? DateTime.now(),
      totalPlanned: PlannedNutrition.fromJson(_map(json, 'totalPlanned') ?? {}),
      totalActual: PlannedNutrition.fromJson(_map(json, 'totalActual') ?? {}),
      details: _listFromJson(
        json,
        'details',
        (e) => PlannedVsActualDay.fromJson(e),
      ),
    );
  }
}

@immutable
class PlannedNutrition {
  const PlannedNutrition({
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.costVnd = 0,
  });

  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double costVnd;

  factory PlannedNutrition.fromJson(Map<String, dynamic> json) {
    return PlannedNutrition(
      caloriesKcal: _double(json, 'caloriesKcal') ?? _double(json, 'CaloriesKcal') ?? 0,
      proteinG: _double(json, 'proteinG') ?? _double(json, 'ProteinG') ?? 0,
      carbsG: _double(json, 'carbsG') ?? _double(json, 'CarbsG') ?? 0,
      fatG: _double(json, 'fatG') ?? _double(json, 'FatG') ?? 0,
      costVnd: _double(json, 'costVnd') ?? _double(json, 'CostVnd') ?? 0,
    );
  }
}

@immutable
class PlannedVsActualDay {
  const PlannedVsActualDay({
    required this.date,
    required this.planned,
    required this.actual,
  });

  final DateTime date;
  final PlannedNutrition planned;
  final PlannedNutrition actual;

  factory PlannedVsActualDay.fromJson(Map<String, dynamic> json) {
    return PlannedVsActualDay(
      date: _parseDate(json['date'] ?? json['Date']) ?? DateTime.now(),
      planned: PlannedNutrition.fromJson(_map(json, 'planned') ?? {}),
      actual: PlannedNutrition.fromJson(_map(json, 'actual') ?? {}),
    );
  }
}

@immutable
class AdherenceScore {
  const AdherenceScore({
    required this.overallScore,
    required this.mealCompletionRate,
    required this.calorieDeviationScore,
    required this.macroDeviationScore,
    required this.unplannedPenaltyScore,
    required this.rating,
    required this.feedback,
  });

  final double overallScore;
  final double mealCompletionRate;
  final double calorieDeviationScore;
  final double macroDeviationScore;
  final double unplannedPenaltyScore;
  final String rating; // EXCELLENT | GOOD | FAIR | POOR
  final String feedback;

  factory AdherenceScore.fromJson(Map<String, dynamic> json) {
    return AdherenceScore(
      overallScore: _double(json, 'overallScore') ?? 0,
      mealCompletionRate: _double(json, 'mealCompletionRate') ?? 0,
      calorieDeviationScore: _double(json, 'calorieDeviationScore') ?? 0,
      macroDeviationScore: _double(json, 'macroDeviationScore') ?? 0,
      unplannedPenaltyScore: _double(json, 'unplannedPenaltyScore') ?? 0,
      rating: _string(json, 'rating') ?? '',
      feedback: _string(json, 'feedback') ?? '',
    );
  }
}

@immutable
class DriftAnalysis {
  const DriftAnalysis({
    this.skippedMealsCount = 0,
    this.unplannedIntakeCount = 0,
    this.substitutedItemsCount = 0,
    this.portionMismatchesCount = 0,
    this.skippedMeals = const [],
    this.unplannedIntakes = const [],
    this.substitutedItems = const [],
    this.portionMismatches = const [],
  });

  final int skippedMealsCount;
  final int unplannedIntakeCount;
  final int substitutedItemsCount;
  final int portionMismatchesCount;
  final List<SkippedMeal> skippedMeals;
  final List<UnplannedIntake> unplannedIntakes;
  final List<SubstitutedItem> substitutedItems;
  final List<PortionMismatch> portionMismatches;

  factory DriftAnalysis.fromJson(Map<String, dynamic> json) {
    return DriftAnalysis(
      skippedMealsCount: _int(json, 'skippedMealsCount') ?? 0,
      unplannedIntakeCount: _int(json, 'unplannedIntakeCount') ?? 0,
      substitutedItemsCount: _int(json, 'substitutedItemsCount') ?? 0,
      portionMismatchesCount: _int(json, 'portionMismatchesCount') ?? 0,
      skippedMeals: _listFromJson(json, 'skippedMeals', (e) => SkippedMeal.fromJson(e)),
      unplannedIntakes:
          _listFromJson(json, 'unplannedIntakes', (e) => UnplannedIntake.fromJson(e)),
      substitutedItems:
          _listFromJson(json, 'substitutedItems', (e) => SubstitutedItem.fromJson(e)),
      portionMismatches:
          _listFromJson(json, 'portionMismatches', (e) => PortionMismatch.fromJson(e)),
    );
  }
}

@immutable
class SkippedMeal {
  const SkippedMeal({
    required this.mealPlanItemId,
    required this.itemName,
    required this.mealType,
    required this.targetCalories,
    required this.date,
  });

  final String mealPlanItemId;
  final String itemName;
  final String mealType;
  final int targetCalories;
  final DateTime date;

  factory SkippedMeal.fromJson(Map<String, dynamic> json) {
    return SkippedMeal(
      mealPlanItemId: (json['mealPlanItemId'] ?? json['MealPlanItemId'] ?? '').toString(),
      itemName: _string(json, 'itemName') ?? '',
      mealType: _string(json, 'mealType') ?? '',
      targetCalories: _int(json, 'targetCalories') ?? 0,
      date: _parseDate(json['date'] ?? json['Date']) ?? DateTime.now(),
    );
  }
}

@immutable
class UnplannedIntake {
  const UnplannedIntake({
    required this.mealLogId,
    required this.itemName,
    required this.mealType,
    required this.caloriesKcal,
    required this.loggedAt,
  });

  final String mealLogId;
  final String itemName;
  final String mealType;
  final double caloriesKcal;
  final DateTime loggedAt;

  factory UnplannedIntake.fromJson(Map<String, dynamic> json) {
    return UnplannedIntake(
      mealLogId: (json['mealLogId'] ?? json['MealLogId'] ?? '').toString(),
      itemName: _string(json, 'itemName') ?? '',
      mealType: _string(json, 'mealType') ?? '',
      caloriesKcal: _double(json, 'caloriesKcal') ?? 0,
      loggedAt: _parseDate(json['loggedAt'] ?? json['LoggedAt']) ?? DateTime.now(),
    );
  }
}

@immutable
class SubstitutedItem {
  const SubstitutedItem({
    required this.plannedItemName,
    required this.actualItemName,
    required this.mealType,
    required this.plannedCalories,
    required this.actualCalories,
    required this.date,
  });

  final String plannedItemName;
  final String actualItemName;
  final String mealType;
  final int plannedCalories;
  final double actualCalories;
  final DateTime date;

  factory SubstitutedItem.fromJson(Map<String, dynamic> json) {
    return SubstitutedItem(
      plannedItemName: _string(json, 'plannedItemName') ?? '',
      actualItemName: _string(json, 'actualItemName') ?? '',
      mealType: _string(json, 'mealType') ?? '',
      plannedCalories: _int(json, 'plannedCalories') ?? 0,
      actualCalories: _double(json, 'actualCalories') ?? 0,
      date: _parseDate(json['date'] ?? json['Date']) ?? DateTime.now(),
    );
  }
}

@immutable
class PortionMismatch {
  const PortionMismatch({
    required this.itemName,
    required this.mealType,
    required this.plannedCalories,
    required this.actualCalories,
    required this.percentDeviation,
    required this.date,
  });

  final String itemName;
  final String mealType;
  final int plannedCalories;
  final double actualCalories;
  final double percentDeviation;
  final DateTime date;

  factory PortionMismatch.fromJson(Map<String, dynamic> json) {
    return PortionMismatch(
      itemName: _string(json, 'itemName') ?? '',
      mealType: _string(json, 'mealType') ?? '',
      plannedCalories: _int(json, 'plannedCalories') ?? 0,
      actualCalories: _double(json, 'actualCalories') ?? 0,
      percentDeviation: _double(json, 'percentDeviation') ?? 0,
      date: _parseDate(json['date'] ?? json['Date']) ?? DateTime.now(),
    );
  }
}

@immutable
class PlannedVsActualRecommendations {
  const PlannedVsActualRecommendations({
    this.insights = const [],
    this.actionableSteps = const [],
    this.summaryMessage = '',
  });

  final List<String> insights;
  final List<String> actionableSteps;
  final String summaryMessage;

  factory PlannedVsActualRecommendations.fromJson(Map<String, dynamic> json) {
    return PlannedVsActualRecommendations(
      insights: _listFromJson(json, 'insights', (e) => e.toString()),
      actionableSteps: _listFromJson(json, 'actionableSteps', (e) => e.toString()),
      summaryMessage: _string(json, 'summaryMessage') ?? '',
    );
  }
}

/// Ingredient substitution preference (2.18).
@immutable
class IngredientSubstitutePreference {
  const IngredientSubstitutePreference({
    required this.id,
    this.originalIngredientId,
    this.originalIngredientName = '',
    this.substituteIngredientId,
    this.substituteIngredientName = '',
    this.reason = 'not_available',
    this.maxPriceVnd,
    this.macroMatch = false,
  });

  final String id;
  final String? originalIngredientId;
  final String originalIngredientName;
  final String? substituteIngredientId;
  final String substituteIngredientName;
  final String reason; // allergy | not_available | expensive
  final int? maxPriceVnd;
  final bool macroMatch;

  factory IngredientSubstitutePreference.fromJson(Map<String, dynamic> json) {
    return IngredientSubstitutePreference(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      originalIngredientId:
          (json['originalIngredientId'] ?? json['OriginalIngredientId'])?.toString(),
      originalIngredientName:
          _string(json, 'originalIngredientName') ?? _string(json, 'OriginalIngredientName') ?? '',
      substituteIngredientId:
          (json['substituteIngredientId'] ?? json['SubstituteIngredientId'])?.toString(),
      substituteIngredientName:
          _string(json, 'substituteIngredientName') ??
              _string(json, 'SubstituteIngredientName') ??
              '',
      reason: _string(json, 'reason') ?? _string(json, 'Reason') ?? 'not_available',
      maxPriceVnd: _int(json, 'maxPriceVnd') ?? _int(json, 'MaxPriceVnd'),
      macroMatch: _bool(json, 'macroMatch') ?? _bool(json, 'MacroMatch') ?? false,
    );
  }
}

// -- helpers ----------------------------------------------------------------

String? _string(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v == null ? null : v.toString();
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _string(json, key)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

double? _double(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _int(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool? _bool(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}

Map<String, dynamic>? _map(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is Map<String, dynamic>) return v;
  return null;
}

List<T> _listFromJson<T>(
  Map<String, dynamic> json,
  String key,
  T Function(dynamic) parse,
) {
  final raw = json[key];
  if (raw is List) {
    return raw.map(parse).toList();
  }
  return <T>[];
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}
