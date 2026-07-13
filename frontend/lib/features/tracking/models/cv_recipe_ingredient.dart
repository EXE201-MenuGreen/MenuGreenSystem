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
      tenKyThuat: (json['ten_ky_thuat'] ?? json['tenKyThuat'] ?? '').toString(),
      khoiLuongG: _number(json['khoi_luong_g'] ?? json['khoiLuongG']),
    );
  }
}

double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
