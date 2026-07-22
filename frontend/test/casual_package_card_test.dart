import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/widgets/casual_package_card.dart';

void main() {
  testWidgets('Casual package is visually separated with three actions', (
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
              child: CasualPackageCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CASUAL PLUS'), findsOneWidget);
    expect(find.text('ĐÃ KÍCH HOẠT'), findsOneWidget);
    expect(
      find.text('Bộ công cụ ăn uống đơn giản đã sẵn sàng'),
      findsOneWidget,
    );
    expect(find.text('Vòng quay'), findsOneWidget);
    expect(find.text('1 chạm'), findsOneWidget);
    expect(find.text('Cảm xúc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
