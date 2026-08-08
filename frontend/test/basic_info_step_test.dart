import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/custom_text_field.dart';
import 'package:frontend/features/onboarding/views/steps/basic_info_step.dart';

void main() {
  testWidgets('shows the registered full name without allowing re-entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BasicInfoStep(
            initialFullName: 'Nguyễn Văn An',
            onNext:
                ({
                  required fullName,
                  required gender,
                  dateOfBirth,
                  required heightCm,
                  required weightKg,
                  bodyFatPercent,
                  targetWeightKg,
                  required activityLevel,
                  required goal,
                }) async {},
          ),
        ),
      ),
    );

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    final fullNameField = tester.widget<CustomTextField>(
      find.byType(CustomTextField).first,
    );
    expect(fullNameField.readOnly, isTrue);
  });

  testWidgets('fills and locks the full name when it arrives after startup', (
    tester,
  ) async {
    late StateSetter updateHost;
    String? fullName;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return BasicInfoStep(
                initialFullName: fullName,
                onNext:
                    ({
                      required fullName,
                      required gender,
                      dateOfBirth,
                      required heightCm,
                      required weightKg,
                      bodyFatPercent,
                      targetWeightKg,
                      required activityLevel,
                      required goal,
                    }) async {},
              );
            },
          ),
        ),
      ),
    );

    updateHost(() => fullName = 'Trần Thị Bình');
    await tester.pump();

    expect(find.text('Trần Thị Bình'), findsOneWidget);
    final fullNameField = tester.widget<CustomTextField>(
      find.byType(CustomTextField).first,
    );
    expect(fullNameField.readOnly, isTrue);
  });
}
