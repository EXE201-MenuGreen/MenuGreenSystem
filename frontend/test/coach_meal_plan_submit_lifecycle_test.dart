import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/models/coach_meal_plan_models.dart';
import 'package:frontend/features/coach_pt/providers/coach_meal_plan_provider.dart';
import 'package:frontend/features/coach_pt/views/coach_meal_plan_history_screen.dart';
import 'package:provider/provider.dart';

void main() {
  test('an active Gymer plan is shown as not approved', () {
    expect(coachMealPlanStatusLabel('Active'), 'Chưa duyệt');
    expect(coachMealPlanStatusLabel('Approved'), 'Đã duyệt & gửi');
    expect(
      coachMealPlanStatusLabel('PendingAcceptance'),
      'Chờ Gymer chấp nhận',
    );
  });

  testWidgets(
    'submitting a plan tears down dialog and detail route before SnackBar',
    (tester) async {
      final provider = _FakeCoachMealPlanProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CoachMealPlanProvider>.value(
            value: provider,
            child: const CoachMealPlanHistoryScreen(
              clientId: 'client-1',
              clientName: 'Học viên',
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Lộ trình kiểm thử'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duyệt & gửi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi'));

      // Finish the dialog and detail-route reverse transitions. The success
      // SnackBar is only inserted after both overlays have been removed.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(provider.submitCalls, 1);
      expect(provider.refreshCalls, 1);
      expect(
        find.text(
          'Đã gửi lộ trình. Gymer sẽ nhận thông báo để xem và chấp nhận.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('approved plan cannot be submitted or edited again', (
    tester,
  ) async {
    final provider = _FakeCoachMealPlanProvider(status: 'Approved');

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<CoachMealPlanProvider>.value(
          value: provider,
          child: const CoachMealPlanHistoryScreen(
            clientId: 'client-1',
            clientName: 'Học viên',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Lộ trình kiểm thử'));
    await tester.pumpAndSettle();

    expect(find.text('Duyệt & gửi'), findsNothing);
    expect(find.text('Đã duyệt & gửi cho học viên'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(provider.submitCalls, 0);
  });
}

class _FakeCoachMealPlanProvider extends CoachMealPlanProvider {
  _FakeCoachMealPlanProvider({String status = 'Active'})
    : _plans = [
        CoachMealPlanListItem(
          id: 'plan-1',
          title: 'Lộ trình kiểm thử',
          planType: 'daily',
          startDate: DateTime(2026, 7, 26),
          endDate: DateTime(2026, 7, 26),
          targetCalories: 2000,
          totalItems: 0,
          completedItems: 0,
          status: status,
        ),
      ],
      _detail = CoachMealPlanDetail(
        header: CoachMealPlanHeader(
          id: 'plan-1',
          title: 'Lộ trình kiểm thử',
          planType: 'daily',
          isActive: true,
          startDate: DateTime(2026, 7, 26),
          endDate: DateTime(2026, 7, 26),
          targetCalories: 2000,
          status: status,
        ),
        itemsByMeal: const {
          'breakfast': [],
          'lunch': [],
          'dinner': [],
          'snack': [],
        },
      );

  final List<CoachMealPlanListItem> _plans;
  final CoachMealPlanDetail _detail;
  int submitCalls = 0;
  int refreshCalls = 0;

  @override
  List<CoachMealPlanListItem> get plans => _plans;

  @override
  CoachMealPlanDetail? get selectedPlan => _detail;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingDetail => false;

  @override
  String? get error => null;

  @override
  String? get detailError => null;

  @override
  Future<void> loadPlanDetail(String planId) async {}

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  void setFilters({DateTime? from, DateTime? to, String? planType}) {}

  @override
  Future<bool> submitPlan(
    String planId, {
    String? notes,
    int? minCalories,
    int? maxCalories,
  }) async {
    submitCalls++;
    return true;
  }
}
