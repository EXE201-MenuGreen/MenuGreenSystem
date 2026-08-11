import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/views/register_screen.dart';

void main() {
  testWidgets('PT account option explains the separate PT onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    const onboardingMessage =
        'Sau khi xác thực OTP, bạn sẽ hoàn thiện hồ sơ PT và gửi Admin xét duyệt trước khi nhận học viên.';

    expect(find.text(onboardingMessage), findsNothing);

    await tester.tap(find.text('PT'));
    await tester.pumpAndSettle();

    expect(find.text(onboardingMessage), findsOneWidget);
  });

  testWidgets('missing full name shows only the full-name validation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'pt@example.com');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.enterText(fields.at(3), 'secret1');
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
    expect(find.text('Vui lòng nhập email.'), findsNothing);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsNothing);
    expect(find.text('Vui lòng nhập lại mật khẩu.'), findsNothing);
    expect(find.text('Vui lòng nhập đầy đủ thông tin'), findsNothing);
  });

  testWidgets('each empty registration field has its own validation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    expect(find.text('Vui lòng nhập lại mật khẩu.'), findsOneWidget);
    expect(find.text('Vui lòng nhập đầy đủ thông tin'), findsNothing);
  });
}
