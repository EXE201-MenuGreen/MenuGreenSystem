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
      idNguyenLieu: (json['id_nguyen_lieu'] ?? json['idNguyenLieu'] ?? '').toString(),
      tenNguyenLieu: (json['ten_nguyen_lieu'] ?? json['tenNguyenLieu'] ?? '').toString(),
      tenNguyenLieuKyThuat:
          (json['ten_nguyen_lieu_ky_thuat'] ?? json['tenNguyenLieuKyThuat'] ?? '').toString(),
      khoiLuongUocTinhG: _number(json['khoi_luong_uoc_tinh_g'] ?? json['khoiLuongUocTinhG']),
      doChinhXacUocTinh: (json['do_chinh_xac_uoc_tinh'] ?? json['doChinhXacUocTinh'] ?? '').toString(),
    );
  }
}

double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
