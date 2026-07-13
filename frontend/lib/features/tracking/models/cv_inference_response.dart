import 'cv_ingredient_item.dart';
import 'cv_suggested_dish.dart';

class CvInferenceResponse {
  CvInferenceResponse({
    required this.jobId,
    required this.requestId,
    required this.apiVersion,
    required this.status,
    this.processingTimeMs,
    this.luongTinCayChung,
    this.nguyenLieuThoQuetDuoc,
    this.danhSachMonAnGoiY,
  });

  final String jobId;
  final String requestId;
  final String apiVersion;
  final String status;
  final double? processingTimeMs;
  final String? luongTinCayChung;
  final List<CvIngredientItem>? nguyenLieuThoQuetDuoc;
  final List<CvSuggestedDish>? danhSachMonAnGoiY;

  factory CvInferenceResponse.fromJson(Map<String, dynamic> json) {
    final rawRawIngredients = json['nguyen_lieu_tho_quet_duoc'] ?? json['nguyenLieuThoQuetDuoc'];
    final rawDishes = json['danh_sach_mon_an_goi_y'] ?? json['danhSachMonAnGoiY'];
    return CvInferenceResponse(
      jobId: (json['job_id'] ?? json['jobId'] ?? '').toString(),
      requestId: (json['request_id'] ?? json['requestId'] ?? '').toString(),
      apiVersion: (json['api_version'] ?? json['apiVersion'] ?? 'v1').toString(),
      status: (json['status'] ?? '').toString(),
      processingTimeMs: _number(json['processing_time_ms'] ?? json['processingTimeMs']),
      luongTinCayChung: (json['luong_tin_cay_chung'] ?? json['luongTinCayChung'])?.toString(),
      nguyenLieuThoQuetDuoc: rawRawIngredients is List
          ? rawRawIngredients
              .whereType<Map<String, dynamic>>()
              .map(CvIngredientItem.fromJson)
              .toList()
          : null,
      danhSachMonAnGoiY: rawDishes is List
          ? rawDishes
              .whereType<Map<String, dynamic>>()
              .map(CvSuggestedDish.fromJson)
              .toList()
          : null,
    );
  }
}

double? _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value');
