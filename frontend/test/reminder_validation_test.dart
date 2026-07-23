import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/adaptive_reminders/utils/reminder_validation.dart';

void main() {
  final now = DateTime(2026, 7, 22, 13, 50);

  ReminderValidationResult validate({
    String title = 'Mang cơm',
    String body = 'Nhớ mang cơm trước khi đi làm.',
    DateTime? scheduledAt,
  }) => validateReminderInput(
    title: title,
    body: body,
    scheduledAt: scheduledAt ?? DateTime(2026, 7, 22, 14),
    now: now,
  );

  test('chấp nhận nội dung đầy đủ và thời gian hợp lệ', () {
    expect(validate().isValid, isTrue);
  });

  test('giải thích khi thiếu tiêu đề', () {
    final result = validate(title: '   ');

    expect(result.titleError, contains('nhập tiêu đề'));
    expect(result.firstError, result.titleError);
  });

  test('giải thích khi thiếu nội dung', () {
    final result = validate(body: '');

    expect(result.bodyError, contains('nhập nội dung'));
  });

  test('phân biệt ngày đã qua', () {
    final result = validate(scheduledAt: DateTime(2026, 7, 21, 18));

    expect(result.scheduleError, startsWith('Ngày nhắc đã qua'));
  });

  test('phân biệt giờ đã qua trong ngày hiện tại', () {
    final result = validate(scheduledAt: DateTime(2026, 7, 22, 13, 40));

    expect(result.scheduleError, startsWith('Giờ nhắc đã qua'));
  });

  test('yêu cầu thời gian cách hiện tại ít nhất một phút', () {
    final result = validate(scheduledAt: DateTime(2026, 7, 22, 13, 50, 30));

    expect(result.scheduleError, contains('ít nhất 1 phút'));
  });

  test('kiểm tra giới hạn độ dài theo backend', () {
    final longTitle = List.filled(256, 'a').join();
    final longBody = List.filled(1001, 'a').join();

    expect(validate(title: longTitle).titleError, contains('255 ký tự'));
    expect(validate(body: longBody).bodyError, contains('1000 ký tự'));
  });
}
