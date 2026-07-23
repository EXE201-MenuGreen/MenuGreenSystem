import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/office/widgets/office_grocery_section.dart';

void main() {
  testWidgets('shows after-work shopping trips and their covered meals', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfficeGroceryTab(
            loading: false,
            hasPlan: true,
            currency: (value) => '${value ?? 0}đ',
            data: {
              'estimatedTotalVnd': 75000,
              'items': [
                {'name': 'Ức gà'},
                {'name': 'Yến mạch'},
              ],
              'shoppingTrips': [
                {
                  'shoppingDate': '2026-07-20',
                  'estimatedTotalVnd': 75000,
                  'coveredMeals': [
                    {'plannedDate': '2026-07-20', 'mealType': 'dinner'},
                    {'plannedDate': '2026-07-21', 'mealType': 'breakfast'},
                    {'plannedDate': '2026-07-21', 'mealType': 'lunch'},
                  ],
                  'items': [
                    {
                      'name': 'Ức gà',
                      'quantity': 700,
                      'unit': 'g',
                      'estimatedPriceVnd': 42000,
                    },
                    {
                      'name': 'Yến mạch',
                      'quantity': 350,
                      'unit': 'g',
                      'estimatedPriceVnd': 33000,
                      'isWeeklyStock': true,
                    },
                  ],
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(
      find.text('1 lượt mua · 2 nguyên liệu · Ước tính 75000đ'),
      findsOneWidget,
    );
    expect(find.text('Mua sau giờ làm Thứ Hai, 20/07'), findsOneWidget);
    expect(find.text('Cho tối 20/07 · sáng & trưa 21/07'), findsOneWidget);
    expect(find.text('Mua một lần, dùng nhiều ngày'), findsOneWidget);
    expect(find.text('Ức gà'), findsOneWidget);
    expect(find.text('Yến mạch'), findsOneWidget);
  });
}
