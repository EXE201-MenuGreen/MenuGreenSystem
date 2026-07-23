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
  const HistoryView({super.key, this.onTrackingUpdated});

  final VoidCallback? onTrackingUpdated;

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
    var sections = _buildSectionsFromSummary(_dailySummary);

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: const TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    DashboardRangeSelector(
                      selected: _dashboardRange,
                      onChanged: _onDashboardRangeChanged,
                    ),
                    const SizedBox(height: 16),
                    DailySummaryCard(
                      summary: _dailySummary,
                      title: 'Tiến độ ngày ${_selectedDate.day}/${_selectedDate.month}',
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
                    const SizedBox(height: 20),
                    const Text(
                      'Nhật ký bữa ăn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 24),
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

  Widget _buildHeader() {
    final latestWeight = _dashboard?.weightLogs.isNotEmpty == true
        ? _dashboard!.weightLogs.last.weightKg
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch sử hoạt động',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (latestWeight != null)
                  Text(
                    'Cân nặng gần nhất: ${latestWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.textDark),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.textDark),
            onPressed: _addMealLog,
          ),
          IconButton(
            icon: const Icon(Icons.monitor_weight_outlined, color: AppColors.textDark),
            onPressed: _addWeightLog,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday % 7;
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.textDark),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.textDark),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (d) => SizedBox(
                  width: 36,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm món ăn...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
            isSelected: _mealFilter == null,
            showDropdown: false,
            onTap: () => setState(() => _mealFilter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.breakfast.filterLabel,
            isSelected: _mealFilter == MealCategory.breakfast,
            showDropdown: true,
            onTap: () => setState(() => _mealFilter = MealCategory.breakfast),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.lunch.filterLabel,
            isSelected: _mealFilter == MealCategory.lunch,
            showDropdown: true,
            onTap: () => setState(() => _mealFilter = MealCategory.lunch),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.snack.filterLabel,
            isSelected: _mealFilter == MealCategory.snack,
            showDropdown: true,
            onTap: () => setState(() => _mealFilter = MealCategory.snack),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: AppColors.textLight.withValues(alpha: 0.8)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'Không tìm thấy món ăn' : 'Chưa có hoạt động trong ngày này',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : heatmapColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isOutsideMonth
                    ? AppColors.textLight
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
    required this.isSelected,
    required this.showDropdown,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool showDropdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.progressBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineSectionWidget extends StatelessWidget {
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

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = section.isHighlighted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: highlighted ? AppColors.primary : AppColors.progressBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    section.category.icon,
                    size: 20,
                    color: highlighted ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.progressBackground,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        section.category.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        _formatTime(section.time),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...section.meals.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MealCard(
                          meal: meal,
                          onOpenDetail: meal.canOpenDetail ? () => onOpenDetail(meal) : null,
                          onEdit: () => onEditMeal(meal.id),
                          onDelete: () => onDeleteMeal(meal.id),
                          onCreateTemplate: () => onCreateTemplate(meal),
                        ),
                      )),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.progressBackground),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: meal.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: meal.imageUrl!,
                        width: 56,
                        height: 56,
                        memCacheWidth: 56,
                        memCacheHeight: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (_, __, ___) => _imagePlaceholder(),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.calories} kcal • ${meal.portion}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (onOpenDetail != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Chạm để xem chi tiết',
                          style: TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                onSelected: (value) {
                  if (value == 'detail') onOpenDetail?.call();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'template') onCreateTemplate();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'template',
                    child: Text('Lưu thành thực đơn'),
                  ),
                  if (onOpenDetail != null)
                    const PopupMenuItem<String>(
                      value: 'detail',
                      child: Text('Xem chi tiết'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Sửa nhật ký'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xóa nhật ký'),
                  ),
                ],
              ),
              if (onOpenDetail != null)
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder([bool isRecipe = false]) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.progressBackground,
      child: Icon(
        isRecipe ? Icons.menu_book_outlined : Icons.restaurant,
        color: AppColors.textLight,
        size: 24,
      ),
    );
  }
}
