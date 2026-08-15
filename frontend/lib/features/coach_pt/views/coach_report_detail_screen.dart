import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../coach_pt.dart';
import 'coach_create_meal_plan_screen.dart';

/// Coach reads and reviews a single weekly report.
///
/// * Top half: summary stats, 7-day detailed accordion breakdown,
///   planned vs actual nutrition, adherence score, check-in data.
/// * Bottom half: feedback form and inline meal-plan adjustments.
/// * CTA: "Tạo lộ trình tiếp theo" opens [CoachCreateMealPlanScreen].
class CoachReportDetailScreen extends StatefulWidget {
  const CoachReportDetailScreen({super.key, required this.reportId});
  final String reportId;

  @override
  State<CoachReportDetailScreen> createState() =>
      _CoachReportDetailScreenState();
}

class _CoachReportDetailScreenState extends State<CoachReportDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _calorieCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final List<MealPlanAdjustment> _adjustments = [];
  final AdvancedRepository _advancedRepository = AdvancedRepository();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CoachReportProvider>();
      if (provider.selectedDetail?.summary.reportId != widget.reportId) {
        provider.loadReportDetail(widget.reportId);
      }
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _calorieCtrl.dispose();
    _proteinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Vui lòng nhập nhận xét.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final submission = CoachReviewSubmission(
      comment: _commentCtrl.text.trim(),
      suggestedCalorieTarget: int.tryParse(_calorieCtrl.text.trim()),
      suggestedProteinTarget: int.tryParse(_proteinCtrl.text.trim()),
      adjustments: List.unmodifiable(_adjustments),
    );
    final ok = await context.read<CoachReportProvider>().submitReview(
      widget.reportId,
      submission,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          ok
              ? 'Đã gửi đánh giá. Học viên sẽ nhận thông báo.'
              : 'Gửi thất bại. Vui lòng thử lại.',
        ),
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _addAdjustmentDialog() async {
    final detail = context.read<CoachReportProvider>().selectedDetail;
    if (detail == null) return;
    final summary = detail.summary;
    final isMidWeek = summary.isMidWeekCheckIn;
    final firstDate = summary.weekStartDate.add(
      Duration(days: isMidWeek ? 4 : 7),
    );
    final lastDate = summary.weekStartDate.add(
      Duration(days: isMidWeek ? 6 : 13),
    );
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isMidWeek
          ? 'Chọn ngày điều chỉnh (Thứ Sáu–Chủ nhật)'
          : 'Chọn ngày của tuần kế tiếp',
    );
    if (!mounted || selectedDate == null) return;

    final sourceDate = isMidWeek
        ? selectedDate
        : selectedDate.subtract(const Duration(days: 7));
    final sourceMeals = _sourceMealsForDate(
      detail.reportData ?? const {},
      sourceDate,
      keepItemId: isMidWeek,
    );
    var candidates = <_AdjustmentCandidate>[];
    var catalogError = false;
    try {
      final target =
          summary.suggestedCalorieTarget ??
          _firstNumber(detail.reportData ?? const {}, const [
            'targetCaloriesDaily',
            'TargetCaloriesDaily',
          ])?.toInt() ??
          2000;
      final clientId = summary.clientId;
      if (clientId == null || clientId.isEmpty) {
        throw StateError('Thiếu mã Gymer.');
      }
      final raw = await _advancedRepository.clientSuggestions(
        clientId,
        date: selectedDate,
        targetCalories: target,
        top: 30,
      );
      candidates = raw
          .map(_AdjustmentCandidate.fromSuggestion)
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      catalogError = true;
    }
    if (!mounted) return;

    final result = await showDialog<_AdjustmentDialogResult>(
      context: context,
      builder: (_) => _MealAdjustmentDialog(
        selectedDate: selectedDate,
        isMidWeek: isMidWeek,
        sourceMeals: sourceMeals,
        candidates: candidates,
        catalogError: catalogError,
      ),
    );
    if (result == null) return;
    setState(() {
      _adjustments.add(
        MealPlanAdjustment(
          action: result.action,
          mealType: result.mealType,
          plannedDate: selectedDate,
          itemId: result.existingItemId,
          foodId: result.foodId,
          recipeId: result.recipeId,
          targetCalories: result.calories,
          quantityG: result.quantityG,
          ingredients: result.ingredients,
        ),
      );
    });
  }

  List<_AdjustmentSourceMeal> _sourceMealsForDate(
    Map<String, dynamic> reportData,
    DateTime date, {
    required bool keepItemId,
  }) {
    final days =
        (reportData['dailyMeals'] ?? reportData['DailyMeals']) as List? ??
        const [];
    for (final rawDay in days.whereType<Map>()) {
      final day = Map<String, dynamic>.from(rawDay);
      final parsedDate = DateTime.tryParse(
        (day['date'] ?? day['Date'] ?? '').toString(),
      );
      if (parsedDate == null || !DateUtils.isSameDay(parsedDate, date)) {
        continue;
      }
      final items =
          (day['plannedItems'] ?? day['PlannedItems']) as List? ?? const [];
      return items.whereType<Map>().map((rawItem) {
        final item = Map<String, dynamic>.from(rawItem);
        return _AdjustmentSourceMeal.fromMap(item, keepItemId: keepItemId);
      }).toList();
    }
    return const [];
  }

  void _openCreateNextPlan(
    CoachWeeklyReport summary,
    Map<String, dynamic> data,
  ) {
    final rawClientId =
        (summary.clientId != null && summary.clientId!.isNotEmpty)
        ? summary.clientId
        : (data['clientId'] ??
                  data['ClientId'] ??
                  data['userId'] ??
                  data['UserId'])
              ?.toString();

    if (rawClientId == null || rawClientId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text(
            'Không tìm thấy thông tin Gymer (clientId) để tạo lộ trình.',
          ),
        ),
      );
      return;
    }

    final suggestedCal =
        summary.suggestedCalorieTarget ??
        _firstNumber(data, const [
          'targetCaloriesDaily',
          'TargetCaloriesDaily',
        ])?.toInt();
    final suggestedProtein = summary.suggestedProteinTarget;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachCreateMealPlanScreen(
          clientId: rawClientId.trim(),
          clientName: summary.studentName,
          initialPlanType: 'weekly',
          initialTargetCalories: suggestedCal,
          initialTargetProtein: suggestedProtein,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachReportProvider>();
    if (provider.isLoadingDetail ||
        provider.selectedDetail == null ||
        provider.selectedDetail?.summary.reportId != widget.reportId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo tuần')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.detailError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo tuần')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(provider.detailError!),
          ),
        ),
      );
    }

    final detail = provider.selectedDetail!;
    final summary = detail.summary;
    final data = detail.reportData ?? const {};
    final nutrition = _asMap(
      data['nutritionSummary'] ?? data['NutritionSummary'],
    );
    final adherence = _asMap(data['adherenceScore'] ?? data['AdherenceScore']);
    final weightLogs =
        (data['weightLogs'] ?? data['WeightLogs'] ?? const []) as List;
    final dailyMeals =
        (data['dailyMeals'] ?? data['DailyMeals'] ?? const []) as List;

    final isPartial = data['isPartial'] == true || data['IsPartial'] == true;
    final dataThroughDateStr =
        (data['dataThroughDate'] ?? data['DataThroughDate'])?.toString();
    final DateTime? dataThroughDate = dataThroughDateStr != null
        ? DateTime.tryParse(dataThroughDateStr)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Báo cáo - ${summary.studentName}'),
        actions: [
          if (!summary.isMidWeekCheckIn)
            IconButton(
              icon: const Icon(Icons.alt_route),
              tooltip: 'Tạo lộ trình tuần tiếp theo',
              onPressed: () => _openCreateNextPlan(summary, data),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (!summary.isMidWeekCheckIn) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openCreateNextPlan(summary, data),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Mở trình tạo tuần kế tiếp'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitting || !summary.isPending ? null : _submit,
                  icon: Icon(
                    summary.isPending ? Icons.send : Icons.check_circle_outline,
                  ),
                  label: Text(
                    summary.isPending ? 'Gửi đánh giá' : 'Đã đánh giá',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            summary: summary,
            isPartial: isPartial,
            dataThroughDate: dataThroughDate,
            onCreatePlan: () => _openCreateNextPlan(summary, data),
          ),
          const SizedBox(height: 16),
          _OverviewCard(
            summary: summary,
            nutrition: nutrition,
            adherence: adherence,
            reportData: data,
          ),
          const SizedBox(height: 16),
          _DailyAccordionCard(
            weekStartDate: summary.weekStartDate,
            dataThroughDate: dataThroughDate,
            dailyMealsRaw: dailyMeals,
          ),
          const SizedBox(height: 16),
          if (weightLogs.isNotEmpty) ...[
            _WeightLogsCard(
              logs: weightLogs
                  .cast<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          _ReviewForm(
            commentCtrl: _commentCtrl,
            calorieCtrl: _calorieCtrl,
            proteinCtrl: _proteinCtrl,
          ),
          const SizedBox(height: 16),
          _AdjustmentsCard(
            adjustments: _adjustments,
            onAdd: _addAdjustmentDialog,
            onRemove: (a) => setState(() => _adjustments.remove(a)),
            isMidWeek: summary.isMidWeekCheckIn,
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.summary,
    required this.isPartial,
    required this.dataThroughDate,
    required this.onCreatePlan,
  });

  final CoachWeeklyReport summary;
  final bool isPartial;
  final DateTime? dataThroughDate;
  final VoidCallback onCreatePlan;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final throughLabel = dataThroughDate != null
        ? '${dataThroughDate!.day.toString().padLeft(2, '0')}/${dataThroughDate!.month.toString().padLeft(2, '0')}'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.studentName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPartial
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPartial
                          ? Colors.orange.shade300
                          : Colors.green.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPartial ? Icons.hourglass_top : Icons.check_circle,
                        size: 14,
                        color: isPartial
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPartial
                            ? 'Tạm tính đến $throughLabel'
                            : 'Đã hoàn tất',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPartial
                              ? Colors.orange.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tuần: ${_fmt(summary.weekStartDate)} → '
              '${_fmt(summary.weekStartDate.add(const Duration(days: 6)))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: Icon(switch (summary.status) {
                    CoachReportStatus.pending => Icons.schedule,
                    CoachReportStatus.reviewed => Icons.rate_review,
                    CoachReportStatus.applied => Icons.check_circle_outline,
                    CoachReportStatus.rejected => Icons.cancel_outlined,
                  }, size: 16),
                  label: Text(switch (summary.status) {
                    CoachReportStatus.pending => 'Chờ đánh giá',
                    CoachReportStatus.reviewed => 'Đã đánh giá',
                    CoachReportStatus.applied => 'Gymer đã áp dụng',
                    CoachReportStatus.rejected => 'Gymer từ chối',
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.summary,
    required this.nutrition,
    required this.adherence,
    required this.reportData,
  });

  final CoachWeeklyReport summary;
  final Map<String, dynamic> nutrition;
  final Map<String, dynamic> adherence;
  final Map<String, dynamic> reportData;

  @override
  Widget build(BuildContext context) {
    final totalActual = _asMap(
      nutrition['totalActual'] ?? nutrition['TotalActual'],
    );
    final totalPlanned = _asMap(
      nutrition['totalPlanned'] ?? nutrition['TotalPlanned'],
    );

    final calActual =
        _firstNumber(totalActual, const ['caloriesKcal', 'CaloriesKcal']) ??
        _firstNumber(nutrition, const [
          'caloriesActual',
          'CaloriesActual',
          'actualCalories',
        ]);
    final calPlanned =
        _firstNumber(totalPlanned, const ['caloriesKcal', 'CaloriesKcal']) ??
        _firstNumber(nutrition, const [
          'caloriesPlanned',
          'CaloriesPlanned',
          'plannedCalories',
        ]);

    final proActual =
        _firstNumber(totalActual, const ['proteinG', 'ProteinG']) ??
        _firstNumber(nutrition, const [
          'proteinActualG',
          'ProteinActualG',
          'actualProtein',
        ]);
    final proPlanned =
        _firstNumber(totalPlanned, const ['proteinG', 'ProteinG']) ??
        _firstNumber(nutrition, const [
          'proteinPlannedG',
          'ProteinPlannedG',
          'plannedProtein',
        ]);

    final isPartial =
        reportData['isPartial'] == true || reportData['IsPartial'] == true;
    final dataThroughStr =
        (reportData['dataThroughDate'] ?? reportData['DataThroughDate'])
            ?.toString();
    final weekStart =
        _date(reportData['weekStartDate'] ?? reportData['WeekStartDate']) ??
        summary.weekStartDate;
    int elapsedDays = 7;
    if (isPartial && dataThroughStr != null) {
      final throughDate = DateTime.tryParse(dataThroughStr);
      if (throughDate != null) {
        elapsedDays = throughDate.difference(weekStart).inDays + 1;
        if (elapsedDays < 1) elapsedDays = 1;
        if (elapsedDays > 7) elapsedDays = 7;
      }
    }

    final calAvgDay = calActual != null ? (calActual / elapsedDays) : null;
    final proAvgDay = proActual != null ? (proActual / elapsedDays) : null;

    final overallScore =
        _firstNumber(adherence, const [
          'overallScore',
          'OverallScore',
          'score',
          'Score',
        ]) ??
        0;

    int completedMeals =
        _firstNumber(adherence, const [
          'completedMealsCount',
          'CompletedMealsCount',
        ])?.toInt() ??
        -1;
    int plannedMeals =
        _firstNumber(adherence, const [
          'plannedMealsCount',
          'PlannedMealsCount',
        ])?.toInt() ??
        -1;
    int skippedMeals =
        _firstNumber(adherence, const [
          'skippedMealsCount',
          'SkippedMealsCount',
        ])?.toInt() ??
        -1;
    int unplannedMeals =
        _firstNumber(adherence, const [
          'unplannedMealsCount',
          'UnplannedMealsCount',
        ])?.toInt() ??
        -1;

    if (completedMeals < 0 ||
        plannedMeals < 0 ||
        skippedMeals < 0 ||
        unplannedMeals < 0) {
      final dailyMeals =
          (reportData['dailyMeals'] ?? reportData['DailyMeals'] ?? const [])
              as List;
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final cutoffDateOnly = dataThroughStr != null
          ? DateTime.tryParse(dataThroughStr)
          : null;

      int compCount = 0;
      int planCount = 0;
      int skipCount = 0;
      int unplanCount = 0;

      for (final raw in dailyMeals) {
        if (raw is Map) {
          final dateStr = (raw['date'] ?? raw['Date'])?.toString();
          if (dateStr == null) continue;
          final d = DateTime.tryParse(dateStr);
          if (d == null) continue;
          final dOnly = DateTime(d.year, d.month, d.day);

          if (cutoffDateOnly != null &&
              dOnly.isAfter(
                DateTime(
                  cutoffDateOnly.year,
                  cutoffDateOnly.month,
                  cutoffDateOnly.day,
                ),
              )) {
            continue;
          }

          final plannedItems =
              ((raw['plannedItems'] ?? raw['PlannedItems']) as List? ??
              const []);
          final actualLogs =
              ((raw['actualLogs'] ?? raw['ActualLogs']) as List? ?? const []);

          for (final item in plannedItems) {
            if (item is Map) {
              final isComp =
                  item['isCompleted'] == true || item['IsCompleted'] == true;
              planCount++;
              if (isComp) {
                compCount++;
              } else if (dOnly.isBefore(todayOnly)) {
                skipCount++;
              }
            }
          }

          for (final log in actualLogs) {
            if (log is Map) {
              final linkId = log['mealPlanItemId'] ?? log['MealPlanItemId'];
              if (linkId == null || linkId.toString().isEmpty) {
                unplanCount++;
              }
            }
          }
        }
      }

      if (completedMeals < 0) completedMeals = compCount;
      if (plannedMeals < 0) plannedMeals = planCount;
      if (skippedMeals < 0) skippedMeals = skipCount;
      if (unplannedMeals < 0) unplannedMeals = unplanCount;
    }

    final checkInWeight =
        summary.checkInWeight ??
        _firstNumber(reportData, const [
          'checkInWeight',
          'CheckInWeight',
        ])?.toDouble();
    final checkInBodyFat = _firstNumber(reportData, const [
      'checkInBodyFat',
      'CheckInBodyFat',
    ])?.toDouble();
    final trainingDays =
        summary.trainingDaysCount ??
        _firstNumber(reportData, const [
          'trainingDaysCount',
          'TrainingDaysCount',
        ])?.toInt();
    final bodyFeeling =
        (reportData['bodyFeeling'] ?? reportData['BodyFeeling'] ?? '')
            ?.toString();
    final studentNote =
        (reportData['studentNote'] ?? reportData['StudentNote'] ?? '')
            ?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan dinh dưỡng & Tuân thủ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    label: 'Calo tích lũy',
                    value: calActual != null
                        ? '${calActual.toStringAsFixed(0)} kcal'
                        : '--',
                    subValue: calPlanned != null
                        ? 'Mục tiêu: ${calPlanned.toStringAsFixed(0)} kcal'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                    label: 'Đạm tích lũy',
                    value: proActual != null
                        ? '${proActual.toStringAsFixed(0)} g'
                        : '--',
                    subValue: proPlanned != null
                        ? 'Mục tiêu: ${proPlanned.toStringAsFixed(0)} g'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.today,
                    color: Colors.teal,
                    label: 'Calo TB/ngày',
                    value: calAvgDay != null
                        ? '${calAvgDay.toStringAsFixed(0)} kcal'
                        : '--',
                    subValue: 'Tính qua $elapsedDays ngày',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.pie_chart,
                    color: Colors.purple,
                    label: 'Đạm TB/ngày',
                    value: proAvgDay != null
                        ? '${proAvgDay.toStringAsFixed(0)} g'
                        : '--',
                    subValue: 'Tính qua $elapsedDays ngày',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Điểm tuân thủ:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${overallScore.toStringAsFixed(0)} / 100',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: overallScore >= 80
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (overallScore.clamp(0, 100)) / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Colors.grey.shade200,
                        color: overallScore >= 80
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatMini(
                  label: 'Bữa hoàn thành',
                  value: '$completedMeals/$plannedMeals',
                  color: Colors.green,
                ),
                _StatMini(
                  label: 'Bỏ bữa',
                  value: '$skippedMeals',
                  color: Colors.red,
                ),
                _StatMini(
                  label: 'Ngoài kế hoạch',
                  value: '$unplannedMeals',
                  color: Colors.purple,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                if (checkInWeight != null)
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.scale,
                      label: 'Cân nặng',
                      value: '${checkInWeight.toStringAsFixed(1)} kg',
                    ),
                  ),
                if (checkInBodyFat != null)
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.straighten,
                      label: 'Tỷ lệ mỡ',
                      value: '${checkInBodyFat.toStringAsFixed(1)}%',
                    ),
                  ),
                if (trainingDays != null)
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.directions_run,
                      label: 'Số buổi tập',
                      value: '$trainingDays buổi',
                    ),
                  ),
              ],
            ),
            if (bodyFeeling != null && bodyFeeling.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoItem(
                icon: Icons.mood,
                label: 'Thể trạng',
                value: bodyFeeling,
              ),
            ],
            if (studentNote != null && studentNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Ghi chú từ Gymer: "$studentNote"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyAccordionCard extends StatelessWidget {
  const _DailyAccordionCard({
    required this.weekStartDate,
    required this.dataThroughDate,
    required this.dailyMealsRaw,
  });

  final DateTime weekStartDate;
  final DateTime? dataThroughDate;
  final List dailyMealsRaw;

  static const _dayNames = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final cutoffDate = dataThroughDate ?? today;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Chi tiết 7 ngày trong tuần',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            for (int i = 0; i < 7; i++) ...[
              _buildDayExpansionTile(context, i, cutoffDate, today),
              if (i < 6) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayExpansionTile(
    BuildContext context,
    int dayOffset,
    DateTime cutoffDate,
    DateTime today,
  ) {
    final currentDate = DateTime(
      weekStartDate.year,
      weekStartDate.month,
      weekStartDate.day,
    ).add(Duration(days: dayOffset));

    final currentDateOnly = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final cutoffDateOnly = DateTime(
      cutoffDate.year,
      cutoffDate.month,
      cutoffDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);

    final isFuture = currentDateOnly.isAfter(cutoffDateOnly);

    final String dateStr =
        '${currentDate.year.toString().padLeft(4, '0')}-'
        '${currentDate.month.toString().padLeft(2, '0')}-'
        '${currentDate.day.toString().padLeft(2, '0')}';

    Map<String, dynamic>? dayData;
    for (final raw in dailyMealsRaw) {
      if (raw is Map) {
        final dStr = (raw['date'] ?? raw['Date'])?.toString();
        if (dStr != null && dStr.startsWith(dateStr)) {
          dayData = Map<String, dynamic>.from(raw);
          break;
        }
      }
    }

    final plannedItems =
        ((dayData?['plannedItems'] ?? dayData?['PlannedItems']) as List? ??
                const [])
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final actualLogs =
        ((dayData?['actualLogs'] ?? dayData?['ActualLogs']) as List? ??
                const [])
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    num dayActualCal = 0;
    for (final log in actualLogs) {
      dayActualCal +=
          _firstNumber(log, const ['caloriesKcal', 'CaloriesKcal']) ?? 0;
    }
    num dayTargetCal = 0;
    for (final item in plannedItems) {
      dayTargetCal +=
          _firstNumber(item, const ['targetCalories', 'TargetCalories']) ?? 0;
    }

    bool hasSkipped = false;
    if (!isFuture) {
      for (final item in plannedItems) {
        final isComp =
            item['isCompleted'] == true || item['IsCompleted'] == true;
        if (!isComp && currentDateOnly.isBefore(todayOnly)) {
          hasSkipped = true;
          break;
        }
      }
    }

    String statusLabel;
    Color statusBg;
    Color statusFg;

    if (isFuture) {
      statusLabel = 'Chưa đến';
      statusBg = Colors.grey.shade100;
      statusFg = Colors.grey.shade600;
    } else if (hasSkipped) {
      statusLabel = 'Có bỏ bữa';
      statusBg = Colors.orange.shade50;
      statusFg = Colors.orange.shade800;
    } else if (dayTargetCal > 0) {
      final ratio = dayActualCal / dayTargetCal;
      if (ratio >= 0.9 && ratio <= 1.1) {
        statusLabel = 'Đạt';
        statusBg = Colors.green.shade50;
        statusFg = Colors.green.shade800;
      } else if (ratio < 0.9) {
        statusLabel = 'Thiếu';
        statusBg = Colors.amber.shade50;
        statusFg = Colors.amber.shade900;
      } else {
        statusLabel = 'Vượt';
        statusBg = Colors.purple.shade50;
        statusFg = Colors.purple.shade800;
      }
    } else {
      statusLabel = dayActualCal > 0 ? 'Đạt' : 'Chưa ghi nhận';
      statusBg = dayActualCal > 0 ? Colors.green.shade50 : Colors.grey.shade100;
      statusFg = dayActualCal > 0
          ? Colors.green.shade800
          : Colors.grey.shade600;
    }

    final dayTitle =
        '${_dayNames[dayOffset]}, ${currentDate.day}/${currentDate.month}';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                dayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusFg,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          isFuture
              ? 'Chưa có dữ liệu'
              : 'Thực tế: ${dayActualCal.toStringAsFixed(0)} kcal'
                    '${dayTargetCal > 0 ? " / Kế hoạch: ${dayTargetCal.toStringAsFixed(0)} kcal" : ""}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealSlot(
                  context,
                  'Bữa sáng',
                  'breakfast',
                  plannedItems,
                  actualLogs,
                  isFuture,
                  currentDateOnly,
                  todayOnly,
                ),
                _buildMealSlot(
                  context,
                  'Bữa trưa',
                  'lunch',
                  plannedItems,
                  actualLogs,
                  isFuture,
                  currentDateOnly,
                  todayOnly,
                ),
                _buildMealSlot(
                  context,
                  'Bữa tối',
                  'dinner',
                  plannedItems,
                  actualLogs,
                  isFuture,
                  currentDateOnly,
                  todayOnly,
                ),
                _buildMealSlot(
                  context,
                  'Bữa phụ',
                  'snack',
                  plannedItems,
                  actualLogs,
                  isFuture,
                  currentDateOnly,
                  todayOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlot(
    BuildContext context,
    String slotTitle,
    String mealTypeKey,
    List<Map<String, dynamic>> plannedItems,
    List<Map<String, dynamic>> actualLogs,
    bool isFuture,
    DateTime currentDateOnly,
    DateTime todayOnly,
  ) {
    final itemsForSlot = plannedItems
        .where(
          (i) =>
              _normalizeMealType(i['mealType'] ?? i['MealType']) == mealTypeKey,
        )
        .toList();
    final logsForSlot = actualLogs
        .where(
          (l) =>
              _normalizeMealType(l['mealType'] ?? l['MealType']) == mealTypeKey,
        )
        .toList();
    final plannedItemIds = plannedItems
        .map((item) => (item['id'] ?? item['Id'])?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final standaloneLogsForSlot = logsForSlot.where((log) {
      final linkId = (log['mealPlanItemId'] ?? log['MealPlanItemId'])
          ?.toString();
      return linkId == null ||
          linkId.isEmpty ||
          !plannedItemIds.contains(linkId);
    }).toList();

    if (itemsForSlot.isEmpty && standaloneLogsForSlot.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slotTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 4),
          ...itemsForSlot.map((item) {
            final itemId = (item['id'] ?? item['Id'])?.toString();
            Map<String, dynamic>? linkedLog;
            if (itemId != null && itemId.isNotEmpty) {
              // A linked log belongs to its planned item even when the user later
              // corrects the log's meal type. Search the whole day, not this slot.
              for (final log in actualLogs) {
                final linkId = (log['mealPlanItemId'] ?? log['MealPlanItemId'])
                    ?.toString();
                if (linkId == itemId) {
                  linkedLog = log;
                  break;
                }
              }
            }
            return _buildPlannedItemTile(
              context,
              item,
              linkedLog,
              isFuture,
              currentDateOnly,
              todayOnly,
            );
          }),
          ...standaloneLogsForSlot.map(
            (log) => _buildActualLogTile(context, log),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannedItemTile(
    BuildContext context,
    Map<String, dynamic> item,
    Map<String, dynamic>? linkedLog,
    bool isFuture,
    DateTime currentDateOnly,
    DateTime todayOnly,
  ) {
    final plannedName =
        (item['foodName'] ??
                item['FoodName'] ??
                item['recipeName'] ??
                item['RecipeName'] ??
                item['customName'] ??
                'Món ăn trong kế hoạch')
            ?.toString();
    final plannedFoodId = (item['foodId'] ?? item['FoodId'])?.toString();
    final plannedRecipeId = (item['recipeId'] ?? item['RecipeId'])?.toString();
    final plannedQuantity = _firstNumber(item, const [
      'quantityG',
      'QuantityG',
    ]);
    final plannedCal = _firstNumber(item, const [
      'targetCalories',
      'TargetCalories',
      'caloriesKcal',
      'CaloriesKcal',
    ]);
    final plannedProtein = _firstNumber(item, const ['proteinG', 'ProteinG']);

    final actualName = linkedLog == null
        ? null
        : (linkedLog['foodName'] ??
                  linkedLog['FoodName'] ??
                  linkedLog['recipeName'] ??
                  linkedLog['RecipeName'] ??
                  linkedLog['customName'])
              ?.toString();
    final actualFoodId = linkedLog == null
        ? null
        : (linkedLog['foodId'] ?? linkedLog['FoodId'])?.toString();
    final actualRecipeId = linkedLog == null
        ? null
        : (linkedLog['recipeId'] ?? linkedLog['RecipeId'])?.toString();
    final actualQuantity = linkedLog != null
        ? _firstNumber(linkedLog, const ['quantityG', 'QuantityG'])
        : null;
    final actualCal = linkedLog != null
        ? _firstNumber(linkedLog, const ['caloriesKcal', 'CaloriesKcal'])
        : null;
    final actualProtein = linkedLog != null
        ? _firstNumber(linkedLog, const ['proteinG', 'ProteinG'])
        : null;

    final isCompleted =
        item['isCompleted'] == true ||
        item['IsCompleted'] == true ||
        linkedLog != null;
    final displayName =
        linkedLog != null && actualName != null && actualName.isNotEmpty
        ? actualName
        : plannedName;
    final detailFoodId = linkedLog != null ? actualFoodId : plannedFoodId;
    final detailRecipeId = linkedLog != null ? actualRecipeId : plannedRecipeId;

    final displayQty = actualQuantity ?? plannedQuantity;
    final displayCal = actualCal ?? plannedCal;
    final displayProtein = actualProtein ?? plannedProtein;

    final primarySubtitle =
        '${displayQty != null ? "${displayQty.toStringAsFixed(0)}g • " : ""}'
        '${displayCal != null ? "${displayCal.toStringAsFixed(0)} kcal" : ""}'
        '${displayProtein != null ? " • ${displayProtein.toStringAsFixed(1)}g đạm" : ""}';

    final hasDifference =
        linkedLog != null &&
        (_textDiffers(actualName, plannedName) ||
            _textDiffers(actualFoodId, plannedFoodId) ||
            _textDiffers(actualRecipeId, plannedRecipeId) ||
            _numbersDiffer(actualQuantity, plannedQuantity) ||
            _numbersDiffer(actualCal, plannedCal) ||
            _numbersDiffer(actualProtein, plannedProtein));
    final secondarySubtitle = hasDifference
        ? 'Kế hoạch: ${plannedName ?? "Món ăn"}'
              '${plannedQuantity != null ? " • ${plannedQuantity.toStringAsFixed(0)}g" : ""}'
              '${plannedCal != null ? " • ${plannedCal.toStringAsFixed(0)} kcal" : ""}'
              '${plannedProtein != null ? " • ${plannedProtein.toStringAsFixed(1)}g đạm" : ""}'
        : null;

    String badgeLabel;
    Color badgeBg;
    Color badgeFg;

    if (isFuture) {
      badgeLabel = 'Chưa đến';
      badgeBg = Colors.grey.shade100;
      badgeFg = Colors.grey.shade600;
    } else if (isCompleted) {
      badgeLabel = 'Đã ăn';
      badgeBg = Colors.green.shade50;
      badgeFg = Colors.green.shade800;
    } else if (currentDateOnly.isBefore(todayOnly)) {
      badgeLabel = 'Bỏ bữa';
      badgeBg = Colors.red.shade50;
      badgeFg = Colors.red.shade800;
    } else {
      badgeLabel = 'Chưa ghi nhận';
      badgeBg = Colors.amber.shade50;
      badgeFg = Colors.amber.shade900;
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 20,
        ),
        title: Text(
          displayName ?? 'Món ăn',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(primarySubtitle, style: const TextStyle(fontSize: 11.5)),
            if (secondarySubtitle != null)
              Text(
                secondarySubtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              color: badgeFg,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _openItemDetail(context, detailFoodId, detailRecipeId),
      ),
    );
  }

  Widget _buildActualLogTile(BuildContext context, Map<String, dynamic> log) {
    final foodName =
        (log['foodName'] ??
                log['FoodName'] ??
                log['recipeName'] ??
                log['RecipeName'] ??
                log['customName'] ??
                'Món ăn ngoài kế hoạch')
            ?.toString();
    final quantity = _firstNumber(log, const ['quantityG', 'QuantityG']);
    final cal = _firstNumber(log, const ['caloriesKcal', 'CaloriesKcal']);
    final protein = _firstNumber(log, const ['proteinG', 'ProteinG']);

    final foodId = (log['foodId'] ?? log['FoodId'])?.toString();
    final recipeId = (log['recipeId'] ?? log['RecipeId'])?.toString();

    return Card(
      elevation: 0,
      color: Colors.blue.shade50.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: const Icon(
          Icons.add_circle_outline,
          color: Colors.blue,
          size: 20,
        ),
        title: Text(
          foodName ?? 'Món ghi nhận',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${quantity != null ? "${quantity.toStringAsFixed(0)}g • " : ""}'
          '${cal != null ? "${cal.toStringAsFixed(0)} kcal" : ""}'
          '${protein != null ? " • ${protein.toStringAsFixed(1)}g đạm" : ""}',
          style: const TextStyle(fontSize: 11.5),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Ngoài kế hoạch',
            style: TextStyle(
              color: Colors.purple.shade800,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _openItemDetail(context, foodId, recipeId),
      ),
    );
  }

  void _openItemDetail(BuildContext context, String? foodId, String? recipeId) {
    if (foodId != null && foodId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(name: '/foods/$foodId'),
          builder: (_) => FoodDetailScreen(foodId: foodId),
        ),
      );
    } else if (recipeId != null && recipeId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(name: '/recipes/$recipeId'),
          builder: (_) => RecipeDetailScreen(recipeId: recipeId),
        ),
      );
    }
  }

  static String _normalizeMealType(dynamic raw) {
    final str = (raw ?? '').toString().trim().toLowerCase();
    switch (str) {
      case 'breakfast':
      case 'bữa sáng':
      case 'bua sang':
        return 'breakfast';
      case 'lunch':
      case 'bữa trưa':
      case 'bua trua':
        return 'lunch';
      case 'dinner':
      case 'bữa tối':
      case 'bua toi':
        return 'dinner';
      default:
        return 'snack';
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (subValue != null)
            Text(
              subValue!,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Colors.black54),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightLogsCard extends StatelessWidget {
  const _WeightLogsCard({required this.logs});
  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cân nặng ghi nhận trong tuần',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...logs.map((l) {
              final kg =
                  _firstNumber(l, const [
                    'weightKg',
                    'WeightKg',
                  ])?.toStringAsFixed(1) ??
                  '--';
              final fat = _firstNumber(l, const [
                'bodyFatPercent',
                'BodyFatPercent',
              ]);
              final recorded = (l['recordedAt'] ?? l['RecordedAt'] ?? '')
                  .toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.scale, color: Colors.teal),
                title: Text(
                  '$kg kg${fat != null ? " (Mỡ: ${fat.toStringAsFixed(1)}%)" : ""}',
                ),
                subtitle: Text(recorded),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.commentCtrl,
    required this.calorieCtrl,
    required this.proteinCtrl,
  });
  final TextEditingController commentCtrl;
  final TextEditingController calorieCtrl;
  final TextEditingController proteinCtrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: Colors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh giá & Khuyến nghị của PT',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Nhập ý kiến chuyên môn và chỉ số khuyến nghị',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText: 'Nhận xét cho học viên *',
                hintText:
                    'Nhận xét chi tiết về dinh dưỡng, tập luyện tuần qua...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.edit_note_rounded, color: Colors.teal),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: calorieCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Calo đề xuất',
                      hintText: '2000',
                      prefixIcon: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.deepOrangeAccent,
                      ),
                      suffixText: 'kcal',
                      suffixStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: proteinCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Đạm đề xuất',
                      hintText: '140',
                      prefixIcon: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.teal,
                      ),
                      suffixText: 'g',
                      suffixStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentsCard extends StatelessWidget {
  const _AdjustmentsCard({
    required this.adjustments,
    required this.onAdd,
    required this.onRemove,
    required this.isMidWeek,
  });
  final List<MealPlanAdjustment> adjustments;
  final VoidCallback onAdd;
  final void Function(MealPlanAdjustment) onRemove;
  final bool isMidWeek;

  String _mealTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return type;
    }
  }

  Color _actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return Colors.green.shade700;
      case 'replace':
        return Colors.orange.shade700;
      case 'remove':
        return Colors.red.shade600;
      default:
        return Colors.teal;
    }
  }

  String _actionText(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return 'THÊM';
      case 'replace':
        return 'THAY THẾ';
      case 'remove':
        return 'XÓA';
      default:
        return action.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điều chỉnh lộ trình đề xuất',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isMidWeek
                            ? 'Chỉ thay đổi món từ Thứ Sáu đến Chủ nhật'
                            : 'Chuẩn bị món cho tuần kế tiếp',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.withValues(alpha: 0.12),
                    foregroundColor: Colors.teal.shade800,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (adjustments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.checklist_rtl_rounded,
                      size: 40,
                      color: Colors.teal.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có điều chỉnh nào',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMidWeek
                          ? 'Bấm "Thêm" để chọn đúng món hiện tại và món thay thế.'
                          : 'Bản nháp tuần mới được sao chép tự động; các mục ở đây là thay đổi bổ sung.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adjustments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final a = adjustments[index];
                  final actionColor = _actionColor(a.action);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _actionText(a.action),
                            style: TextStyle(
                              color: actionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _mealTypeName(a.mealType),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (a.targetCalories != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${a.targetCalories} kcal',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a.plannedDate.day}/${a.plannedDate.month}/${a.plannedDate.year}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          tooltip: 'Xóa điều chỉnh',
                          onPressed: () => onRemove(a),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MealAdjustmentDialog extends StatefulWidget {
  const _MealAdjustmentDialog({
    required this.selectedDate,
    required this.isMidWeek,
    required this.sourceMeals,
    required this.candidates,
    required this.catalogError,
  });

  final DateTime selectedDate;
  final bool isMidWeek;
  final List<_AdjustmentSourceMeal> sourceMeals;
  final List<_AdjustmentCandidate> candidates;
  final bool catalogError;

  @override
  State<_MealAdjustmentDialog> createState() => _MealAdjustmentDialogState();
}

class _MealAdjustmentDialogState extends State<_MealAdjustmentDialog> {
  String _action = 'add';
  String _mealType = 'breakfast';
  _AdjustmentSourceMeal? _source;
  _AdjustmentCandidate? _candidate;
  late final TextEditingController _calorieController;
  final AdvancedRepository _repository = AdvancedRepository();
  final List<_EditableIngredientPortion> _ingredients = [];
  bool _loadingIngredients = false;
  String? _ingredientError;

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController();
    if (widget.sourceMeals.isNotEmpty) {
      _mealType = widget.sourceMeals.first.mealType;
    }
  }

  @override
  void dispose() {
    _calorieController.dispose();
    for (final item in _ingredients) {
      item.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectCandidate(_AdjustmentCandidate? value) async {
    for (final item in _ingredients) {
      item.controller.dispose();
    }
    setState(() {
      _candidate = value;
      _ingredients.clear();
      _ingredientError = null;
      _loadingIngredients = value?.recipeId != null;
      if (value?.calories != null) {
        _calorieController.text = '${value!.calories}';
      } else {
        _calorieController.clear();
      }
    });

    if (value?.recipeId == null) return;
    try {
      final recipe = await _repository.recipeDetail(value!.recipeId!);
      final servings =
          (_firstNumber(recipe, const ['servings', 'Servings']) ?? 1)
              .clamp(1, 100)
              .toDouble();
      final raw = recipe['ingredients'] ?? recipe['Ingredients'];
      final parsed = raw is List
          ? raw
                .whereType<Map>()
                .map((entry) {
                  final map = Map<String, dynamic>.from(entry);
                  return _EditableIngredientPortion.fromMap(map, servings);
                })
                .where((item) => item.ingredientId.isNotEmpty)
                .toList()
          : <_EditableIngredientPortion>[];
      if (!mounted) {
        for (final item in parsed) {
          item.controller.dispose();
        }
        return;
      }
      setState(() {
        _ingredients.addAll(parsed);
        _loadingIngredients = false;
        if (_ingredients.isEmpty) {
          _ingredientError =
              'Công thức chưa có định lượng nguyên liệu để điều chỉnh.';
        }
        _refreshNutritionPreview();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingIngredients = false;
        _ingredientError =
            'Không tải được định lượng nguyên liệu của công thức.';
      });
    }
  }

  void _refreshNutritionPreview() {
    if (_ingredients.isEmpty) return;
    final calories = _ingredients.fold<double>(
      0,
      (sum, item) => sum + item.caloriesForCurrentQuantity,
    );
    _calorieController.text = calories.round().toString();
  }

  List<_AdjustmentSourceMeal> get _visibleSources =>
      widget.sourceMeals.where((item) => item.mealType == _mealType).toList();

  void _submit() {
    if ((_action == 'replace' || _action == 'remove') && _source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Hãy chọn món đang có trong lộ trình.'),
        ),
      );
      return;
    }
    if ((_action == 'add' || _action == 'replace') && _candidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Hãy chọn món mới.'),
        ),
      );
      return;
    }
    if (_loadingIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Đang tải định lượng nguyên liệu.'),
        ),
      );
      return;
    }
    if (_ingredients.any((item) => item.quantity <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Định lượng nguyên liệu phải lớn hơn 0.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _AdjustmentDialogResult(
        action: _action,
        mealType: _mealType,
        existingItemId: _source?.itemId,
        foodId: _candidate?.foodId,
        recipeId: _candidate?.recipeId,
        calories:
            int.tryParse(_calorieController.text.trim()) ??
            _candidate?.calories,
        quantityG: _ingredients.isEmpty
            ? _candidate?.quantityG
            : _ingredients
                  .where((item) => item.isMassOrVolume)
                  .fold<double>(0, (sum, item) => sum + item.quantity),
        ingredients: _ingredients
            .map(
              (item) => MealPlanIngredientPortion(
                ingredientId: item.ingredientId,
                quantity: item.quantity,
                unit: item.unit,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.selectedDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Điều chỉnh lộ trình đề xuất',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isMidWeek
                    ? 'Giữa tuần • $dateLabel'
                    : 'Tuần kế tiếp • $dateLabel',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _action,
                decoration: const InputDecoration(labelText: 'Hành động'),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Thêm món')),
                  DropdownMenuItem(value: 'replace', child: Text('Thay món')),
                  DropdownMenuItem(value: 'remove', child: Text('Bỏ món')),
                ],
                onChanged: (value) => setState(() {
                  _action = value ?? 'add';
                  _source = null;
                  _candidate = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _mealType,
                decoration: const InputDecoration(labelText: 'Bữa ăn'),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                  DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                  DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                  DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                ],
                onChanged: (value) => setState(() {
                  _mealType = value ?? 'breakfast';
                  _source = null;
                }),
              ),
              if (_action == 'replace' || _action == 'remove') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<_AdjustmentSourceMeal>(
                  key: ValueKey('source-$_mealType-${_source?.itemId}'),
                  initialValue: _source,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.isMidWeek
                        ? 'Món hiện tại cần xử lý'
                        : 'Món dự kiến từ tuần trước',
                  ),
                  items: _visibleSources
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _source = value),
                ),
                if (_visibleSources.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Ngày/bữa này chưa có món trong lộ trình để thay hoặc bỏ.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
              if (_action == 'add' || _action == 'replace') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<_AdjustmentCandidate>(
                  key: ValueKey('candidate-${_candidate?.id}'),
                  initialValue: _candidate,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Món mới'),
                  items: widget.candidates
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            '${item.name}${item.calories == null ? '' : ' • ${item.calories} kcal'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _selectCandidate,
                ),
                if (widget.catalogError || widget.candidates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Không tải được món phù hợp. Hãy kiểm tra cấu hình kcal hoặc thử lại.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
              if (_loadingIngredients) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_ingredientError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _ingredientError!,
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
              if (_ingredients.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Điều chỉnh định lượng nguyên liệu',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._ingredients.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name)),
                        SizedBox(
                          width: 105,
                          child: TextField(
                            controller: item.controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              isDense: true,
                              suffixText: item.unit,
                            ),
                            onChanged: (_) =>
                                setState(_refreshNutritionPreview),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_action != 'remove') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _calorieController,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calo dự tính',
                    suffixText: 'kcal',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Thêm vào danh sách'),
        ),
      ],
    );
  }
}

class _AdjustmentSourceMeal {
  const _AdjustmentSourceMeal({
    required this.name,
    required this.mealType,
    this.itemId,
  });

  final String name;
  final String mealType;
  final String? itemId;

  factory _AdjustmentSourceMeal.fromMap(
    Map<String, dynamic> map, {
    required bool keepItemId,
  }) {
    final foodName = (map['foodName'] ?? map['FoodName'])?.toString();
    final recipeName = (map['recipeName'] ?? map['RecipeName'])?.toString();
    return _AdjustmentSourceMeal(
      name: foodName?.isNotEmpty == true
          ? foodName!
          : recipeName?.isNotEmpty == true
          ? recipeName!
          : 'Món chưa có tên',
      mealType: _normalizeAdjustmentMealType(
        map['mealType'] ?? map['MealType'],
      ),
      itemId: keepItemId ? (map['id'] ?? map['Id'])?.toString() : null,
    );
  }
}

class _AdjustmentCandidate {
  const _AdjustmentCandidate({
    required this.id,
    required this.name,
    this.foodId,
    this.recipeId,
    this.calories,
    this.quantityG,
  });

  final String id;
  final String name;
  final String? foodId;
  final String? recipeId;
  final int? calories;
  final double? quantityG;

  factory _AdjustmentCandidate.fromSuggestion(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['Id'] ?? '').toString();
    final type = (map['type'] ?? map['Type'] ?? '').toString().toLowerCase();
    return _AdjustmentCandidate(
      id: id,
      name: (map['name'] ?? map['Name'] ?? 'Món ăn').toString(),
      foodId: type == 'recipe' ? null : id,
      recipeId: type == 'recipe' ? id : null,
      calories: _firstNumber(map, const [
        'caloriesKcal',
        'CaloriesKcal',
      ])?.toInt(),
      quantityG: _firstNumber(map, const [
        'quantityG',
        'QuantityG',
      ])?.toDouble(),
    );
  }
}

