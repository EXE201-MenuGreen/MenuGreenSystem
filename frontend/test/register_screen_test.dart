import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/views/register_screen.dart';

void main() {
  testWidgets('PT account option explains that onboarding is skipped', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    const skipSurveyMessage =
        'Tài khoản PT sẽ vào thẳng không gian quản lý sau khi xác thực OTP, không cần làm khảo sát.';

    expect(find.text(skipSurveyMessage), findsNothing);

    await tester.tap(find.text('PT'));
    await tester.pumpAndSettle();

    expect(find.text(skipSurveyMessage), findsOneWidget);
  });
}
