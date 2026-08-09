import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/widgets/gymer_package_card.dart';

void main() {
  testWidgets('Gymer package is visually separated with four actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GymerPackageCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('GYMER VIP'), findsOneWidget);
    expect(find.text('TRẢ PHÍ'), findsOneWidget);
    expect(find.text('Bộ công cụ tập luyện đã kích hoạt'), findsOneWidget);
    expect(find.text('Mục tiêu'), findsOneWidget);
    expect(find.text('Báo cáo PT'), findsOneWidget);
    expect(find.text('Lộ trình'), findsOneWidget);
    expect(find.text('Chat với PT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unread chat badge belongs to the standalone chat action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GymerPackageCard(chatBadgeCount: 4)),
      ),
    );

    expect(find.text('Chat với PT'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
