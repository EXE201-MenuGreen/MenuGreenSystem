import 'dart:convert';

import '../../../../core/i18n/api_message_translator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ai_assistant_models.dart';

class AiAssistantRepository {
  AiAssistantRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<AiConversation>> getConversations() async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations',
    );
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AiConversation.fromJson)
        .toList();
  }

  Future<AiConversation> createConversation(String? firstMessage) async {
    final body = <String, dynamic>{};
    if (firstMessage != null && firstMessage.isNotEmpty) {
      body['firstMessage'] = firstMessage;
    }
    final response = await _api.postJson(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations',
      body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return AiConversation.fromJson(decoded);
  }

  Future<AiConversation> getConversationById(String conversationId) async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId',
    );
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return AiConversation.fromJson(decoded);
  }

  Future<void> deleteConversation(String conversationId) async {
    final response = await _api.delete(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId',
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  Future<AiConversation> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    final body = <String, dynamic>{'title': title};
    final response = await _api.postJson(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId/title',
      body,
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return AiConversation.fromJson(decoded);
  }

  Future<List<AiMessage>> getMessages(String conversationId) async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId/messages',
    );
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AiMessage.fromJson)
        .toList();
  }

  Future<AiMessage> sendMessage(
    String conversationId,
    String message, {
    bool stream = false,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'language': 'vi',
      'stream': stream,
    };
    final response = await _api.postJson(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId/messages',
      body,
      // The server waits up to 15 seconds for ONNX/worker fallback.  Keep the
      // mobile timeout higher so it receives that response instead of treating
      // a still-running request as failed.
      timeout: const Duration(seconds: 22),
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return AiMessage.fromJson(decoded);
  }

  Future<AiMessage> regenerateMessage(
    String conversationId,
    String messageId,
  ) async {
    final response = await _api.postJson(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId/messages/$messageId/regenerate',
      <String, dynamic>{},
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return AiMessage.fromJson(decoded);
  }

  Future<void> sendFeedback(
    String conversationId,
    String messageId, {
    required bool isPositive,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'isPositive': isPositive,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };
    final response = await _api.patchJson(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId/messages/$messageId/feedback',
      body,
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  Future<AiAssistantContext> getContext() async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/context',
    );
    if (response.statusCode != 200 || response.body.isEmpty) {
      return const AiAssistantContext();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const AiAssistantContext();
    return AiAssistantContext.fromJson(decoded);
  }

  Future<AiAssistantProfile> getProfile() async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/profile',
    );
    if (response.statusCode != 200 || response.body.isEmpty) {
      return const AiAssistantProfile();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const AiAssistantProfile();
    }
    return AiAssistantProfile.fromJson(decoded);
  }

  Future<AiAssistantProfile> updateProfile(AiAssistantProfile profile) async {
    final body = <String, dynamic>{
      if (profile.preferences != null) 'preferences': profile.preferences,
      if (profile.dislikedFoods != null) 'dislikedFoods': profile.dislikedFoods,
      if (profile.eatingPattern != null) 'eatingPattern': profile.eatingPattern,
    };
    final response = await _api.putJson(
      '${ApiEndpoints.baseUrl}/AiAssistant/profile',
      body,
    );
    if (response.statusCode != 200 || response.body.isEmpty) {
      return profile;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return profile;
    return AiAssistantProfile.fromJson(decoded);
  }

  Future<List<SuggestionItem>> getSuggestions() async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/suggestions',
    );
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<dynamic>()
        .map((e) => SuggestionItem.fromJson(e))
        .toList();
  }

  Future<String> summarizeConversation(String conversationId) async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/AiAssistant/conversations/$conversationId/summary',
    );
    if (response.statusCode != 200 || response.body.isEmpty) {
      return '';
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['summary'] ?? decoded['Summary'])?.toString() ?? '';
    }
    return '';
  }

  String _messageFromResponse(dynamic response) {
    try {
      final decoded = jsonDecode(response.body as String);
      if (decoded is Map && decoded['message'] != null) {
        return ApiMessageTranslator.translate(decoded['message'].toString());
      }
      if (decoded is Map && decoded['Message'] != null) {
        return ApiMessageTranslator.translate(decoded['Message'].toString());
      }
    } catch (_) {}
    return 'Không thực hiện được thao tác trợ lý AI.';
  }
}
