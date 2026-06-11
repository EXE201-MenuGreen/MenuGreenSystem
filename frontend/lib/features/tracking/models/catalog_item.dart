class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CatalogItem.fromJson(
    Map<String, dynamic> json, {
    required String fallbackNameKey,
  }) {
    final name = (json[fallbackNameKey] ??
            json['nameVi'] ??
            json['title'] ??
            json['name'] ??
            '')
        .toString();
    return CatalogItem(
      id: (json['id'] ?? '').toString(),
      name: name.isEmpty ? 'Không tên' : name,
    );
  }
}
