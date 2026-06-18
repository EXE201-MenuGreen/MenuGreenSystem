class AiConversation {
  final String id;
  final String userId;
  final String? title;
  final DateTime createdAt;

  const AiConversation({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class AiMessage {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final int? tokensUsed;
  final DateTime createdAt;
  final String? feedback;

  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.tokensUsed,
    required this.createdAt,
    this.feedback,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      tokensUsed: (json['tokensUsed'] as num?)?.toInt(),
      createdAt: _parseDateTime(json['createdAt']),
      feedback: json['feedback'] as String?,
    );
  }
}

class AiAssistantProfile {
  final String? preferences;
  final String? dislikedFoods;
  final String? eatingPattern;

  const AiAssistantProfile({
    this.preferences,
    this.dislikedFoods,
    this.eatingPattern,
  });

  factory AiAssistantProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiAssistantProfile();
    return AiAssistantProfile(
      preferences: json['preferences'] as String?,
      dislikedFoods: json['dislikedFoods'] as String?,
      eatingPattern: json['eatingPattern'] as String?,
    );
  }
}

class AiAssistantContext {
  final AiAssistantProfile? profile;
  final Map<String, dynamic>? healthProfile;
  final List<String> allergies;
  final Map<String, dynamic>? recentNutrition;

  const AiAssistantContext({
    this.profile,
    this.healthProfile,
    this.allergies = const [],
    this.recentNutrition,
  });

  factory AiAssistantContext.fromJson(Map<String, dynamic> json) {
    return AiAssistantContext(
      profile: AiAssistantProfile.fromJson(json['profile'] as Map<String, dynamic>?),
      healthProfile: json['healthProfile'] as Map<String, dynamic>?,
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recentNutrition: json['recentNutrition'] as Map<String, dynamic>?,
    );
  }
}

class SuggestionItem {
  final String text;

  const SuggestionItem({required this.text});

  factory SuggestionItem.fromJson(dynamic json) {
    return SuggestionItem(text: json.toString());
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  final text = value.toString();
  return DateTime.tryParse(text) ?? DateTime.now();
}
