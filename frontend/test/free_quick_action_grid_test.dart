import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/widgets/quick_action_grid.dart';

void main() {
  testWidgets('Free grid shows seven Free shortcuts and hides paid shortcuts', (
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
              padding: EdgeInsets.all(12),
              child: QuickActionGrid(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tìm\nmón'), findsOneWidget);
    expect(find.text('Ghi\nbữa ăn'), findsOneWidget);
    expect(find.text('Tra cứu\ncalo'), findsOneWidget);
    expect(find.text('Cân\nnặng'), findsOneWidget);
    expect(find.text('Kế hoạch\năn'), findsOneWidget);
    expect(find.text('Ăn\nngoài?'), findsOneWidget);
    expect(find.text('Yêu\nthích'), findsOneWidget);
    expect(find.text('Khác'), findsOneWidget);

    expect(find.text('Hôm nay\năn gì?'), findsNothing);
    expect(find.text('Gói\nGym/PT'), findsNothing);
    expect(find.text('Không gian\nOffice'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Free weight shortcut opens the weight log sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuickActionGrid())),
    );

    await tester.tap(find.text('Cân\nnặng'));
    await tester.pumpAndSettle();

    expect(find.text('Ghi cân nặng'), findsOneWidget);
  });
}
