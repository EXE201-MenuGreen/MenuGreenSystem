import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/i18n/api_message_translator.dart';

void main() {
  group('ApiMessageTranslator', () {
    test('translates exact API messages', () {
      expect(
        ApiMessageTranslator.translate('Recipe not found.'),
        'Không tìm thấy công thức.',
      );
      expect(
        ApiMessageTranslator.translate('Calorie intake deviates more than 10% from daily target.'),
        'Calo lệch hơn 10% so với mục tiêu ngày.',
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
