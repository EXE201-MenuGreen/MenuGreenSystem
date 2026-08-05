import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_chat/models/coach_chat_models.dart';
import 'package:frontend/features/coach_chat/providers/coach_chat_provider.dart';
import 'package:frontend/features/coach_chat/repositories/coach_chat_repository.dart';
import 'package:frontend/features/coach_chat/services/coach_chat_realtime_service.dart';
import 'package:frontend/features/coach_chat/views/coach_chat_partners_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('a single connected PT opens directly', (tester) async {
    final provider = CoachChatProvider(
      repository: _FakeCoachChatRepository(),
      realtime: _FakeCoachChatRealtimeService(),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<CoachChatProvider>.value(
        value: provider,
        child: const MaterialApp(home: CoachChatPartnersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PT Minh'), findsOneWidget);
    expect(find.text('Tin nhắn riêng tư'), findsOneWidget);
    expect(find.text('Tin nhắn PT – Gymer'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeCoachChatRepository extends CoachChatRepository {
  @override
  Future<List<CoachChatPartner>> getPartners() async => const [
    CoachChatPartner(partnerId: 'coach-1', fullName: 'PT Minh', unreadCount: 0),
  ];

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<List<CoachChatMessage>> getMessages(
    String partnerId, {
    DateTime? before,
    int take = 50,
  }) async => const [];

  @override
  Future<void> markRead(String partnerId) async {}
}

class _FakeCoachChatRealtimeService extends CoachChatRealtimeService {
  @override
  Stream<CoachChatMessage> get messages => const Stream.empty();

  @override
  Stream<int> get unreadCounts => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> dispose() async {}
}
