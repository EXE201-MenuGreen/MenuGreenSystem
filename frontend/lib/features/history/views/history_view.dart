import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/history_models.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../../tracking/widgets/meal_log_edit_sheet.dart';
import '../../tracking/widgets/dashboard_range_selector.dart';
import '../../tracking/widgets/daily_summary_card.dart';
import '../../tracking/widgets/calorie_trend_chart.dart';
import '../../tracking/widgets/weight_log_sheet.dart';
import '../../tracking/widgets/weight_trend_chart.dart';
import '../../tracking/widgets/calendar_heatmap_legend.dart';
import '../../tracking/utils/nutrition_warning_utils.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_templates/repositories/meal_template_repository.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key, this.onTrackingUpdated, this.initialDate});

  final VoidCallback? onTrackingUpdated;
  final DateTime? initialDate;

  @override
  State<HistoryView> createState() => HistoryViewState();
}

class HistoryViewState extends State<HistoryView> {
  DateTime _focusedMonth = DateTime(2023, 10, 1);
  DateTime _selectedDate = DateTime(2023, 10, 5);
  String _searchQuery = '';
  MealCategory? _mealFilter;
  final _repository = NutritionTrackingRepository();
  final _mealTemplateRepository = MealTemplateRepository();
  MealDaySummary? _dailySummary;
  NutritionDashboard? _dashboard;
  bool _loading = false;
  DashboardRange _dashboardRange = DashboardRange.week;
  Map<String, double?> _monthGoalByDate = {};

