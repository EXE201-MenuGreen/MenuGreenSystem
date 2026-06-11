class CvIngredientItem {
  CvIngredientItem({
    required this.idNguyenLieu,
    required this.tenNguyenLieu,
    required this.tenNguyenLieuKyThuat,
    required this.khoiLuongUocTinhG,
    required this.doChinhXacUocTinh,
  });

  final String idNguyenLieu;
  final String tenNguyenLieu;
  final String tenNguyenLieuKyThuat;
  final double khoiLuongUocTinhG;
  final String doChinhXacUocTinh;

  factory CvIngredientItem.fromJson(Map<String, dynamic> json) {
    return CvIngredientItem(
      idNguyenLieu: (json['idNguyenLieu'] ?? '').toString(),
      tenNguyenLieu: (json['tenNguyenLieu'] ?? '').toString(),
      tenNguyenLieuKyThuat: (json['tenNguyenLieuKyThuat'] ?? '').toString(),
      khoiLuongUocTinhG: (json['khoiLuongUocTinhG'] as num?)?.toDouble() ?? 0.0,
      doChinhXacUocTinh: (json['doChinhXacUocTinh'] ?? '').toString(),
    );
  }
}