class _EditableIngredientPortion {
  _EditableIngredientPortion({
    required this.ingredientId,
    required this.name,
    required this.unit,
    required this.basisQuantity,
    required this.caloriesPerBasis,
    required double quantity,
  }) : controller = TextEditingController(text: _formatQuantity(quantity));

  final String ingredientId;
  final String name;
  final String unit;
  final double basisQuantity;
  final double caloriesPerBasis;
  final TextEditingController controller;

  double get quantity => double.tryParse(controller.text.trim()) ?? 0;
  bool get isMassOrVolume {
    final value = unit.trim().toLowerCase();
    return value == 'g' || value == 'gram' || value == 'ml';
  }

  double get caloriesForCurrentQuantity =>
      basisQuantity <= 0 ? 0 : caloriesPerBasis * quantity / basisQuantity;

  factory _EditableIngredientPortion.fromMap(
    Map<String, dynamic> map,
    double servings,
  ) {
    final quantity =
        (_firstNumber(map, const ['quantity', 'Quantity'])?.toDouble() ?? 0) /
        servings;
    return _EditableIngredientPortion(
      ingredientId: (map['ingredientId'] ?? map['IngredientId'] ?? '')
          .toString(),
      name: (map['ingredientName'] ?? map['IngredientName'] ?? 'Nguyên liệu')
          .toString(),
      unit: (map['unit'] ?? map['Unit'] ?? 'g').toString(),
      basisQuantity:
          _firstNumber(map, const [
            'nutritionBasisQuantity',
            'NutritionBasisQuantity',
          ])?.toDouble() ??
          100,
      caloriesPerBasis:
          _firstNumber(map, const [
            'caloriesKcal',
            'CaloriesKcal',
          ])?.toDouble() ??
          0,
      quantity: quantity,
    );
  }