  static const _monthNames = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  List<HistoryTimelineSection> get _sections {
    var sections = _buildSectionsFromSummary(_effectiveSummary);

    if (_mealFilter != null) {
      sections = sections.where((s) => s.category == _mealFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      sections = sections
          .map((section) {
            final meals = section.meals
                .where((m) => m.title.toLowerCase().contains(q))
                .toList();
            if (meals.isEmpty) return null;
            return HistoryTimelineSection(
              category: section.category,
              time: section.time,
              meals: meals,
              isHighlighted: section.isHighlighted,
            );
          })
          .whereType<HistoryTimelineSection>()
          .toList();
    }

    return sections;
  }

  MealDaySummary? get _effectiveSummary {
    if (_dashboardRange == DashboardRange.day) {
      return _dailySummary;
    }
    final days = _dashboard?.days ?? [];
    if (days.isEmpty) return _dailySummary;

    final count = days.length;
    final totalCal = days.fold<double>(0, (sum, d) => sum + d.totalCalories);
    final totalTargetCal = days.fold<double>(0, (sum, d) => sum + d.targetCalories);
    final totalProt = days.fold<double>(0, (sum, d) => sum + d.totalProteinG);
    final totalTargetProt = days.fold<double>(0, (sum, d) => sum + d.targetProteinG);
    final totalCarb = days.fold<double>(0, (sum, d) => sum + d.totalCarbsG);
    final totalTargetCarb = days.fold<double>(0, (sum, d) => sum + d.targetCarbsG);
    final totalFat = days.fold<double>(0, (sum, d) => sum + d.totalFatG);
    final totalTargetFat = days.fold<double>(0, (sum, d) => sum + d.targetFatG);
    final allLogs = days.expand((d) => d.mealLogs).toList();

    return MealDaySummary(
      date: _dashboardRange == DashboardRange.week ? 'Tuần' : 'Tháng',
      totalCalories: count > 0 ? totalCal / count : 0,
      targetCalories: count > 0 ? totalTargetCal / count : 0,
      totalProteinG: count > 0 ? totalProt / count : 0,
      targetProteinG: count > 0 ? totalTargetProt / count : 0,
      totalCarbsG: count > 0 ? totalCarb / count : 0,
      targetCarbsG: count > 0 ? totalTargetCarb / count : 0,
      totalFatG: count > 0 ? totalFat / count : 0,
      targetFatG: count > 0 ? totalTargetFat / count : 0,
      goalCompletionPercent: totalTargetCal > 0 ? (totalCal / totalTargetCal * 100) : null,
      mealLogs: allLogs,
    );
  }

  String get _summaryCardTitle {
    switch (_dashboardRange) {
      case DashboardRange.day:
        return 'Tiến độ ngày ${_selectedDate.day}/${_selectedDate.month}';
      case DashboardRange.week:
        final days = _dashboard?.days ?? [];
        if (days.isNotEmpty) {
          final startStr = _formatShortDateStr(days.first.date);
          final endStr = _formatShortDateStr(days.last.date);
          return 'Tiến độ tuần ($startStr - $endStr)';
        }
        return 'Tiến độ tuần này';
      case DashboardRange.month:
        return 'Tiến độ tháng ${_focusedMonth.month}/${_focusedMonth.year}';
    }
  }

  String _formatShortDateStr(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadData();
  }

  Future<void> reloadData() => _loadData();

  void _notifyTrackingUpdated() => widget.onTrackingUpdated?.call();

  List<HistoryTimelineSection> _buildSectionsFromSummary(MealDaySummary? summary) {
    if (summary == null || summary.mealLogs.isEmpty) return [];

    final grouped = <MealCategory, List<MealLogItem>>{};
    for (final log in summary.mealLogs) {
      final category = _mapMealType(log.mealType);
      grouped.putIfAbsent(category, () => []).add(log);
    }

    final sections = <HistoryTimelineSection>[];
    for (final entry in grouped.entries) {
      final logs = entry.value;
      logs.sort((a, b) {
        final aTime = a.loggedAt ?? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
        final bTime = b.loggedAt ?? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
        return aTime.compareTo(bTime);
      });
      final firstTime = logs.first.loggedAt;
      final sectionTime = firstTime == null
          ? const TimeOfDay(hour: 12, minute: 0)
          : TimeOfDay(hour: firstTime.hour, minute: firstTime.minute);

      sections.add(
        HistoryTimelineSection(
          category: entry.key,
          time: sectionTime,
          isHighlighted: entry.key == MealCategory.breakfast,
          meals: logs
              .map(
                (item) => HistoryMealEntry(
                  id: item.id,
                  title: item.displayName,
                  calories: item.caloriesKcal.toInt(),
                  portion: item.isRecipe
                      ? '${item.quantityG.toStringAsFixed(0)}% phần'
                      : '${item.quantityG.toStringAsFixed(0)}g',
                  time: item.loggedAt == null
                      ? sectionTime
                      : TimeOfDay(hour: item.loggedAt!.hour, minute: item.loggedAt!.minute),
                  category: entry.key,
                  foodId: item.foodId,
                  recipeId: item.recipeId,
                  isRecipe: item.isRecipe,
                ),
              )
              .toList(),
        ),
      );
    }

    sections.sort((a, b) => _categoryOrder(a.category).compareTo(_categoryOrder(b.category)));
    return sections;
  }

  MealCategory _mapMealType(String mealType) {
    switch (mealType.trim().toLowerCase()) {
      case 'breakfast':
      case 'bữa sáng':
        return MealCategory.breakfast;
      case 'lunch':
      case 'bữa trưa':
        return MealCategory.lunch;
      case 'dinner':
      case 'bữa tối':
        return MealCategory.dinner;
      default:
        return MealCategory.snack;
    }
  }

  int _categoryOrder(MealCategory category) {
    switch (category) {
      case MealCategory.breakfast:
        return 0;
      case MealCategory.lunch:
        return 1;
      case MealCategory.dinner:
        return 2;
      case MealCategory.snack:
        return 3;
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repository.getDailySummary(_selectedDate).timeout(const Duration(seconds: 25)),
        _repository.getDashboard(range: _dashboardRange.apiValue).timeout(const Duration(seconds: 25)),
        _fetchMonthGoalMap(),
      ]);
      if (!mounted) return;
      setState(() {
        _dailySummary = results[0] as MealDaySummary?;
        _dashboard = results[1] as NutritionDashboard?;
        _monthGoalByDate = results[2] as Map<String, double?>;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được lịch sử. Thử lại sau.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, double?>> _fetchMonthGoalMap() async {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final today = DateTime.now();
    final end = lastInMonth.isAfter(DateTime(today.year, today.month, today.day))
        ? DateTime(today.year, today.month, today.day)
        : lastInMonth;

    final dash = await _repository
        .getDashboard(range: 'month', startDate: first, endDate: end)
        .timeout(const Duration(seconds: 25));

    final map = <String, double?>{};
    for (final day in dash?.days ?? []) {
      map[day.date] = NutritionHeatmapColors.goalPercentForDay(day);
    }
    return map;
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _onDashboardRangeChanged(DashboardRange range) {
    if (_dashboardRange == range) return;
    setState(() => _dashboardRange = range);
    _loadData();
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
    _loadData();
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _loadData();
  }

  Future<void> _addWeightLog() async {
    final ok = await showWeightLogSheet(
      context,
      recordedAt: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
    );
    if (!ok) {
      _showSnack('Không thể lưu cân nặng', isError: true);
      return;
    }
    _showSnack('Đã lưu cân nặng');
    _notifyTrackingUpdated();
    await _loadData();
  }

  Future<void> _editWeightLog(WeightLogItem log) async {
    final ok = await showWeightLogSheet(context, existing: log);
    if (!ok) {
      _showSnack('Không thể cập nhật cân nặng', isError: true);
      return;
    }
    _showSnack('Đã cập nhật cân nặng');
    _notifyTrackingUpdated();
    await _loadData();
  }

  Future<void> _deleteWeightLog(WeightLogItem log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cân nặng'),
        content: const Text('Bạn có chắc muốn xóa mục này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _repository.deleteWeightLog(log.id);
    if (!ok) {
      _showSnack('Xóa thất bại', isError: true);
      return;
    }
    _showSnack('Đã xóa cân nặng');
    _notifyTrackingUpdated();
    await _loadData();
  }

  Future<void> _addMealLog() async {
    String sourceType = 'food';
    String mealType = 'breakfast';
    final quantityController = TextEditingController(text: '100');
    final keywordController = TextEditingController();
    List<CatalogItem> items = [];
    String? selectedId;
    bool loadingItems = false;

    Future<void> loadItems(StateSetter setModalState) async {
      setModalState(() => loadingItems = true);
      final keyword = keywordController.text.trim();
      final loaded = sourceType == 'food'
          ? await _repository.getFoods(keyword: keyword)
          : await _repository.getRecipes(keyword: keyword);
      setModalState(() {
        items = loaded;
        loadingItems = false;
        if (selectedId != null && !items.any((e) => e.id == selectedId)) {
          selectedId = null;
        }
      });
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Thêm nhật ký bữa ăn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Nguồn'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sourceType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'food', child: Text('Món ăn (Food)')),
                        DropdownMenuItem(value: 'recipe', child: Text('Công thức (Recipe)')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          sourceType = value;
                          selectedId = null;
                          items = [];
                        });
                        loadItems(setModalState);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keywordController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm',
                    hintText: 'Nhập từ khóa rồi bấm tải danh sách',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => loadItems(setModalState),
                    child: const Text('Tải danh sách'),
                  ),
                ),
                if (loadingItems)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: sourceType == 'food' ? 'Chọn món ăn' : 'Chọn công thức',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedId,
                        isExpanded: true,
                        items: items
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(
                                  e.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setModalState(() => selectedId = value),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Loại bữa'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: mealType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                        DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                        DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                        DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => mealType = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sourceType == 'recipe'
                        ? 'Phần ăn (100 = 1 khẩu phần)'
                        : 'Khối lượng (gram)',
                    hintText: sourceType == 'recipe' ? 'Ví dụ: 100' : 'Ví dụ: 150',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final quantity = double.tryParse(quantityController.text.trim());
    if (selectedId == null || selectedId!.isEmpty) {
      _showSnack('Vui lòng chọn món ăn/công thức', isError: true);
      return;
    }
    if (quantity == null || quantity <= 0) {
      _showSnack('Khối lượng không hợp lệ', isError: true);
      return;
    }

    final loggedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );
    final ok = await _repository.createMealLog(
      foodId: sourceType == 'food' ? selectedId : null,
      recipeId: sourceType == 'recipe' ? selectedId : null,
      mealType: mealType,
      quantityG: quantity,
      loggedAt: loggedAt,
    );
    if (!ok) {
      _showSnack('Không thể thêm nhật ký bữa ăn', isError: true);
      return;
    }
    _showSnack('Đã thêm nhật ký bữa ăn');
    _notifyTrackingUpdated();
    await _loadData();
  }

  Future<void> _openMealDetail(HistoryMealEntry meal) async {
    final recipeId = meal.recipeId?.trim();
    if (recipeId != null && recipeId.isNotEmpty && recipeId.toLowerCase() != 'null') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: recipeId),
        ),
      );
      return;
    }

