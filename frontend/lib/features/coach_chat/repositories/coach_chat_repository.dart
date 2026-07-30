import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/coach_chat_models.dart';

class CoachChatRepository {
  CoachChatRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<CoachChatPartner>> getPartners() async {
    final uri = Uri.parse(
      ApiEndpoints.coachChatPartners,
    ).replace(queryParameters: const {'scope': 'gymer'});
    final response = await _api.get(uri.toString());
    final decoded = _decodeSuccess(response.statusCode, response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => CoachChatPartner.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<CoachChatMessage>> getMessages(
    String partnerId, {
    DateTime? before,
    int take = 50,
  }) async {
    final uri = Uri.parse(ApiEndpoints.coachChatMessages(partnerId)).replace(
      queryParameters: {
        'take': '$take',
        if (before != null) 'before': before.toUtc().toIso8601String(),
      },
    );
    final response = await _api.get(uri.toString());
    final decoded = _decodeSuccess(response.statusCode, response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => CoachChatMessage.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<CoachChatMessage> sendMessage(String partnerId, String content) async {
    final response = await _api.postJson(
      ApiEndpoints.coachChatMessages(partnerId),
      {'content': content},
    );
    final decoded = _decodeSuccess(response.statusCode, response.body);
    if (decoded is! Map) throw Exception('Dữ liệu tin nhắn không hợp lệ.');
    return CoachChatMessage.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> markRead(String partnerId) async {
    final response = await _api.postJson(
      ApiEndpoints.coachChatRead(partnerId),
      const {},
    );
    _decodeSuccess(response.statusCode, response.body);
  }

  Future<int> getUnreadCount() async {
    final uri = Uri.parse(
      ApiEndpoints.coachChatUnreadCount,
    ).replace(queryParameters: const {'scope': 'gymer'});
    final response = await _api.get(uri.toString());
    final decoded = _decodeSuccess(response.statusCode, response.body);
    if (decoded is! Map) return 0;
    final value = decoded['count'] ?? decoded['Count'];
    return value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  dynamic _decodeSuccess(int statusCode, String body) {
    dynamic decoded;
    if (body.trim().isNotEmpty) decoded = jsonDecode(body);
    if (statusCode >= 200 && statusCode < 300) return decoded;
    final message = decoded is Map
        ? (decoded['message'] ?? decoded['Message'])?.toString()
        : null;
    throw Exception(message ?? 'Không thể kết nối cuộc trò chuyện.');
  }
}
