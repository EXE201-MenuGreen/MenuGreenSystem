class CvRecipeIngredient {
  CvRecipeIngredient({
    required this.ten,
    required this.tenKyThuat,
    required this.khoiLuongG,
  });

  final String ten;
  final String tenKyThuat;
  final double khoiLuongG;

  factory CvRecipeIngredient.fromJson(Map<String, dynamic> json) {
    return CvRecipeIngredient(
      ten: (json['ten'] ?? '').toString(),
      tenKyThuat: (json['tenKyThuat'] ?? '').toString(),
      khoiLuongG: (json['khoiLuongG'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
