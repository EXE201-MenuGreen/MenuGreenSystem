class CvNutritionInfo {
  CvNutritionInfo({
    required this.tongCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  final double tongCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  factory CvNutritionInfo.fromJson(Map<String, dynamic> json) {
    return CvNutritionInfo(
      tongCalories: (json['tongCalories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiberG'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
