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
    final rawRawIngredients = json['nguyenLieuThoQuetDuoc'];
    final rawDishes = json['danhSachMonAnGoiY'];
    return CvInferenceResponse(
      jobId: (json['jobId'] ?? '').toString(),
      requestId: (json['requestId'] ?? '').toString(),
      apiVersion: (json['apiVersion'] ?? 'v1').toString(),
      status: (json['status'] ?? '').toString(),
      processingTimeMs: (json['processingTimeMs'] as num?)?.toDouble(),
      luongTinCayChung: json['luongTinCayChung']?.toString(),
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
