import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_models.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_responses.dart';
import 'package:frontend/features/meal_plan/providers/meal_plan_provider.dart';
import 'package:frontend/features/meal_plan/repositories/meal_plan_repository.dart';

void main() {
  test(
    'external mutation invalidates cache and reloads plan dashboard',
    () async {
      final repository = _FakeMealPlanRepository();
      final provider = MealPlanProvider(repository: repository);
      addTearDown(provider.dispose);

      await provider.refreshAfterExternalMutation();

      expect(repository.invalidateCalls, 1);
      expect(repository.planLoadCalls, 1);
      expect(repository.dashboardLoadCalls, 1);
      expect(provider.isLoading, isFalse);
    },
  );
}

class _FakeMealPlanRepository extends MealPlanRepository {
  int invalidateCalls = 0;
  int planLoadCalls = 0;
  int dashboardLoadCalls = 0;

  @override
  void invalidateCache() {
    invalidateCalls++;
  }

  @override
  Future<List<MealPlanListItem>> getPlans({bool? isActive}) async {
    planLoadCalls++;
    return [];
  }

  @override
  Future<MealPlanDayDashboard> getDashboard(DateTime date) async {
    dashboardLoadCalls++;
    throw Exception('Use adherence fallback in this isolated test.');
  }

  @override
  Future<MealPlanAdherence?> getAdherence(DateTime date) async => null;

  @override
  Future<MealPlanStreak> getStreaks() async {
    throw Exception('Streak data is unrelated to this test.');
  }
}
