import 'package:flutter/foundation.dart';

/// Lightweight model for the user's most-recent [WeightLog]. Returned by
/// [NutritionTrackingRepository.getLatestWeightLog] so the weight log
/// sheet can pre-fill its form fields with the value the user just
/// entered.
@immutable
class LatestWeightLog {
  const LatestWeightLog({
    required this.id,
    required this.weightKg,
    this.bodyFatPercent,
    this.recordedAt,
  });

  final String id;
  final double weightKg;
  final double? bodyFatPercent;
  final DateTime? recordedAt;

  factory LatestWeightLog.fromJson(Map<String, dynamic> json) {
    return LatestWeightLog(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      weightKg:
          _toDouble(json['weightKg']) ?? _toDouble(json['WeightKg']) ?? 0,
      bodyFatPercent:
          _toDouble(json['bodyFatPercent']) ?? _toDouble(json['BodyFatPercent']),
      recordedAt: _toDate(json['recordedAt'] ?? json['RecordedAt']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}