    final foodId = meal.foodId?.trim();
    if (foodId != null && foodId.isNotEmpty && foodId.toLowerCase() != 'null') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: foodId),
        ),
      );
      return;
    }

    if (!mounted) return;
    _showSnack('Không có liên kết chi tiết cho món này.', isError: true);
  }

  Future<void> _createTemplateFromLog(HistoryMealEntry meal) async {
    final controller = TextEditingController(text: meal.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu thành thực đơn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên thực đơn'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;

    try {
      await _mealTemplateRepository.createFromLog(meal.id, title);
      if (mounted) _showSnack('Đã lưu thực đơn.');
    } catch (_) {
      if (mounted) _showSnack('Không thể lưu thực đơn.', isError: true);
    }
  }

  Future<void> _editMealLog(String mealLogId) async {
    final logs = _dailySummary?.mealLogs ?? [];
    MealLogItem? meal;
    for (final item in logs) {
      if (item.id == mealLogId) {
        meal = item;
        break;
      }
    }
    if (meal == null) {
      _showSnack('Không tìm thấy nhật ký', isError: true);
      return;
    }

    final ok = await showMealLogEditSheet(
      context,
      meal: meal,
      selectedDate: _selectedDate,
    );
    if (!ok) {
      _showSnack('Không thể cập nhật nhật ký', isError: true);
      return;
    }
    _showSnack('Đã cập nhật nhật ký bữa ăn');
    _notifyTrackingUpdated();
    await _loadData();
  }

  Future<void> _deleteMealLog(String mealLogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhật ký bữa ăn'),
        content: const Text('Bạn có chắc muốn xóa mục này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _repository.deleteMealLog(mealLogId);
    if (!ok) {
      _showSnack('Xóa thất bại', isError: true);
      return;
    }
    _showSnack('Đã xóa nhật ký bữa ăn');
    _notifyTrackingUpdated();
    await _loadData();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final isStandalone = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isStandalone
          ? AppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              foregroundColor: AppColors.textDark,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Lịch sử hoạt động',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isStandalone),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    Center(
                      child: DashboardRangeSelector(
                        selected: _dashboardRange,
                        onChanged: _onDashboardRangeChanged,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DailySummaryCard(
                      summary: _effectiveSummary,
                      title: _summaryCardTitle,
                      isAverage: _dashboardRange != DashboardRange.day,
                    ),
                    const SizedBox(height: 16),
                    CalorieTrendChart(
                      days: _dashboard?.days ?? [],
                      selectedDate: _selectedDate,
                      onDayTap: (date) => _selectDate(date),
                    ),
                    const SizedBox(height: 16),
                    WeightTrendChart(logs: _dashboard?.weightLogs ?? []),
                    const SizedBox(height: 16),
                    WeightLogsList(
                      logs: _dashboard?.weightLogs ?? [],
                      onEdit: _editWeightLog,
                      onDelete: _deleteWeightLog,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nhật ký bữa ăn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: _addMealLog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.add, size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Thêm món',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (sections.isEmpty)
                      _buildEmptyState()
                    else
                      ...sections.asMap().entries.map((entry) {
                        final index = entry.key;
                        final section = entry.value;
                        final isLast = index == sections.length - 1;
                        return _TimelineSectionWidget(
                          section: section,
                          showLineBelow: !isLast,
                          onDeleteMeal: _deleteMealLog,
                          onEditMeal: _editMealLog,
                          onOpenDetail: _openMealDetail,
                          onCreateTemplate: _createTemplateFromLog,
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isStandalone) {
    final latestWeight = _dashboard?.weightLogs.isNotEmpty == true
        ? _dashboard!.weightLogs.last.weightKg
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isStandalone)
                  const Text(
                    'Lịch sử hoạt động',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                if (latestWeight != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monitor_weight_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cân nặng: ${latestWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _headerIconButton(
            icon: Icons.today_rounded,
            tooltip: 'Hôm nay',
            onTap: () {
              setState(() {
                _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
              });
            },
          ),
          const SizedBox(width: 6),
          _headerIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Thêm nhật ký',
            onTap: _addMealLog,
          ),
          const SizedBox(width: 6),
          _headerIconButton(
            icon: Icons.scale_rounded,
            tooltip: 'Ghi cân nặng',
            onTap: _addWeightLog,
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday % 7;
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textDark, size: 22),
                onPressed: () => _changeMonth(-1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textDark, size: 22),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) {
                final day = daysInPrevMonth - leadingEmpty + index + 1;
                return _CalendarDayCell(
                  day: day,
                  isOutsideMonth: true,
                  isSelected: false,
                  onTap: () {},
                );
              }

              final day = index - leadingEmpty + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final goalPercent = _monthGoalByDate[_dateKey(date)];
              final heatmapLevel = NutritionHeatmapColors.levelForPercent(goalPercent);

              return _CalendarDayCell(
                day: day,
                isOutsideMonth: false,
                isSelected: isSelected,
                heatmapLevel: heatmapLevel,
                onTap: () => _selectDate(date),
              );
            },
          ),
          const CalendarHeatmapLegend(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm món ăn trong nhật ký...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            icon: Icons.restaurant_menu_rounded,
            isSelected: _mealFilter == null,
            onTap: () => setState(() => _mealFilter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.breakfast.filterLabel,
            icon: Icons.wb_twilight_rounded,
            isSelected: _mealFilter == MealCategory.breakfast,
            onTap: () => setState(() => _mealFilter = MealCategory.breakfast),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.lunch.filterLabel,
            icon: Icons.wb_sunny_rounded,
            isSelected: _mealFilter == MealCategory.lunch,
            onTap: () => setState(() => _mealFilter = MealCategory.lunch),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.dinner.filterLabel,
            icon: Icons.nights_stay_rounded,
            isSelected: _mealFilter == MealCategory.dinner,
            onTap: () => setState(() => _mealFilter = MealCategory.dinner),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.snack.filterLabel,
            icon: Icons.local_cafe_rounded,
            isSelected: _mealFilter == MealCategory.snack,
            onTap: () => setState(() => _mealFilter = MealCategory.snack),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty ? 'Không tìm thấy món ăn phù hợp' : 'Chưa ghi nhận bữa ăn nào',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Thử gõ tên từ khóa khác xem sao.'
                  : 'Bấm "+ Thêm món" ở trên để ghi chép lại bữa ăn nhé.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isOutsideMonth,
    required this.isSelected,
    required this.onTap,
    this.heatmapLevel = HeatmapLevel.none,
  });

  final int day;
  final bool isOutsideMonth;
  final bool isSelected;
  final HeatmapLevel heatmapLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final heatmapColor = isOutsideMonth || isSelected
        ? Colors.transparent
        : CalendarHeatmapStyle.backgroundForLevel(heatmapLevel);

    return GestureDetector(
      onTap: isOutsideMonth ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : heatmapColor,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isOutsideMonth
                    ? AppColors.textLight.withValues(alpha: 0.5)
                    : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSectionWidget extends StatefulWidget {
  const _TimelineSectionWidget({
    required this.section,
    required this.showLineBelow,
    required this.onDeleteMeal,
    required this.onEditMeal,
    required this.onOpenDetail,
    required this.onCreateTemplate,
  });

  final HistoryTimelineSection section;
  final bool showLineBelow;
  final Future<void> Function(String mealId) onDeleteMeal;
  final Future<void> Function(String mealId) onEditMeal;
  final Future<void> Function(HistoryMealEntry meal) onOpenDetail;
  final Future<void> Function(HistoryMealEntry meal) onCreateTemplate;

  @override
  State<_TimelineSectionWidget> createState() => _TimelineSectionWidgetState();
}

class _TimelineSectionWidgetState extends State<_TimelineSectionWidget> {
  bool _isExpanded = true;

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _categoryColor(MealCategory cat) {
    return switch (cat) {
      MealCategory.breakfast => const Color(0xFFD97706),
      MealCategory.lunch => AppColors.primary,
      MealCategory.dinner => const Color(0xFF4F46E5),
      MealCategory.snack => const Color(0xFF8B5CF6),
    };
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(widget.section.category);
    final totalCount = widget.section.meals.length;
    final totalCalories = widget.section.meals.fold<int>(0, (sum, m) => sum + m.calories);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      widget.section.category.icon,
                      size: 18,
                      color: catColor,
                    ),
                  ),
                ),
                if (widget.showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                widget.section.category.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$totalCount món • $totalCalories kcal',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: catColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formatTime(widget.section.time),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _isExpanded ? 0 : -0.25,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 10),
                    ...widget.section.meals.map((meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MealCard(
                            meal: meal,
                            onOpenDetail: meal.canOpenDetail ? () => widget.onOpenDetail(meal) : null,
                            onEdit: () => widget.onEditMeal(meal.id),
                            onDelete: () => widget.onDeleteMeal(meal.id),
                            onCreateTemplate: () => widget.onCreateTemplate(meal),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateTemplate,
    this.onOpenDetail,
  });

  final HistoryMealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCreateTemplate;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: meal.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: meal.imageUrl!,
                        width: 54,
                        height: 54,
                        memCacheWidth: 54,
                        memCacheHeight: 54,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFFF1F5F9),
                        ),
                        errorWidget: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(meal.isRecipe),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${meal.calories} kcal',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meal.portion,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'detail') onOpenDetail?.call();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'template') onCreateTemplate();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'template',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_add_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Lưu thành thực đơn'),
                      ],
                    ),
                  ),
                  if (onOpenDetail != null)
                    const PopupMenuItem<String>(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: AppColors.textDark),
                          SizedBox(width: 8),
                          Text('Xem chi tiết'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textDark),
                        SizedBox(width: 8),
                        Text('Sửa nhật ký'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa nhật ký', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              if (onOpenDetail != null)
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder([bool isRecipe = false]) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRecipe
              ? [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        isRecipe ? Icons.menu_book_rounded : Icons.restaurant_rounded,
        color: isRecipe ? const Color(0xFF4F46E5) : AppColors.primary,
        size: 24,
      ),
    );
  }
}
