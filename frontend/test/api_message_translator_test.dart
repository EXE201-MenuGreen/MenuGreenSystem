import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/i18n/api_message_translator_fixed.dart';

void main() {
  group('ApiMessageTranslator', () {
    test('translates exact API messages', () {
      expect(
        ApiMessageTranslator.translate('Recipe not found.'),
        'Không tìm thấy công thức.',
      );
      expect(
        ApiMessageTranslator.translate(
          'Calorie intake deviates more than 10% from daily target.',
        ),
        'Calo lệch hơn 10% so với mục tiêu ngày.',
      );
      expect(
        ApiMessageTranslator.translate(
          'Current weight is confirmed, but there are not enough consistent weight logs to adjust calories safely. Keeping the current target.',
        ),
        'Đã xác nhận cân nặng hiện tại nhưng chưa đủ dữ liệu nhất quán để điều chỉnh calo an toàn. Hệ thống giữ nguyên mục tiêu hiện tại.',
      );
    });

    test('translates macro warning patterns', () {
      expect(
        ApiMessageTranslator.translate('Protein below target (50g / 120g).'),
        'Protein thấp hơn mục tiêu (50g / 120g).',
      );
      expect(
        ApiMessageTranslator.translate('Fat exceeds target (80g / 60g).'),
        'Chất béo vượt mục tiêu (80g / 60g).',
      );
    });

    test('keeps Vietnamese messages unchanged', () {
      const vi = 'Không tải được dữ liệu.';
      expect(ApiMessageTranslator.translate(vi), vi);
    });

    test('keeps foreground notification translations valid UTF-8', () {
      final translated = ApiMessageTranslator.translateNotification(
        'Connection request accepted',
      );

      expect(translated, 'Yêu cầu kết nối đã được chấp nhận');
      expect(translated, isNot(contains('Ã')));
      expect(translated, isNot(contains('Ä')));
    });

    test('translates dynamic PT connection notifications', () {
      expect(
        ApiMessageTranslator.translateNotification(
          'Coach Trần Minh has accepted your connection request.',
        ),
        'PT Trần Minh đã chấp nhận yêu cầu kết nối của bạn.',
      );
      expect(
        ApiMessageTranslator.translateNotification(
          'Coach Trần Minh has rejected your connection request.',
        ),
        'PT Trần Minh đã từ chối yêu cầu kết nối của bạn.',
      );
    });

    test('translateList maps all items', () {
      final out = ApiMessageTranslator.translateList([
        'Food not found.',
        'Protein below target (50g / 120g).',
      ]);
      expect(out.length, 2);
      expect(out.first, 'Không tìm thấy món ăn.');
    });
  });
}
