import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/models/coach_meal_plan_models.dart';
import 'package:frontend/features/coach_pt/providers/coach_meal_plan_provider.dart';
import 'package:frontend/features/coach_pt/repositories/coach_meal_plan_repository.dart';
import 'package:frontend/features/coach_pt/views/coach_meal_plan_history_screen.dart';
import 'package:frontend/features/coach_pt/views/coach_meal_plan_select_client_screen.dart';
import 'package:frontend/features/advanced/repositories/advanced_repository.dart';
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

  test('localizes automatic daily titles and plan type labels', () {
    expect(
      coachMealPlanDisplayTitle(
        title: 'Daily plan 2026-07-31',
        planType: 'DAILY',
        startDate: DateTime(2026, 7, 31),
      ),
      'Kế hoạch dinh dưỡng 31-07-2026',
    );
    expect(coachMealPlanTypeLabel('DAILY'), 'Ngày:');
    expect(coachMealPlanTypeLabel('WEEKLY'), 'Tuần:');
    expect(coachMealPlanTypeLabel('MONTHLY'), 'Tháng:');
  });

  test('keeps a custom meal-plan title unchanged', () {
    expect(
      coachMealPlanDisplayTitle(
        title: 'Kế hoạch dinh dưỡng tuần mới',
        planType: 'WEEKLY',
        startDate: DateTime(2026, 7, 31),
      ),
      'Kế hoạch dinh dưỡng tuần mới',
    );
  });

  testWidgets('submitting a plan sends the form note without a second dialog', (
    tester,
  ) async {
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

    // Finish the detail-route reverse transition. Submission happens
    // directly, without asking for the same note a second time.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Duyệt & gửi cho học viên'), findsNothing);
    expect(provider.submitCalls, 1);
    expect(provider.submittedNotes, 'Ghi chú trong form');
    expect(provider.refreshCalls, 1);
    expect(
      find.text(
        'Đã gửi lộ trình. Gymer sẽ nhận thông báo để xem và chấp nhận.',
      ),
      findsOneWidget,
    );
  });

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

  testWidgets('PT can auto balance a Gymer plan before approving it', (
    tester,
  ) async {
    final provider = _FakeCoachMealPlanProvider(withMeals: true);

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

    expect(find.text('Tổng kcal của 4 bữa'), findsOneWidget);
    expect(find.text('Vượt 400 kcal'), findsOneWidget);

    final autoButton = find.text('Tùy chỉnh');
    await tester.ensureVisible(autoButton);
    await tester.pumpAndSettle();
    await tester.tap(autoButton);
    await tester.pumpAndSettle();
    expect(find.text('Thấp hơn'), findsOneWidget);
    expect(find.text('Cân bằng'), findsOneWidget);
    expect(find.text('Cao hơn'), findsOneWidget);
    await tester.tap(find.text('Áp dụng 2000 kcal'));
    await tester.pumpAndSettle();

    expect(find.text('2000 / 2000 kcal', findRichText: true), findsOneWidget);
    expect(find.text('Đạt mục tiêu'), findsOneWidget);

    await tester.tap(find.text('Lưu nháp').last);
    await tester.pumpAndSettle();
    expect(provider.updateCalls, 1);
    expect(
      provider.updatedPayload!.items.fold<int>(
        0,
        (sum, item) => sum + (item.targetCalories ?? 0),
      ),
      2000,
    );
  });

  testWidgets('client without a plan can create the first plan', (
    tester,
  ) async {
    final provider = _EmptyCoachMealPlanProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<CoachMealPlanProvider>.value(
          value: provider,
          child: const CoachMealPlanHistoryScreen(
            clientId: 'new-client',
            clientName: 'Học viên mới',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Chưa có lộ trình nào'), findsOneWidget);
    expect(find.text('Tạo lộ trình đầu tiên'), findsOneWidget);
  });

  testWidgets('route tab reloads newly connected clients when selected again', (
    tester,
  ) async {
    final controller = CoachMealPlanSelectClientController();
    final repository = _ChangingClientRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: CoachMealPlanSelectClientScreen(
          controller: controller,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Học viên cũ'), findsOneWidget);

    controller.refresh();
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Học viên mới kết nối'), findsOneWidget);
    controller.dispose();
  });
}

class _ChangingClientRepository extends AdvancedRepository {
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> clients() async {
    calls++;
    return [
      {
        'clientId': calls == 1 ? 'old-client' : 'new-client',
        'fullName': calls == 1 ? 'Học viên cũ' : 'Học viên mới kết nối',
        'email': calls == 1 ? 'old@example.com' : 'new@example.com',
        'connectionStatus': 'Connected',
      },
    ];
  }
}

class _EmptyCoachMealPlanProvider extends CoachMealPlanProvider {
  @override
  List<CoachMealPlanListItem> get plans => const [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  void setFilters({DateTime? from, DateTime? to, String? planType}) {}
}

class _FakeCoachMealPlanProvider extends CoachMealPlanProvider {
  _FakeCoachMealPlanProvider({String status = 'Active', bool withMeals = false})
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
          coachNotes: 'Ghi chú trong form',
        ),
        itemsByMeal: withMeals
            ? {
                'breakfast': [
                  CoachMealPlanItem(
                    id: 'breakfast-1',
                    mealType: 'breakfast',
                    displayName: 'Bữa sáng',
                    foodId: 'food-1',
                    plannedDate: DateTime(2026, 7, 26),
                    targetCalories: 600,
                    quantityG: 300,
                  ),
                ],
                'lunch': [
                  CoachMealPlanItem(
                    id: 'lunch-1',
                    mealType: 'lunch',
                    displayName: 'Bữa trưa',
                    foodId: 'food-2',
                    plannedDate: DateTime(2026, 7, 26),
                    targetCalories: 700,
                    quantityG: 350,
                  ),
                ],
                'dinner': [
                  CoachMealPlanItem(
                    id: 'dinner-1',
                    mealType: 'dinner',
                    displayName: 'Bữa tối',
                    foodId: 'food-3',
                    plannedDate: DateTime(2026, 7, 26),
                    targetCalories: 500,
                    quantityG: 250,
                  ),
                ],
                'snack': [
                  CoachMealPlanItem(
                    id: 'snack-1',
                    mealType: 'snack',
                    displayName: 'Bữa phụ',
                    foodId: 'food-4',
                    plannedDate: DateTime(2026, 7, 26),
                    targetCalories: 600,
                    quantityG: 300,
                  ),
                ],
              }
            : const {'breakfast': [], 'lunch': [], 'dinner': [], 'snack': []},
      );

  final List<CoachMealPlanListItem> _plans;
  final CoachMealPlanDetail _detail;
  int submitCalls = 0;
  int refreshCalls = 0;
  int updateCalls = 0;
  String? submittedNotes;
  ClientMealPlanPayload? updatedPayload;

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
  Future<bool> updatePlan(String planId, ClientMealPlanPayload payload) async {
    updateCalls++;
    updatedPayload = payload;
    return true;
  }

  @override
  Future<bool> submitPlan(
    String planId, {
    String? notes,
    int? minCalories,
    int? maxCalories,
  }) async {
    submitCalls++;
    submittedNotes = notes;
    return true;
  }
}
