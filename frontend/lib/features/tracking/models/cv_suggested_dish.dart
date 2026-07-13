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
    final rawIngredients = json['nguyen_lieu_su_dung'] ?? json['nguyenLieuSuDung'];
    final rawNutri = json['thong_tin_dinh_duong_mon_an'] ?? json['thongTinDinhDuongMonAn'];
    final rawAllergens = json['matched_allergens'] ?? json['matchedAllergens'];
    return CvSuggestedDish(
      idMonAnGoiY: (json['id_mon_an_goi_y'] ?? json['idMonAnGoiY'] ?? '').toString(),
      tenMonAn: (json['ten_mon_an'] ?? json['tenMonAn'] ?? '').toString(),
      tenMonAnKyThuat: (json['ten_mon_an_ky_thuat'] ?? json['tenMonAnKyThuat'])?.toString(),
      moTaNgan: (json['mo_ta_ngan'] ?? json['moTaNgan'] ?? '').toString(),
      doKhaThi: (json['do_kha_thi'] ?? json['doKhaThi'] ?? '').toString(),
      confidence: _number(json['confidence']),
      nguyenLieuSuDung: rawIngredients is List
          ? rawIngredients
              .whereType<Map<String, dynamic>>()
              .map(CvRecipeIngredient.fromJson)
              .toList()
          : [],
      thongTinDinhDuongMonAn: rawNutri is Map<String, dynamic>
          ? CvNutritionInfo.fromJson(rawNutri)
          : CvNutritionInfo(tongCalories: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0),
      isSafeForUser: json['is_safe_for_user'] == true || json['isSafeForUser'] == true,
      matchedAllergens: rawAllergens is List
          ? rawAllergens.map((e) => e.toString()).toList()
          : [],
    );
  }
}

double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
