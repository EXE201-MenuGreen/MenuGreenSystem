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
      expect(provider.receivedMinProteinG, 50);
      expect(provider.receivedMaxProteinG, 100);
      expect(find.text('Bò xào giá đỗ'), findsOneWidget);
      expect(find.text('Danh sách món ăn gợi ý'), findsOneWidget);
      expect(find.text('Khởi tạo lộ trình mới'), findsOneWidget);
      expect(find.text('Trang 1/2'), findsOneWidget);
      expect(find.text('Món phân trang 7'), findsNothing);

      await tester.ensureVisible(find.byTooltip('Trang sau'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Trang sau'));
      await tester.pump();
      expect(find.text('Trang 2/2'), findsOneWidget);
      expect(find.text('Món phân trang 7'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Trang trước'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Trang trước'));
      await tester.pump();

      await tester.ensureVisible(find.text('Khởi tạo lộ trình mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khởi tạo lộ trình mới'));
      await tester.pump();

      expect(find.textContaining('Bò xào giá đỗ'), findsAtLeastNWidgets(2));
      expect(find.byTooltip('Thay món'), findsWidgets);
      expect(find.byTooltip('Chỉnh sửa món'), findsWidgets);
      expect(find.byTooltip('Xóa món'), findsWidgets);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Tổng quan cấu hình'), findsOneWidget);
      expect(find.text('Ngày khởi tạo'), findsOneWidget);
      expect(find.text('Thực đơn xem lại'), findsOneWidget);
      expect(find.textContaining('Bò xào giá đỗ'), findsWidgets);
    },
  );
}

class _SuggestionCoachMealPlanProvider extends CoachMealPlanProvider {
  int suggestionCalls = 0;
  int? receivedTargetCalories;
  int? receivedMinCalories;
  int? receivedMaxCalories;
  double? receivedMinProteinG;
  double? receivedMaxProteinG;

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
    double? minProteinG,
    double? maxProteinG,
    int top = 20,
  }) async {
    suggestionCalls++;
    receivedTargetCalories = targetCalories;
    receivedMinCalories = minCalories;
    receivedMaxCalories = maxCalories;
    receivedMinProteinG = minProteinG;
    receivedMaxProteinG = maxProteinG;
    return [
      {
        'id': 'recipe-1',
        'name': 'Bò xào giá đỗ',
        'type': 'Recipe',
        'caloriesKcal': 631,
        'proteinG': 20,
        'carbsG': 45,
        'fatG': 18,
      },
      for (var index = 2; index <= 7; index++)
        {
          'id': 'recipe-$index',
          'name': 'Món phân trang $index',
          'type': 'Recipe',
          'caloriesKcal': 500 + index,
          'proteinG': 20,
          'carbsG': 40,
          'fatG': 12,
        },
    ];
  }
}
