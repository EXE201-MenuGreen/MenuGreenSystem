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
      tongCalories: _number(json['tong_calories'] ?? json['tongCalories']),
      proteinG: _number(json['protein_g'] ?? json['proteinG']),
      carbsG: _number(json['carbs_g'] ?? json['carbsG']),
      fatG: _number(json['fat_g'] ?? json['fatG']),
      fiberG: _number(json['fiber_g'] ?? json['fiberG']),
    );
  }
}

double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
