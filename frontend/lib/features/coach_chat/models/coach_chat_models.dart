class CoachChatMessage {
  const CoachChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isMine,
    this.readAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isMine;

  factory CoachChatMessage.fromJson(Map<String, dynamic> json) {
    return CoachChatMessage(
      id: _text(json, 'id'),
      senderId: _text(json, 'senderId'),
      receiverId: _text(json, 'receiverId'),
      content: _text(json, 'content'),
      sentAt:
          DateTime.tryParse(_text(json, 'sentAt'))?.toLocal() ?? DateTime.now(),
      readAt: DateTime.tryParse(_text(json, 'readAt'))?.toLocal(),
      isMine: _value(json, 'isMine') == true,
    );
  }
}

class CoachChatPartner {
  const CoachChatPartner({
    required this.partnerId,
    required this.fullName,
    required this.unreadCount,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String partnerId;
  final String fullName;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory CoachChatPartner.fromJson(Map<String, dynamic> json) {
    final unread = _value(json, 'unreadCount');
    return CoachChatPartner(
      partnerId: _text(json, 'partnerId'),
      fullName: _text(json, 'fullName').isEmpty
          ? 'PT / Gymer'
          : _text(json, 'fullName'),
      avatarUrl: _nullableText(json, 'avatarUrl'),
      lastMessage: _nullableText(json, 'lastMessage'),
      lastMessageAt: DateTime.tryParse(_text(json, 'lastMessageAt'))?.toLocal(),
      unreadCount: unread is num
          ? unread.round()
          : int.tryParse(unread?.toString() ?? '') ?? 0,
    );
  }
}

dynamic _value(Map<String, dynamic> json, String key) {
  final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
  return json[key] ?? json[pascal];
}

String _text(Map<String, dynamic> json, String key) =>
    _value(json, key)?.toString() ?? '';

String? _nullableText(Map<String, dynamic> json, String key) {
  final value = _text(json, key).trim();
  return value.isEmpty ? null : value;
}
