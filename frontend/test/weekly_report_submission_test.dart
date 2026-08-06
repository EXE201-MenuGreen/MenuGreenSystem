import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/advanced/repositories/advanced_repository.dart';
import 'package:frontend/features/advanced/views/advanced_features_screen.dart';
import 'package:frontend/features/vietnam_local/models/vietnam_local_models.dart';
import 'package:frontend/features/vietnam_local/repositories/vietnam_local_repositories.dart';

class _FakeAdvancedRepository extends AdvancedRepository {
  final List<Map<String, dynamic>> _reports = [];
  final List<Map<String, dynamic>> _proposals = [];
  final Map<String, Map<String, dynamic>> _results = {};
  int createCalls = 0;
  String? submittedWeekStart;
  String? submittedNote;
  double? submittedWeight;
  double? submittedBodyFat;
  int? submittedTrainingDays;
  String? submittedFeeling;

  @override
  Future<List<Map<String, dynamic>>> ptRequests() async =>
      List<Map<String, dynamic>>.from(_reports);

  @override
  Future<List<Map<String, dynamic>>> myMealPlanProposals({
    String? status,
  }) async => List<Map<String, dynamic>>.from(_proposals);

  @override
  Future<Map<String, dynamic>> mealPlanProposal(String proposalId) async =>
      Map<String, dynamic>.from(
        _proposals.firstWhere((proposal) => proposal['id'] == proposalId),
      );

  @override
  Future<Map<String, dynamic>> ptResult(String id) async =>
      Map<String, dynamic>.from(_results[id]!);

  @override
  Future<List<Map<String, dynamic>>> myCoaches() async => [
    {'connectionStatus': 'Connected'},
  ];

  @override
  Future<Map<String, dynamic>> createPtReport(
    String weekStart,
    int expiry, {
    String requestType = 'WeeklyReport',
    String? studentNote,
    double? checkInWeight,
    double? checkInBodyFat,
    int? trainingDaysCount,
    String? bodyFeeling,
  }) async {
    createCalls++;
    submittedWeekStart = weekStart;
    submittedNote = studentNote;
    submittedWeight = checkInWeight;
    submittedBodyFat = checkInBodyFat;
    submittedTrainingDays = trainingDaysCount;
    submittedFeeling = bodyFeeling;
    _reports.add({
      'reportId': 'report-1',
      'requestType': requestType,
      'weekStartDate': weekStart,
      'status': 'Pending',
    });
    return {'reportId': 'report-1', 'shareLink': 'https://example.test/r/1'};
  }
}

class _FakePlannedVsActualRepository extends PlannedVsActualRepository {
  @override
  Future<ApiResult<PlannedVsActualSummary>> getSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final start = from!;
    final days = List.generate(7, (index) {
      final hasActual = index != 2;
      return PlannedVsActualDay(
        date: start.add(Duration(days: index)),
        planned: const PlannedNutrition(
          caloriesKcal: 2000,
          proteinG: 120,
          carbsG: 220,
          fatG: 60,
        ),
        actual: PlannedNutrition(
          caloriesKcal: hasActual ? 1900 : 0,
          proteinG: hasActual ? 110 : 0,
          carbsG: hasActual ? 210 : 0,
          fatG: hasActual ? 55 : 0,
        ),
      );
    });
    return ApiResult(
      success: true,
      data: PlannedVsActualSummary(
        from: start,
        to: to!,
        totalPlanned: const PlannedNutrition(
          caloriesKcal: 14000,
          proteinG: 840,
        ),
        totalActual: const PlannedNutrition(caloriesKcal: 11400, proteinG: 660),
        details: days,
      ),
    );
  }

  @override
  Future<ApiResult<AdherenceScore>> getAdherenceScore({
    DateTime? from,
    DateTime? to,
  }) async => const ApiResult(
    success: true,
    data: AdherenceScore(
      overallScore: 82,
      mealCompletionRate: 85,
      calorieDeviationScore: 80,
      macroDeviationScore: 78,
      unplannedPenaltyScore: 100,
      rating: 'GOOD',
      feedback: '',
    ),
  );
}

