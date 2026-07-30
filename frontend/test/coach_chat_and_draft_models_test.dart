import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_chat/models/coach_chat_models.dart';
import 'package:frontend/features/coach_pt/models/coach_meal_plan_models.dart';
import 'package:frontend/features/coach_pt/repositories/coach_meal_plan_repository.dart';

void main() {
  test('chat models parse SignalR/API PascalCase payloads', () {
    final message = CoachChatMessage.fromJson({
      'Id': 'message-1',
      'SenderId': 'coach-1',
      'ReceiverId': 'gymer-1',
      'Content': 'Chào bạn',
      'SentAt': '2026-07-29T10:00:00Z',
      'IsMine': false,
    });
    final partner = CoachChatPartner.fromJson({
      'PartnerId': 'coach-1',
      'FullName': 'PT Minh',
      'UnreadCount': 3,
    });

    expect(message.content, 'Chào bạn');
    expect(message.isMine, isFalse);
    expect(partner.fullName, 'PT Minh');
    expect(partner.unreadCount, 3);
  });

  test('draft payload persists PT calorie bounds and notes', () {
    final payload = ClientMealPlanPayload(
      title: 'Lộ trình tuần',
      planType: 'WEEKLY',
      targetCalories: 1800,
      minCalories: 350,
      maxCalories: 650,
      coachNotes: 'Ưu tiên món Việt',
    ).toJson();

    expect(payload['targetCalories'], 1800);
    expect(payload['minCalories'], 350);
    expect(payload['maxCalories'], 650);
    expect(payload['coachNotes'], 'Ưu tiên món Việt');
  });

  test('meal-plan response restores saved PT configuration', () {
    final detail = CoachMealPlanDetail.fromJson({
      'Id': 'plan-1',
      'Title': 'Lộ trình tuần',
      'PlanType': 'WEEKLY',
      'IsActive': true,
      'TargetCalories': 1800,
      'MinCalories': 350,
      'MaxCalories': 650,
      'CoachNotes': 'Ưu tiên món Việt',
      'Items': <Object>[],
    });

    expect(detail.header.minCalories, 350);
    expect(detail.header.maxCalories, 650);
    expect(detail.header.coachNotes, 'Ưu tiên món Việt');
  });
}
