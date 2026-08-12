import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach/views/coach_application_screen.dart';

void main() {
  testWidgets('PT onboarding reports only the missing full-name field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CoachApplicationScreen(
          initialData: {..._validPersonalData(), 'fullName': ''},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
    expect(find.text('Vui lòng tải ảnh đại diện.'), findsNothing);
    expect(find.text('Vui lòng chọn ngày sinh.'), findsNothing);
    expect(find.text('Vui lòng nhập số điện thoại.'), findsNothing);
    expect(find.text('Vui lòng nhập tỉnh/thành phố.'), findsNothing);
    expect(find.text('Vui lòng chọn ít nhất một ngôn ngữ.'), findsNothing);
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
  });

  testWidgets('professional PT fields show separate validation messages', (
    tester,
  ) async {
    await _pumpApplication(tester, {
      ..._validPersonalData(),
      'headline': '',
      'bio': '',
      'experienceYears': 3,
      'specialty': '',
    });

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();

    expect(find.text('Vui lòng nhập tiêu đề hồ sơ.'), findsOneWidget);
    expect(
      find.text('Vui lòng nhập phần giới thiệu bản thân.'),
      findsOneWidget,
    );
    expect(find.text('Vui lòng chọn ít nhất một chuyên môn.'), findsOneWidget);
  });

  testWidgets('verification items each show their own validation message', (
    tester,
  ) async {
    await _pumpApplication(tester, {
      ..._validPersonalData(),
      'headline': 'PT tăng cơ cho người mới',
      'bio': List.filled(80, 'a').join(),
      'experienceYears': 3,
      'specialty': 'Tăng cơ',
      'certificates': const <Map<String, dynamic>>[],
    });

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    await tester.tap(find.text('Gửi hồ sơ xét duyệt'));
    await tester.pump();

    expect(find.text('Vui lòng nhập tên chứng chỉ.'), findsOneWidget);
    expect(find.text('Vui lòng nhập đơn vị cấp.'), findsOneWidget);
    expect(find.text('Vui lòng tải ảnh chứng chỉ.'), findsOneWidget);
    expect(find.text('Vui lòng tải ảnh giấy tờ xác minh.'), findsOneWidget);
    expect(
      find.text('Vui lòng thêm ít nhất một ảnh hoạt động.'),
      findsOneWidget,
    );
    expect(
      find.text('Vui lòng xác nhận quyền sử dụng hình ảnh.'),
      findsOneWidget,
    );
    expect(
      find.text('Mỗi chứng chỉ cần có tên, đơn vị cấp và ảnh minh chứng.'),
      findsNothing,
    );
  });
}

Map<String, dynamic> _validPersonalData() => {
  'applicationStatus': 'Draft',
  'fullName': 'Nguyễn Văn An',
  'avatarUrl': 'https://example.invalid/avatar.jpg',
  'dateOfBirth': '1990-01-01',
  'phoneNumber': '0901234567',
  'city': 'TP. Hồ Chí Minh',
  'languages': ['Tiếng Việt'],
  'experienceYears': 3,
  'certificates': const <Map<String, dynamic>>[],
};

Future<void> _pumpApplication(
  WidgetTester tester,
  Map<String, dynamic> initialData,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(home: CoachApplicationScreen(initialData: initialData)),
  );
  await tester.pumpAndSettle();
}
