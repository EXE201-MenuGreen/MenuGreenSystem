class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String id;
  final String name;
  final double? caloriesKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  factory CatalogItem.fromJson(
    Map<String, dynamic> json, {
    required String fallbackNameKey,
  }) {
    final name =
        (json[fallbackNameKey] ??
                json['nameVi'] ??
                json['title'] ??
                json['name'] ??
                '')
            .toString();
    return CatalogItem(
      id: (json['id'] ?? '').toString(),
      name: name.isEmpty ? 'Không tên' : name,
      caloriesKcal: _optionalNumber(
        json['caloriesKcal'] ?? json['CaloriesKcal'],
      ),
      proteinG: _optionalNumber(json['proteinG'] ?? json['ProteinG']),
      carbsG: _optionalNumber(json['carbsG'] ?? json['CarbsG']),
      fatG: _optionalNumber(json['fatG'] ?? json['FatG']),
    );
  }

  static double? _optionalNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
