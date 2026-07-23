import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/micro_learning_models.dart';

class MicroLearningRepository {
  MicroLearningRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<MicroLearningCard>> getRecommended() =>
      _cards(_api.get(ApiEndpoints.microLearningRecommended));

  Future<List<MicroLearningCard>> getLibrary({String? category}) {
    final query = category == null || category.trim().isEmpty
        ? ''
        : '?category=${Uri.encodeQueryComponent(category.trim())}';
    return _cards(_api.get('${ApiEndpoints.microLearningLibrary}$query'));
  }

  Future<List<MicroLearningCard>> getSaved() =>
      _cards(_api.get(ApiEndpoints.microLearningSavedCards));

  Future<MicroLearningCard> getById(String id) async {
    final response = await _api.get(ApiEndpoints.microLearningCardById(id));
    final data = _object(response);
    return MicroLearningCard.fromJson(data);
  }

  Future<List<MicroLearningCategory>> getCategories() async {
    final response = await _api.get(ApiEndpoints.microLearningCategories);
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_message(response));
    }
    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (item) =>
              MicroLearningCategory.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> recordAction(String id, String action) async {
    final response = await _api.postJson(
      ApiEndpoints.microLearningCardAction(id),
      {'action': action},
    );
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  Future<QuizSubmitResult> submitQuiz(
    String id,
    int selectedOptionIndex,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.microLearningSubmitQuiz(id),
      {'selectedOptionIndex': selectedOptionIndex},
    );
    return QuizSubmitResult.fromJson(_object(response));
  }

  Future<List<MicroLearningCard>> _cards(Future<dynamic> request) async {
    final response = await request;
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_message(response));
    }
    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => MicroLearningCard.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _object(dynamic response) {
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        response.body.isEmpty) {
      throw Exception(_message(response));
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Phản hồi không hợp lệ.');
    }
    return data;
  }

  String _message(dynamic response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        return (data['message'] ??
                data['Message'] ??
                'Không thể thực hiện thao tác.')
            .toString();
      }
    } catch (_) {}
    return 'Không thể thực hiện thao tác.';
  }
}
