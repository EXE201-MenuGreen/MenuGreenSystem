class WeightLogItem {
  WeightLogItem({
    required this.id,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.recordedAt,
  });

  final String id;
  final double weightKg;
  final double? bodyFatPercent;
  final DateTime? recordedAt;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  factory WeightLogItem.fromJson(Map<String, dynamic> json) {
    final recordedAtRaw = json['recordedAt']?.toString();
    return WeightLogItem(
      id: (json['id'] ?? '').toString(),
      weightKg: _asDouble(json['weightKg']),
      bodyFatPercent: _asNullableDouble(json['bodyFatPercent']),
      recordedAt:
          recordedAtRaw == null ? null : DateTime.tryParse(recordedAtRaw)?.toLocal(),
    );
  }
}
