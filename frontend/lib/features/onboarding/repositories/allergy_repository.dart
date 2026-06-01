import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class AllergyItem {
  final String id;
  final String name;
  final bool isActive;

  const AllergyItem({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory AllergyItem.fromJson(Map<String, dynamic> json) {
    return AllergyItem(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      name: (json['name'] ?? json['Name'])?.toString() ?? '',
      isActive: (json['isActive'] ?? json['IsActive']) == true,
    );
  }
}

class AllergyRepository {
  AllergyRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<AllergyItem>> getAll() async {
    final response = await _api.get(ApiEndpoints.allergies);
    if (response.statusCode != 200 || response.body.isEmpty) return [];

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AllergyItem.fromJson)
        .toList();
  }

  Future<bool> create(String name) async {
    final response = await _api.postJson(ApiEndpoints.allergies, {
      'name': name,
      'isActive': true,
    });
    return response.statusCode == 200;
  }

  Future<bool> delete(String allergyId) async {
    final response = await _api.delete(ApiEndpoints.allergyById(allergyId));
    return response.statusCode == 200;
  }
}
