import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/providers/coach_meal_plan_provider.dart';
import 'package:frontend/features/coach_pt/views/coach_create_meal_plan_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'step 2 automatically shows suitable foods and initializes an editable plan',
    (tester) async {
      final provider = _SuggestionCoachMealPlanProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CoachMealPlanProvider>.value(
            value: provider,
            child: const CoachCreateMealPlanScreen(
              clientId: 'client-1',
              clientName: 'Hoàng Thị Gymer',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(provider.suggestionCalls, 1);
      expect(provider.receivedTargetCalories, 1500);
      expect(provider.receivedMinCalories, 500);
      expect(provider.receivedMaxCalories, 1500);
      expect(find.text('Bò xào giá đỗ'), findsOneWidget);
      expect(find.text('Khởi tạo lộ trình từ gợi ý'), findsOneWidget);

      await tester.tap(find.text('Khởi tạo lộ trình từ gợi ý'));
      await tester.pump();

      expect(find.textContaining('Bò xào giá đỗ'), findsAtLeastNWidgets(2));
      expect(find.byTooltip('Thay món'), findsWidgets);
      expect(find.byTooltip('Xóa món'), findsWidgets);
    },
  );
}

class _SuggestionCoachMealPlanProvider extends CoachMealPlanProvider {
  int suggestionCalls = 0;
  int? receivedTargetCalories;
  int? receivedMinCalories;
  int? receivedMaxCalories;

  @override
  Future<Map<String, dynamic>?> loadClientGymConfig(DateTime date) async {
    return {
      'targetCalories': 1500,
      'minCalories': 500,
      'maxCalories': 1500,
      'scope': 'profile',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> loadSuggestions({
    required DateTime date,
    required int targetCalories,
    int? minCalories,
    int? maxCalories,
    int top = 20,
  }) async {
    suggestionCalls++;
    receivedTargetCalories = targetCalories;
    receivedMinCalories = minCalories;
    receivedMaxCalories = maxCalories;
    return [
      {
        'id': 'recipe-1',
        'name': 'Bò xào giá đỗ',
        'type': 'Recipe',
        'caloriesKcal': 631,
        'proteinG': 32,
        'carbsG': 45,
        'fatG': 18,
      },
    ];
  }
}
