import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/profile/widgets/health_metrics_card.dart';

void main() {
  testWidgets('renders BMI, energy targets and macros from profile data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthMetricsCard(
            data: const {
              'bmi': 29.3,
              'bmrKcal': 1401,
              'tdeeKcal': 1926,
              'targetCalories': 1926,
              'targetProteinG': 144,
              'targetCarbsG': 193,
              'targetFatG': 64,
            },
          ),
        ),
      ),
    );

    expect(find.text('29.3'), findsOneWidget);
    expect(find.text('1401'), findsOneWidget);
    expect(find.text('1926'), findsNWidgets(2));
    expect(find.text('144 g'), findsOneWidget);
    expect(find.text('193 g'), findsOneWidget);
    expect(find.text('64 g'), findsOneWidget);
  });

  testWidgets('shows guidance when calculated metrics are unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HealthMetricsCard(data: {})),
      ),
    );

    expect(
      find.text(
        'Hãy hoàn thiện thông tin và lưu thay đổi để hệ thống tính các chỉ số.',
      ),
      findsOneWidget,
    );
  });
}