  static String _formatQuantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

String _normalizeAdjustmentMealType(dynamic raw) {
  switch ((raw ?? '').toString().trim().toLowerCase()) {
    case 'breakfast':
    case 'bữa sáng':
      return 'breakfast';
    case 'lunch':
    case 'bữa trưa':
      return 'lunch';
    case 'dinner':
    case 'bữa tối':
      return 'dinner';
    default:
      return 'snack';
  }
}

class _AdjustmentDialogResult {
  _AdjustmentDialogResult({
    required this.action,
    required this.mealType,
    this.existingItemId,
    this.foodId,
    this.recipeId,
    this.calories,
    this.quantityG,
    this.ingredients = const [],
  });
  final String action;
  final String mealType;
  final String? existingItemId;
  final String? foodId;
  final String? recipeId;
  final int? calories;
  final double? quantityG;
  final List<MealPlanIngredientPortion> ingredients;
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const {};
}

bool _textDiffers(String? actual, String? planned) {
  final actualValue = actual?.trim();
  final plannedValue = planned?.trim();
  if (actualValue == null ||
      actualValue.isEmpty ||
      plannedValue == null ||
      plannedValue.isEmpty) {
    return false;
  }
  return actualValue.toLowerCase() != plannedValue.toLowerCase();
}

bool _numbersDiffer(num? actual, num? planned) {
  return actual != null && planned != null && actual != planned;
}

num? _firstNumber(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is num) return v;
    if (v is String) {
      final parsed = num.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

DateTime? _date(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
