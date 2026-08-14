import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/vietnam_local/models/vietnam_local_models.dart';
import 'package:frontend/features/vietnam_local/providers/daily_starter_provider.dart';
import 'package:frontend/features/vietnam_local/repositories/vietnam_local_repositories.dart';

void main() {
  const food = DailyStarterFood(
    id: 'fd000001-0000-0000-0000-000000000001',
    name: 'Ức gà áp chảo',
    caloriesKcal: 165,
  );

  test('adds the random food to the selected meal slot', () async {
    final repository = _FakeDailyStarterRepository();
    final provider = DailyStarterProvider(repository: repository);

    final added = await provider.addFoodToPlan(food: food, mealType: 'Lunch');

    expect(added, isTrue);
    expect(provider.isAddingToPlan, isFalse);
    expect(provider.errorMessage, isNull);
    expect(repository.lastPayload, {
      'meals': [
        {'foodId': food.id, 'mealType': 'Lunch'},
      ],
    });
  });

  test('exposes the API error when adding to the plan fails', () async {
    final repository = _FakeDailyStarterRepository(shouldFail: true);
    final provider = DailyStarterProvider(repository: repository);

    final added = await provider.addFoodToPlan(food: food, mealType: 'Dinner');

    expect(added, isFalse);
    expect(provider.isAddingToPlan, isFalse);
    expect(provider.errorMessage, 'Kế hoạch không thể chỉnh sửa.');
  });
}

class _FakeDailyStarterRepository extends DailyStarterRepository {
  _FakeDailyStarterRepository({this.shouldFail = false});

  final bool shouldFail;
  Map<String, dynamic>? lastPayload;

  @override
  Future<ApiResult<String>> selectMeal(Map<String, dynamic> payload) async {
    lastPayload = payload;
    if (shouldFail) {
      return const ApiResult<String>(
        success: false,
        message: 'Kế hoạch không thể chỉnh sửa.',
      );
    }
    return const ApiResult<String>(
      success: true,
      data: 'Đã thêm món vào kế hoạch.',
    );
  }
}
