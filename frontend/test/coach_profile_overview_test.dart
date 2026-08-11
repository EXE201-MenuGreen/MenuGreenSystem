import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach/widgets/coach_profile_overview.dart';

void main() {
  testWidgets('renders the complete PT profile from application data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CoachProfileOverview(
              email: 'coach@menugreen.app',
              connectedClients: 3,
              pendingClients: 1,
              profile: {
                'fullName': 'Huấn luyện viên Coach',
                'headline': 'PT tăng cơ và giảm mỡ cho người mới',
                'city': 'TP. Hồ Chí Minh',
                'experienceYears': 6,
                'applicationStatus': 'Approved',
                'phoneNumber': '0901234567',
                'dateOfBirth': '1992-05-15',
                'gender': 'Male',
                'bio': 'Giới thiệu đầy đủ về kinh nghiệm huấn luyện.',
                'specialty': 'Tăng cơ, Giảm mỡ',
                'languages': ['Tiếng Việt', 'English'],
                'coachingStyles': ['Theo sát số liệu'],
                'clientLevels': ['Người mới'],
                'certificates': [
                  {
                    'name': 'NASM Certified Personal Trainer',
                    'issuer': 'NASM',
                    'issuedDate': '2024-01-15',
                    'expiryDate': '2028-01-15',
                    'imageUrl': '',
                  },
                ],
                'achievements': 'Đã đồng hành cùng hơn 100 học viên.',
                'galleryUrls': <String>[],
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Huấn luyện viên Coach'), findsOneWidget);
    expect(find.text('Thông tin riêng tư'), findsOneWidget);
    expect(find.text('coach@menugreen.app'), findsOneWidget);
    expect(find.text('Phương pháp huấn luyện'), findsOneWidget);
    expect(find.text('NASM Certified Personal Trainer'), findsOneWidget);
    expect(find.text('Thành tích nổi bật'), findsOneWidget);
  });

  testWidgets('shows and handles the PT change-password action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CoachProfileOverview(
              profile: const {
                'fullName': 'Huấn luyện viên Coach',
                'applicationStatus': 'Approved',
              },
              email: 'coach@menugreen.app',
              connectedClients: 1,
              pendingClients: 0,
              onChangePassword: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Đổi mật khẩu'));
    await tester.tap(find.text('Đổi mật khẩu'));

    expect(tapped, isTrue);
  });
}
