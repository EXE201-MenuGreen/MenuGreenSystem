import 'package:flutter/foundation.dart';

import '../models/ai_assistant_models.dart';
import '../repositories/ai_assistant_repository.dart';

class AiAssistantProvider extends ChangeNotifier {
  AiAssistantProvider({AiAssistantRepository? repository})
    : _repository = repository ?? AiAssistantRepository();

  final AiAssistantRepository _repository;

  List<AiConversation> _conversations = [];
  List<AiMessage> _messages = [];
  AiAssistantProfile? _profile;
  List<SuggestionItem> _suggestions = [];
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _error;

  List<AiConversation> get conversations => _conversations;
  List<AiMessage> get messages => _messages;
  AiAssistantProfile? get profile => _profile;
  List<SuggestionItem> get suggestions => _suggestions;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get error => _error;

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _repository.getConversations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<AiConversation?> createConversation(String? firstMessage) async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();
    try {
      final conversation = await _repository.createConversation(firstMessage);
      _conversations = [conversation, ..._conversations];
      _messages = [];
      _error = null;
      return conversation;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _isLoadingMessages = true;
    _error = null;
    _messages = [];
    notifyListeners();
    try {
      _messages = await _repository.getMessages(conversationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<AiMessage?> sendMessage(String conversationId, String message) async {
    // Both the keyboard submit action and the send button can fire almost at
    // the same time. Only allow one in-flight send for this provider.
    if (_isSending) return null;

    _isSending = true;
    _error = null;

    // Add user's message locally first to make UI responsive
    final userMessage = AiMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    _messages = [..._messages, userMessage];
    notifyListeners();

    try {
      final aiMessage = await _repository.sendMessage(conversationId, message);
      // The API persists the user message, while the local copy keeps the UI
      // responsive until the assistant response arrives.
      _messages = [..._messages, aiMessage];
      _error = null;
      return aiMessage;
    } catch (e) {
      // Do not leave an unsaved optimistic message in memory. Otherwise a
      // manual retry can visually look like (or become) a duplicate message.
      _messages = _messages.where((item) => item.id != userMessage.id).toList();
      _error = e.toString();
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> regenerateMessage(
    String conversationId,
    String messageId,
  ) async {
    _isLoadingMessages = true;
    notifyListeners();
    try {
      final updated = await _repository.regenerateMessage(
        conversationId,
        messageId,
      );
      _messages = _messages
          .map((m) => m.id == updated.id ? updated : m)
          .toList(growable: false);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendFeedback(
    String conversationId,
    String messageId, {
    required bool isPositive,
    String? comment,
  }) async {
    try {
      await _repository.sendFeedback(
        conversationId,
        messageId,
        isPositive: isPositive,
        comment: comment,
      );
      _messages = _messages
          .map(
            (m) => m.id == messageId
                ? m
                : m.copyWith(feedback: isPositive ? 'positive' : 'negative'),
          )
          .toList(growable: false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      _profile = await _repository.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateProfile(AiAssistantProfile profile) async {
    try {
      _profile = await _repository.updateProfile(profile);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadSuggestions() async {
    try {
      _suggestions = await _repository.getSuggestions();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshConversations() => loadConversations();

  Future<void> deleteConversation(String conversationId) async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.deleteConversation(conversationId);
      _conversations = _conversations
          .where((c) => c.id != conversationId)
          .toList();
      if (_messages.isNotEmpty &&
          _messages.first.conversationId == conversationId) {
        _messages = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

extension _AiMessageCopyWith on AiMessage {
  AiMessage copyWith({
    String? id,
    String? conversationId,
    String? role,
    String? content,
    int? tokensUsed,
    DateTime? createdAt,
    String? feedback,
  }) {
    return AiMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      createdAt: createdAt ?? this.createdAt,
      feedback: feedback ?? this.feedback,
    );
  }
}
