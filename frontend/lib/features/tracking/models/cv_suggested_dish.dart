import 'cv_nutrition_info.dart';
import 'cv_recipe_ingredient.dart';

class CvSuggestedDish {
  CvSuggestedDish({
    required this.idMonAnGoiY,
    required this.tenMonAn,
    this.tenMonAnKyThuat,
    required this.moTaNgan,
    required this.doKhaThi,
    required this.confidence,
    required this.nguyenLieuSuDung,
    required this.thongTinDinhDuongMonAn,
    required this.isSafeForUser,
    required this.matchedAllergens,
  });

  final String idMonAnGoiY;
  final String tenMonAn;
  final String? tenMonAnKyThuat;
  final String moTaNgan;
  final String doKhaThi;
  final double confidence;
  final List<CvRecipeIngredient> nguyenLieuSuDung;
  final CvNutritionInfo thongTinDinhDuongMonAn;
  final bool isSafeForUser;
  final List<String> matchedAllergens;

  factory CvSuggestedDish.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['nguyenLieuSuDung'];
    final rawNutri = json['thongTinDinhDuongMonAn'];
    final rawAllergens = json['matchedAllergens'];
    return CvSuggestedDish(
      idMonAnGoiY: (json['idMonAnGoiY'] ?? '').toString(),
      tenMonAn: (json['tenMonAn'] ?? '').toString(),
      tenMonAnKyThuat: json['tenMonAnKyThuat']?.toString(),
      moTaNgan: (json['moTaNgan'] ?? '').toString(),
      doKhaThi: (json['doKhaThi'] ?? '').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      nguyenLieuSuDung: rawIngredients is List
          ? rawIngredients
              .whereType<Map<String, dynamic>>()
              .map(CvRecipeIngredient.fromJson)
              .toList()
          : [],
      thongTinDinhDuongMonAn: rawNutri is Map<String, dynamic>
          ? CvNutritionInfo.fromJson(rawNutri)
          : CvNutritionInfo(tongCalories: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0),
      isSafeForUser: json['isSafeForUser'] == true,
      matchedAllergens: rawAllergens is List
          ? rawAllergens.map((e) => e.toString()).toList()
          : [],
    );
  }
}