void main() {
  testWidgets('shows the weekly report as a readable date range', (
    tester,
  ) async {
    final repository = _FakeAdvancedRepository();
    repository._reports.add({
      'reportId': 'report-1',
      'requestType': 'WeeklyReport',
      'weekStartDate': '2026-08-03',
      'status': 'Pending',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AdvancedFeaturesScreen(
          gymerOnly: true,
          repository: repository,
          reportAnalyticsRepository: _FakePlannedVsActualRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tuần 03/08/2026 - 09/08/2026'), findsOneWidget);
    expect(find.text('Tuần 2026-08-03'), findsNothing);
  });

  testWidgets('reviews weekly data before submitting the report', (
    tester,
  ) async {
    final repository = _FakeAdvancedRepository();
    final analyticsRepository = _FakePlannedVsActualRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AdvancedFeaturesScreen(
          gymerOnly: true,
          repository: repository,
          reportAnalyticsRepository: analyticsRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Xem lại & tạo báo cáo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'preview must not overflow');

    expect(find.text('Chuẩn bị báo cáo tuần'), findsOneWidget);
    expect(find.text('Dữ liệu từng ngày'), findsOneWidget);
    expect(find.text('82/100'), findsOneWidget);
    expect(find.textContaining('ngày chưa có dữ liệu thực tế'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Thứ Hai').first);
    await tester.pumpAndSettle();
    expect(find.text('Kế hoạch'), findsOneWidget);
    expect(find.text('Thực tế'), findsOneWidget);
    expect(find.text('Mở nhật ký ngày này'), findsOneWidget);
    await tester.tapAt(const Offset(8, 80));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếp tục tạo báo cáo'));
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'check-in dialog must not overflow',
    );

    final inputs = find.byType(TextField);
    expect(inputs, findsNWidgets(3));
    await tester.enterText(inputs.at(0), '70.5');
    await tester.enterText(inputs.at(1), '16.2');
    await tester.enterText(inputs.at(2), 'Tuần này tập đúng kế hoạch');
    await tester.ensureVisible(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.createCalls, 1);
    expect(repository.submittedWeight, 70.5);
    expect(repository.submittedBodyFat, 16.2);
    expect(repository.submittedTrainingDays, 3);
    expect(repository.submittedFeeling, 'Khỏe 😊');
    expect(repository.submittedNote, 'Tuần này tập đúng kế hoạch');
    expect(repository.submittedWeekStart, isNotEmpty);
    expect(find.text('Báo cáo & Check-in Tuần'), findsNothing);
  });

  testWidgets(
    'mid-week review detail shows the exact meal changes sent by the coach',
    (tester) async {
      final repository = _FakeAdvancedRepository();
      repository._reports.add({
        'reportId': 'midweek-report-1',
        'requestType': 'MidWeekCheckIn',
        'weekStartDate': '2026-08-03',
        'status': 'Reviewed',
        'checkInWeight': 75,
        'trainingDaysCount': 3,
        'bodyFeeling': 'Khỏe 😊',
        'ptComment': 'Tiếp tục duy trì tốt',
        'suggestedCalorieTarget': 1500,
        'suggestedProteinTarget': 150,
      });
      repository._results['midweek-report-1'] = {
        'reportId': 'midweek-report-1',
        'requestType': 'MidWeekCheckIn',
        'weekStartDate': '2026-08-03',
        'status': 'Reviewed',
        'checkInWeight': 75,
        'trainingDaysCount': 3,
        'bodyFeeling': 'Khỏe 😊',
        'ptComment': 'Tiếp tục duy trì tốt',
        'suggestedCalorieTarget': 1500,
        'suggestedProteinTarget': 150,
        'suggestedChanges': <dynamic>[],
      };
      repository._proposals.add({
        'id': 'proposal-1',
        'reviewRequestId': 'midweek-report-1',
        'proposalType': 'CurrentWeekAdjustment',
        'status': 'Pending',
        'periodStart': '2026-08-07',
        'periodEnd': '2026-08-09',
        'items': [
          {
            'id': 'change-1',
            'action': 'Replace',
            'plannedDate': '2026-08-07',
            'mealType': 'lunch',
            'existingMealPlanItemId': 'old-item-1',
            'displayName': 'Ức gà nướng',
            'quantityG': 180,
            'targetCalories': 320,
          },
          {
            'id': 'change-2',
            'action': 'Add',
            'plannedDate': '2026-08-08',
            'mealType': 'snack',
            'displayName': 'Sữa chua Hy Lạp',
            'quantityG': 100,
            'targetCalories': 120,
          },
        ],
        'sourceMeals': [
          {
            'mealPlanItemId': 'old-item-1',
            'plannedDate': '2026-08-07',
            'mealType': 'lunch',
            'displayName': 'Cơm gạo lứt',
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdvancedFeaturesScreen(
            gymerOnly: true,
            repository: repository,
            reportAnalyticsRepository: _FakePlannedVsActualRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đề xuất đang chờ bạn duyệt'), findsNothing);
      expect(find.text('Đề xuất điều chỉnh giữa tuần'), findsNothing);
      expect(find.text('Sữa chua Hy Lạp'), findsNothing);

      final detailButton = find.text('Xem chi tiết');
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      await tester.tap(detailButton);
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết đánh giá giữa tuần'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Đề xuất điều chỉnh giữa tuần'), findsOneWidget);
      expect(find.text('Thứ Sáu, 07/08/2026'), findsOneWidget);
      expect(find.text('Bữa trưa • Thay món'), findsOneWidget);
      expect(find.text('Cơm gạo lứt → Ức gà nướng'), findsOneWidget);
      expect(find.text('180 g • 320 kcal'), findsOneWidget);
      expect(find.text('Thứ Bảy, 08/08/2026'), findsOneWidget);
      expect(find.text('Bữa phụ • Thêm món'), findsOneWidget);
      expect(find.text('Sữa chua Hy Lạp'), findsOneWidget);
      expect(find.text('Từ chối toàn bộ'), findsOneWidget);
      expect(find.text('Áp dụng toàn bộ'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết đánh giá giữa tuần'), findsNothing);
      expect(find.text('Xem chi tiết'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
