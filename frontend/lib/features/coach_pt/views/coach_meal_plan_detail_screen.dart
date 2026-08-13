import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/daily_calorie_portion_balancer.dart';
import '../../../core/utils/meal_schedule_format.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../../core/widgets/calorie_adjustment_picker.dart';
import '../../../core/widgets/daily_calorie_balance_card.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../coach_pt.dart';

@visibleForTesting
List<ClientMealLogItem> coachLogsForPlanRange(
  Iterable<ClientMealLogItem> logs,
  DateTime? startDate,
  DateTime? endDate,
) {
  if (startDate == null) return logs.toList();
  final start = DateUtils.dateOnly(startDate);
  final end = DateUtils.dateOnly(endDate ?? startDate);
  return logs.where((log) {
    final loggedDate = DateUtils.dateOnly(log.loggedAt.toLocal());
    return !loggedDate.isBefore(start) && !loggedDate.isAfter(end);
  }).toList();
}

/// Coach edits a specific Gymer's meal plan.
///
/// * Tapping a meal item opens an inline edit sheet (Delete / Replace).
/// * Adding a new item pushes a bottom sheet that picks a food/recipe from the
///   ingredient catalog (using the existing `/Ingredient/search` endpoint).
/// * The bottom action bar lets PT send a draft for Gymer acceptance.
class CoachMealPlanDetailScreen extends StatefulWidget {
  const CoachMealPlanDetailScreen({super.key, required this.planId});
  final String planId;

  @override
  State<CoachMealPlanDetailScreen> createState() =>
      _CoachMealPlanDetailScreenState();
}

class _CoachMealPlanDetailScreenState extends State<CoachMealPlanDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _dirty = false;
  String? _initializedPlanId;
  late final List<_DraftItem> _draft;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _draft = [];
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CoachMealPlanProvider>();
      provider.loadPlanDetail(widget.planId);
    });
  }

  void _loadNutritionForPlan(CoachMealPlanDetail plan) {
    final provider = context.read<CoachMealPlanProvider>();
    final planType = plan.header.planType.toLowerCase();
    final startDate = plan.header.startDate;
    final endDate = plan.header.endDate;

    DateTime? from;
    DateTime? to;

    if (planType == 'daily' && startDate != null) {
      // Daily: chỉ hiển thị ngày đó
      from = startDate;
      to = startDate;
    } else if (planType == 'weekly' && startDate != null) {
      // Weekly: hiển thị 7 ngày từ startDate
      from = startDate;
      to = startDate.add(const Duration(days: 6));
    } else if (planType == 'monthly' && startDate != null) {
      // Monthly: hiển thị tất cả ngày trong tháng
      from = startDate;
      to = DateTime(startDate.year, startDate.month + 1, 0); // Ngày cuối tháng
    } else if (startDate != null && endDate != null) {
      // Custom range
      from = startDate;
      to = endDate;
    }

    provider.loadNutritionSummary(from: from, to: to);
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      // Tab "Theo dõi" được chọn
      final plan = context.read<CoachMealPlanProvider>().selectedPlan;
      if (plan != null) {
        _loadNutritionForPlan(plan);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  CoachMealPlanDetail? get _plan =>
      context.read<CoachMealPlanProvider>().selectedPlan;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  List<DateTime> _draftDates(CoachMealPlanDetail plan) {
    final dates =
        _draft
            .map((item) => item.plannedDate ?? plan.header.startDate)
            .whereType<DateTime>()
            .map(DateUtils.dateOnly)
            .toSet()
            .toList()
          ..sort();
    return dates;
  }

  List<_DraftItem> _draftItemsForDate(CoachMealPlanDetail plan, DateTime date) {
    return _draft.where((item) {
      final itemDate = item.plannedDate ?? plan.header.startDate;
      return itemDate != null && DateUtils.isSameDay(itemDate, date);
    }).toList();
  }

  Widget _buildDailyBalancePanel(
    CoachMealPlanDetail plan, {
    required bool readOnly,
  }) {
    final target = plan.header.targetCalories ?? 0;
    final dates = _draftDates(plan);
    if (target <= 0 || dates.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tổng kcal của 4 bữa',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            readOnly
                ? 'Lộ trình đã gửi hoặc đã duyệt nên khẩu phần đang được khóa.'
                : 'PT có thể tự cân bằng rồi tiếp tục chỉnh từng món trước khi duyệt.',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < dates.length; index++) ...[
                  Builder(
                    builder: (_) {
                      final date = dates[index];
                      final items = _draftItemsForDate(plan, date);
                      return DailyCalorieBalanceCard(
                        width: 245,
                        dateLabel:
                            '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}/${date.year}',
                        totalCalories: items.fold<int>(
                          0,
                          (sum, item) => sum + (item.targetCalories ?? 0),
                        ),
                        targetCalories: target,
                        mealCount: items
                            .map((item) => item.mealType)
                            .toSet()
                            .length,
                        canAutoBalance: !readOnly,
                        actionLabel: 'Tùy chỉnh',
                        allowAdjustmentWhenExact: true,
                        onAutoBalance: readOnly
                            ? null
                            : () => _autoBalanceDraftDate(plan, date, target),
                      );
                    },
                  ),
                  if (index < dates.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _autoBalanceDraftDate(
    CoachMealPlanDetail plan,
    DateTime date,
    int target,
  ) async {
    final items = _draftItemsForDate(plan, date);
    if (items.isEmpty) return;

    final desiredCalories = await showCalorieAdjustmentPicker(
      context: context,
      targetCalories: target,
    );
    if (desiredCalories == null || !mounted) return;

    final result = DailyCaloriePortionBalancer.balance(
      targetCalories: desiredCalories,
      portions: items
          .map(
            (item) => CaloriePortionInput(
              calories: (item.targetCalories ?? 0).toDouble(),
              quantityG: item.quantityG ?? 100,
              proteinG: item.proteinG ?? 0,
              carbsG: item.carbsG ?? 0,
              fatG: item.fatG ?? 0,
              ingredientQuantities: item.ingredients
                  .map((ingredient) => ingredient.quantity)
                  .toList(),
            ),
          )
          .toList(),
    );

    setState(() {
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final balanced = result.portions[index];
        item.targetCalories = balanced.calories;
        item.quantityG = balanced.quantityG;
        item.proteinG = balanced.proteinG;
        item.carbsG = balanced.carbsG;
        item.fatG = balanced.fatG;
        item.ingredients = [
          for (
            var ingredientIndex = 0;
            ingredientIndex < item.ingredients.length;
            ingredientIndex++
          )
            MealPlanIngredientPortion(
              ingredientId: item.ingredients[ingredientIndex].ingredientId,
              quantity: balanced.ingredientQuantities[ingredientIndex],
              unit: item.ingredients[ingredientIndex].unit,
            ),
        ];
      }
      _dirty = true;
    });

    final percent = ((result.scaleFactor - 1).abs() * 100).round();
    final action = result.scaleFactor >= 1 ? 'tăng' : 'giảm';
    final targetComparison = desiredCalories == target
        ? 'đúng mục tiêu'
        : desiredCalories < target
        ? 'thấp hơn mục tiêu'
        : 'cao hơn mục tiêu';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Đã $action khẩu phần khoảng $percent% về $desiredCalories kcal '
            '($targetComparison $target kcal). Hãy lưu hoặc duyệt để áp dụng.',
          ),
        ),
      );
  }

  Future<bool> _saveDraft() async {
    final payload = ClientMealPlanPayload(
      title: _plan!.header.title,
      planType: _plan!.header.planType,
      startDate: _plan!.header.startDate,
      endDate: _plan!.header.endDate,
      targetCalories: _plan!.header.targetCalories,
      minCalories: _plan!.header.minCalories,
      maxCalories: _plan!.header.maxCalories,
      coachNotes: _customCoachNotes ?? _plan!.header.coachNotes,
      items: _draft.map((d) => d.toPayload()).toList(),
    );
    final ok = await context.read<CoachMealPlanProvider>().updatePlan(
      widget.planId,
      payload,
    );
    if (!mounted) return false;
    if (ok) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu nháp lộ trình.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thất bại. Vui lòng thử lại.')),
      );
    }
    return ok;
  }

  Future<void> _submit() async {
    if (_dirty && !await _saveDraft()) return;
    if (!mounted) return;
    final notes = (_customCoachNotes ?? _plan?.header.coachNotes ?? '').trim();
    final provider = context.read<CoachMealPlanProvider>();
    final ok = await provider.submitPlan(
      widget.planId,
      notes: notes.isEmpty ? null : notes,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _dirty = false);
      // Let the previous route own the success SnackBar. Showing a SnackBar
      // from this route while it is being removed can leave Overlay
      // dependents attached during deactivation.
      Navigator.of(context).pop(true);
    } else {
      final message = provider.error?.trim();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message == null || message.isEmpty
                  ? 'Gửi thất bại. Vui lòng thử lại.'
                  : message,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachMealPlanProvider>();
    final plan = provider.selectedPlan;

    if (provider.isLoadingDetail || plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lộ trình')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.detailError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lộ trình')),
        body: _ErrorState(message: provider.detailError!),
      );
    }

    if (_initializedPlanId != plan.header.id && !_dirty) {
      _initializedPlanId = plan.header.id;
      _draft.clear();
      final itemsByMeal = plan.itemsByMeal;
      for (final entry in itemsByMeal.entries) {
        _draft.addAll(
          entry.value.map(
            (item) =>
                _DraftItem.fromItem(item, fallbackDate: plan.header.startDate),
          ),
        );
      }
    }

    final isApproved = plan.header.isApproved;
    final isPendingAcceptance = plan.header.isPendingAcceptance;
    final isReadOnly = isApproved || isPendingAcceptance;
    final sendsForAcceptance = {
      'draft',
      'rejected',
    }.contains(plan.header.status.toLowerCase());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          coachMealPlanDisplayTitle(
            title: plan.header.title,
            planType: plan.header.planType,
            startDate: plan.header.startDate,
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          if (_dirty && !isReadOnly)
            IconButton(
              tooltip: 'Lưu nháp',
              icon: const Icon(Icons.save_outlined, color: Color(0xFF374151)),
              onPressed: _saveDraft,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: isApproved
              ? SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Đã duyệt & gửi cho học viên',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      disabledForegroundColor: const Color(0xFF6B7280),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              : isPendingAcceptance
              ? SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.hourglass_top_rounded, size: 20),
                    label: const Text(
                      'Đang chờ Gymer chấp nhận',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: const Color(0xFFFEF3C7),
                      disabledForegroundColor: const Color(0xFFB45309),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    if (_dirty)
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Lưu nháp'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _saveDraft,
                          ),
                        ),
                      ),
                    if (_dirty) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            sendsForAcceptance
                                ? 'Gửi Gymer duyệt'
                                : 'Duyệt & gửi',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submit,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      body: Column(
        children: [
          // Tab bar for switching between Plan and Tracking views
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Lộ trình'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Theo dõi'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Plan editing (existing content)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OverviewSection(plan: plan),
                    const SizedBox(height: 16),
                    _buildDailyBalancePanel(plan, readOnly: isReadOnly),
                    const SizedBox(height: 16),
                    _NutritionTargetsSection(plan: plan, draft: _draft),
                    const SizedBox(height: 16),
                    _CoachNotesSection(
                      plan: plan,
                      customNotes: _customCoachNotes,
                      onEdit: isReadOnly ? null : _editCoachNotes,
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Bữa ăn và món ăn',
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: AppColors.primary,
                      child: Column(
                        children: _buildMealSections(
                          context,
                          plan,
                          readOnly: isReadOnly,
                        ),
                      ),
                    ),
                  ],
                ),

                // Tab 2: Nutrition tracking with charts
                _NutritionTrackingTab(plan: plan, draft: _draft),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton(
              heroTag: 'addMealItem',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () => _showAddItemSheet(context),
              child: const Icon(Icons.add_rounded, size: 24),
            ),
    );
  }

  List<Widget> _buildMealSections(
    BuildContext context,
    CoachMealPlanDetail plan, {
    required bool readOnly,
  }) {
    const mealOrder = [
      ('breakfast', 'Bữa sáng'),
      ('lunch', 'Bữa trưa'),
      ('dinner', 'Bữa tối'),
      ('snack', 'Bữa phụ'),
    ];
    final sections = <Widget>[];
    for (final entry in mealOrder) {
      final items = _draft.where((d) => d.mealType == entry.$1).toList();
      sections.add(
        _MealSection(
          title: entry.$2,
          items: items,
          onEdit: readOnly ? null : _editItem,
          onView: _openItemDetail,
        ),
      );
      sections.add(const SizedBox(height: 16));
    }
    return sections;
  }

  void _openItemDetail(_DraftItem item) {
    final Widget? screen = item.foodId != null
        ? FoodDetailScreen(
            foodId: item.foodId!,
            plannedQuantityG: item.quantityG,
          )
        : item.recipeId != null
        ? RecipeDetailScreen(
            recipeId: item.recipeId!,
            plannedQuantityG: item.quantityG,
          )
        : null;
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  Future<void> _editItem(_DraftItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Chỉnh giờ ăn'),
              subtitle: Text(
                'Giờ ăn: ${mealScheduledTimeLabel(item.scheduledTime, mealType: item.mealType)}',
              ),
              onTap: () => Navigator.pop(ctx, 'schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.scale_rounded),
              title: const Text('Chỉnh khối lượng món'),
              subtitle: Text(
                '${formatNutritionNumber(item.quantityG ?? 100)} g',
              ),
              onTap: () => Navigator.pop(ctx, 'portion'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Thay món khác'),
              onTap: () => Navigator.pop(ctx, 'replace'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Xóa khỏi lộ trình',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'schedule') {
      await _editItemTime(item);
    } else if (action == 'portion') {
      await _editItemPortion(item);
    } else if (action == 'delete') {
      setState(() => _draft.remove(item));
      _markDirty();
    } else if (action == 'replace') {
      final pick = await _showIngredientPicker(context);
      if (pick != null && mounted) {
        setState(() {
          item.foodId = pick.kind == _IngredientKind.food ? pick.id : null;
          item.recipeId = pick.kind == _IngredientKind.recipe ? pick.id : null;
          item.displayName = pick.name;
          item.targetCalories = pick.calories;
          item.proteinG = pick.proteinG;
          item.carbsG = pick.carbsG;
          item.fatG = pick.fatG;
        });
        _markDirty();
      }
    }
  }

  Future<void> _editItemPortion(_DraftItem item) async {
    final currentQuantity = item.quantityG ?? 100;
    final controller = TextEditingController(
      text: formatNutritionNumber(currentQuantity),
    );
    final dialogRoute = DialogRoute<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Chỉnh khối lượng ${item.displayName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Khối lượng khẩu phần',
            suffixText: 'g',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (parsed == null || parsed <= 0) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final newQuantity = await Navigator.of(context).push(dialogRoute);
    await dialogRoute.completed;
    controller.dispose();
    if (!mounted || newQuantity == null || currentQuantity <= 0) return;

    final factor = newQuantity / currentQuantity;
    setState(() {
      item.quantityG = newQuantity;
      item.targetCalories = ((item.targetCalories ?? 0) * factor).round();
      item.proteinG = (item.proteinG ?? 0) * factor;
      item.carbsG = (item.carbsG ?? 0) * factor;
      item.fatG = (item.fatG ?? 0) * factor;
      item.ingredients = item.ingredients
          .map(
            (ingredient) => MealPlanIngredientPortion(
              ingredientId: ingredient.ingredientId,
              quantity: ingredient.quantity * factor,
              unit: ingredient.unit,
            ),
          )
          .toList();
      _dirty = true;
    });
  }

  Future<void> _editItemTime(_DraftItem item) async {
    final currentTime = mealScheduledTimeLabel(
      item.scheduledTime,
      mealType: item.mealType,
    ).split(':');
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(currentTime.first) ?? 12,
        minute: int.tryParse(currentTime.last) ?? 0,
      ),
      helpText: 'CHỌN GIỜ ĂN',
    );
    if (selectedTime == null || !mounted) return;

    setState(() {
      item.scheduledTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:'
          '${selectedTime.minute.toString().padLeft(2, '0')}';
    });
    _markDirty();
  }

  Future<_IngredientPick?> _showIngredientPicker(BuildContext context) {
    return showModalBottomSheet<_IngredientPick>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _IngredientPickerSheet(),
    );
  }

  Future<void> _showAddItemSheet(BuildContext context) async {
    String mealType = 'breakfast';
    final result = await showModalBottomSheet<_AddItemResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm món mới',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mealType,
                  decoration: const InputDecoration(
                    labelText: 'Bữa',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'breakfast',
                      child: Text('Bữa sáng'),
                    ),
                    DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                    DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                    DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                  ],
                  onChanged: (v) => setSheet(() => mealType = v ?? 'breakfast'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Chọn món / công thức'),
                  onPressed: () async {
                    final pick = await _showIngredientPicker(context);
                    if (pick != null && ctx.mounted) {
                      Navigator.pop(
                        ctx,
                        _AddItemResult(mealType: mealType, pick: pick),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _draft.add(
          _DraftItem(
            id: null,
            mealType: result.mealType,
            foodId: result.pick.kind == _IngredientKind.food
                ? result.pick.id
                : null,
            recipeId: result.pick.kind == _IngredientKind.recipe
                ? result.pick.id
                : null,
            displayName: result.pick.name,
            plannedDate: _plan?.header.startDate,
            scheduledTime: defaultMealScheduledTime(result.mealType),
            targetCalories: result.pick.calories,
            quantityG: result.pick.quantityG ?? 100,
            proteinG: result.pick.proteinG,
            carbsG: result.pick.carbsG,
            fatG: result.pick.fatG,
          ),
        );
      });
      _markDirty();
    }
  }

  String? _customCoachNotes;

  Future<void> _editCoachNotes() async {
    final initialText = _customCoachNotes ?? _plan?.header.coachNotes ?? '';
    final controller = TextEditingController(text: initialText);
    final newNotes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi chú cho học viên'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú cho học viên...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (newNotes != null && mounted) {
      setState(() {
        _customCoachNotes = newNotes;
      });
      _markDirty();
    }
  }
}

// =============================================================================
// Nutrition Tracking Tab - Shows actual meals eaten and charts for PT
// =============================================================================
class _NutritionTrackingTab extends StatelessWidget {
  const _NutritionTrackingTab({required this.plan, required this.draft});

  final CoachMealPlanDetail plan;
  final List<_DraftItem> draft;

  static String _formatDateShort(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static String _formatDateFull(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final nutritionProvider = context.watch<CoachMealPlanProvider>();
    final actualDays = nutritionProvider.nutritionSummary;
    final actualLogs = coachLogsForPlanRange(
      actualDays.expand((day) => day.logs),
      plan.header.startDate,
      plan.header.endDate,
    );
    final planType = plan.header.planType.toLowerCase();

    // Determine display title based on plan type
    String rangeTitle = '';
    if (plan.header.startDate != null) {
      final start = plan.header.startDate!;
      if (planType == 'daily') {
        rangeTitle = _formatDateFull(start);
      } else if (planType == 'weekly') {
        final end = start.add(const Duration(days: 6));
        rangeTitle = '${_formatDateShort(start)} - ${_formatDateShort(end)}';
      } else if (planType == 'monthly') {
        rangeTitle = 'Tháng ${start.month}/${start.year}';
      } else if (plan.header.endDate != null) {
        rangeTitle =
            '${_formatDateShort(start)} - ${_formatDateShort(plan.header.endDate!)}';
      }
    }

    final startDate = plan.header.startDate;
    final endDate = plan.header.endDate ?? startDate;
    final planDayCount = startDate != null && endDate != null
        ? (endDate.difference(startDate).inDays + 1).clamp(1, 366)
        : 1;
    final itemCalories = draft.fold<int>(
      0,
      (sum, item) => sum + (item.targetCalories ?? 0),
    );
    final dailyCalorieTarget = plan.header.targetCalories ?? 0;
    // Tracking follows the concrete approved menu snapshot. The configured
    // calorie goal remains visible in the Route tab, but must not replace the
    // calories of the meals that PT actually approved.
    final totalPlannedCalories = itemCalories > 0
        ? itemCalories
        : dailyCalorieTarget * planDayCount;
    final totalActualCalories = actualLogs.fold<int>(
      0,
      (sum, log) => sum + log.calories,
    );
    final itemProtein = draft.fold<int>(
      0,
      (sum, item) => sum + (item.proteinG ?? 0).round(),
    );
    final totalPlannedProtein = itemProtein > 0
        ? itemProtein
        : (plan.targetProteinG ?? 0) * planDayCount;
    final totalActualProtein = actualLogs.fold<int>(
      0,
      (sum, log) => sum + log.proteinG.round(),
    );
    final itemCarbs = draft.fold<int>(
      0,
      (sum, item) => sum + (item.carbsG ?? 0).round(),
    );
    final totalPlannedCarbs = itemCarbs > 0
        ? itemCarbs
        : (plan.targetCarbsG ?? 0) * planDayCount;
    final totalActualCarbs = actualLogs.fold<int>(
      0,
      (sum, log) => sum + log.carbsG.round(),
    );
    final itemFat = draft.fold<int>(
      0,
      (sum, item) => sum + (item.fatG ?? 0).round(),
    );
    final totalPlannedFat = itemFat > 0
        ? itemFat
        : (plan.targetFatG ?? 0) * planDayCount;
    final totalActualFat = actualLogs.fold<int>(
      0,
      (sum, log) => sum + log.fatG.round(),
    );
    final completedCount = actualLogs.length;
    final linkedItemIds = actualLogs
        .map((log) => log.mealPlanItemId)
        .whereType<String>()
        .toSet();
    final remainingCount = draft
        .where((item) => item.id == null || !linkedItemIds.contains(item.id))
        .length;

    final calorieProgress = totalPlannedCalories > 0
        ? (totalActualCalories / totalPlannedCalories).clamp(0.0, 1.5)
        : 0.0;
    final remainingCalories = (totalPlannedCalories - totalActualCalories)
        .clamp(0, 99999);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (nutritionProvider.isLoadingNutrition)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        if (nutritionProvider.nutritionError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                ),
                title: const Text('Không tải được dữ liệu món đã ăn.'),
                trailing: TextButton(
                  onPressed: nutritionProvider.refreshNutrition,
                  child: const Text('Thử lại'),
                ),
              ),
            ),
          ),
        // Range title badge
        if (rangeTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      planType == 'daily'
                          ? Icons.today_rounded
                          : (planType == 'weekly'
                                ? Icons.view_week_rounded
                                : Icons.calendar_month_rounded),
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    rangeTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      planType == 'daily' ? 'Hôm nay' : planType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Summary cards (Kế hoạch, Đã ăn, Còn lại)
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Kế hoạch',
                value: '$totalPlannedCalories',
                unit: 'kcal',
                icon: Icons.track_changes_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFDBEAFE),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Đã nạp',
                value: '$totalActualCalories',
                unit: 'kcal',
                icon: Icons.restaurant_rounded,
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Còn lại',
                value: '$remainingCalories',
                unit: 'kcal',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Overall progress card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiến độ năng lượng',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Mức tiêu thụ calo hôm nay',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (calorieProgress >= 0.9 && calorieProgress <= 1.1)
                          ? const Color(0xFFECFDF5)
                          : (calorieProgress > 1.1
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (calorieProgress >= 0.9 && calorieProgress <= 1.1)
                            ? const Color(0xFFA7F3D0)
                            : (calorieProgress > 1.1
                                  ? const Color(0xFFFED7AA)
                                  : const Color(0xFFFECDD3)),
                      ),
                    ),
                    child: Text(
                      '${(calorieProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: calorieProgress >= 0.9 && calorieProgress <= 1.1
                            ? const Color(0xFF059669)
                            : (calorieProgress > 1.1
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: calorieProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              calorieProgress >= 0.9 && calorieProgress <= 1.1
                              ? [
                                  const Color(0xFF34D399),
                                  const Color(0xFF059669),
                                ]
                              : (calorieProgress > 1.1
                                    ? [
                                        const Color(0xFFFBBF24),
                                        const Color(0xFFEA580C),
                                      ]
                                    : [
                                        const Color(0xFFF87171),
                                        const Color(0xFFDC2626),
                                      ]),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (calorieProgress >= 0.9 &&
                                            calorieProgress <= 1.1
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626))
                                    .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã nạp: $totalActualCalories kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Text(
                    'Mục tiêu: $totalPlannedCalories kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Macros comparison
        _MacroComparisonSection(
          plannedProtein: totalPlannedProtein,
          actualProtein: totalActualProtein,
          plannedCarbs: totalPlannedCarbs,
          actualCarbs: totalActualCarbs,
          plannedFat: totalPlannedFat,
          actualFat: totalActualFat,
        ),
        const SizedBox(height: 16),

        // Progress summary (Completed vs Remaining meals)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$completedCount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF047857),
                            ),
                          ),
                          const Text(
                            'món đã ăn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$remainingCount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const Text(
                            'món chưa ăn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Meal type breakdown title
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Chi tiết theo bữa ăn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        _MealTypeBreakdownSection(logs: actualLogs),
        const SizedBox(height: 80),
      ],
    );
  }
}

// =============================================================================
// Meal Type Breakdown Section - Shows meals grouped by type (breakfast, lunch, etc.)
// =============================================================================
class _MealTypeBreakdownSection extends StatelessWidget {
  const _MealTypeBreakdownSection({required this.logs});

  final List<ClientMealLogItem> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.no_meals_outlined, color: Color(0xFF94A3B8), size: 30),
            SizedBox(height: 8),
            Text(
              'Chưa có món nào được ghi nhận là đã ăn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final mealTypes = [
      (
        'breakfast',
        'Bữa sáng',
        Icons.wb_sunny_rounded,
        const Color(0xFFEA580C),
        const Color(0xFFFFF7ED),
      ),
      (
        'lunch',
        'Bữa trưa',
        Icons.restaurant_rounded,
        const Color(0xFF059669),
        const Color(0xFFECFDF5),
      ),
      (
        'dinner',
        'Bữa tối',
        Icons.nights_stay_rounded,
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF),
      ),
      (
        'snack',
        'Bữa phụ',
        Icons.cookie_rounded,
        const Color(0xFF7C3AED),
        const Color(0xFFFAF5FF),
      ),
    ];

    return Column(
      children: mealTypes.map((type) {
        final items = logs
            .where((log) => log.mealType.trim().toLowerCase() == type.$1)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();

        final totalCal = items.fold<int>(0, (sum, item) => sum + item.calories);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: type.$5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.$3, size: 22, color: type.$4),
              ),
              title: Text(
                type.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: type.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${items.length} món đã ăn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: type.$4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalCal kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              children: items
                  .map((item) => _ActualMealLogTile(item: item))
                  .toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActualMealLogTile extends StatelessWidget {
  const _ActualMealLogTile({required this.item});

  final ClientMealLogItem item;

  @override
  Widget build(BuildContext context) {
    final localTime = item.loggedAt.toLocal();
    final time =
        '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '$time · ${item.calories} kcal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Đã nạp',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroComparisonSection extends StatelessWidget {
  const _MacroComparisonSection({
    required this.plannedProtein,
    required this.actualProtein,
    required this.plannedCarbs,
    required this.actualCarbs,
    required this.plannedFat,
    required this.actualFat,
  });

  final int plannedProtein;
  final int actualProtein;
  final int plannedCarbs;
  final int actualCarbs;
  final int plannedFat;
  final int actualFat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'So sánh Macros',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Tỷ lệ đạm, tinh bột & chất béo',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MacroBar(
            label: 'Protein',
            subtitle: 'Chất đạm',
            planned: plannedProtein,
            actual: actualProtein,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            accentColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            icon: Icons.fitness_center_rounded,
            unit: 'g',
          ),
          const SizedBox(height: 10),
          _MacroBar(
            label: 'Carbs',
            subtitle: 'Tinh bột',
            planned: plannedCarbs,
            actual: actualCarbs,
            gradientColors: const [Color(0xFFF97316), Color(0xFFC2410C)],
            accentColor: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            icon: Icons.grain_rounded,
            unit: 'g',
          ),
          const SizedBox(height: 10),
          _MacroBar(
            label: 'Fat',
            subtitle: 'Chất béo',
            planned: plannedFat,
            actual: actualFat,
            gradientColors: const [Color(0xFFA855F7), Color(0xFF7E22CE)],
            accentColor: const Color(0xFF9333EA),
            bgColor: const Color(0xFFFAF5FF),
            icon: Icons.water_drop_rounded,
            unit: 'g',
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.subtitle,
    required this.planned,
    required this.actual,
    required this.gradientColors,
    required this.accentColor,
    required this.bgColor,
    required this.icon,
    required this.unit,
  });

  final String label;
  final String subtitle;
  final int planned;
  final int actual;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color bgColor;
  final IconData icon;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($subtitle)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$actual ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    TextSpan(
                      text: '/ $planned $unit ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow(this.label, this.status);

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          _PlanApprovalChip(status: status),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.plan});

  final CoachMealPlanDetail plan;

  @override
  Widget build(BuildContext context) {
    final titleStr = coachMealPlanDisplayTitle(
      title: plan.header.title,
      planType: plan.header.planType,
      startDate: plan.header.startDate,
    );
    final typeLower = plan.header.planType.toLowerCase();
    final scopeLabel = typeLower == 'daily'
        ? 'Ngày'
        : (typeLower == 'weekly'
              ? 'Tuần'
              : (typeLower == 'monthly' ? 'Tháng' : 'Tùy chỉnh'));
    final dateStr = plan.header.startDate != null
        ? _fmtPlanDate(
            plan.header.planType,
            plan.header.startDate,
            plan.header.endDate,
          )
        : 'Ngày 31/07/2026';
    final durationStr = typeLower == 'daily'
        ? '1 ngày'
        : (typeLower == 'weekly' ? '1 tuần' : '1 tháng');

    return _DetailSection(
      title: 'Tổng quan',
      icon: Icons.space_dashboard_rounded,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          _InfoRow('Mô tả', titleStr),
          _InfoRow('Loại cấu hình', scopeLabel),
          _InfoRow('Thời gian', dateStr),
          _InfoRow('Thời lượng', durationStr),
          _StatusInfoRow('Trạng thái', plan.header.status),
        ],
      ),
    );
  }

  static String _dmy(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  static String _fmtPlanDate(String planType, DateTime? start, DateTime? end) {
    if (start == null) return '';
    final type = planType.toLowerCase();
    if (type == 'daily') {
      return 'Ngày ${_dmy(start)}';
    }
    if (end == null) return _dmy(start);
    return '${_dmy(start)} – ${_dmy(end)}';
  }
}

class _NutritionTargetsSection extends StatelessWidget {
  const _NutritionTargetsSection({required this.plan, required this.draft});

  final CoachMealPlanDetail plan;
  final List<_DraftItem> draft;

  @override
  Widget build(BuildContext context) {
    final targetCals = plan.header.targetCalories;
    final minCals = plan.header.minCalories;
    final maxCals = plan.header.maxCalories;

    int totalP = 0;
    int totalC = 0;
    int totalF = 0;
    for (final item in draft) {
      totalP += (item.proteinG ?? 0).round();
      totalC += (item.carbsG ?? 0).round();
      totalF += (item.fatG ?? 0).round();
    }

    final hasCalories = targetCals != null;
    final hasMacros = totalP > 0 || totalC > 0 || totalF > 0;

    return _DetailSection(
      title: 'Mục tiêu dinh dưỡng',
      icon: Icons.insights_rounded,
      iconColor: AppColors.primary,
      child: (!hasCalories && !hasMacros)
          ? const Text(
              'Chưa có mục tiêu dinh dưỡng cho lộ trình này.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCalories) ...[
                  // Hero Calorie Card (System Green Theme)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Mục tiêu Năng lượng',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$targetCals kcal/ngày',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (minCals != null || maxCals != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (minCals != null)
                                Expanded(
                                  child: _CalorieLimitBadge(
                                    icon: Icons.arrow_downward_rounded,
                                    label: 'Món tối thiểu',
                                    value: '$minCals kcal',
                                    color: AppColors.primary,
                                  ),
                                ),
                              if (minCals != null && maxCals != null)
                                const SizedBox(width: 8),
                              if (maxCals != null)
                                Expanded(
                                  child: _CalorieLimitBadge(
                                    icon: Icons.arrow_upward_rounded,
                                    label: 'Món tối đa',
                                    value: '$maxCals kcal',
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (hasMacros) ...[
                  const Text(
                    'Phân bổ Macros',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroCard(
                          icon: Icons.fitness_center_rounded,
                          label: 'Protein',
                          value: '$totalP g',
                          bgColor: AppColors.primary.withValues(alpha: 0.08),
                          borderColor: AppColors.primary.withValues(alpha: 0.2),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroCard(
                          icon: Icons.bakery_dining_rounded,
                          label: 'Carbs',
                          value: '$totalC g',
                          bgColor: AppColors.primary.withValues(alpha: 0.05),
                          borderColor: AppColors.primary.withValues(
                            alpha: 0.18,
                          ),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroCard(
                          icon: Icons.water_drop_outlined,
                          label: 'Fat',
                          value: '$totalF g',
                          bgColor: AppColors.primary.withValues(alpha: 0.08),
                          borderColor: AppColors.primary.withValues(alpha: 0.2),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _CalorieLimitBadge extends StatelessWidget {
  const _CalorieLimitBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachNotesSection extends StatelessWidget {
  const _CoachNotesSection({required this.plan, this.customNotes, this.onEdit});

  final CoachMealPlanDetail plan;
  final String? customNotes;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final rawNotes = customNotes ?? plan.header.coachNotes;
    final notes = rawNotes?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;

    return _DetailSection(
      title: 'Ghi chú từ PT',
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: AppColors.primary,
      child: Material(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasNotes ? notes : 'PT chưa để lại ghi chú.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                      color: hasNotes
                          ? const Color(0xFF374151)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                if (onEdit != null)
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanApprovalChip extends StatelessWidget {
  const _PlanApprovalChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final (label, bgColor, textColor, borderColor) = switch (s) {
      'approved' => (
        'Đã duyệt & gửi',
        const Color(0xFFECFDF5),
        const Color(0xFF047857),
        const Color(0xFFA7F3D0),
      ),
      'active' || 'unapproved' => (
        'Chưa duyệt',
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        const Color(0xFFFECACA),
      ),
      'pending' || 'pendingacceptance' => (
        'Chờ Gymer chấp nhận',
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
        const Color(0xFFFDE68A),
      ),
      'rejected' => (
        'Đã từ chối',
        const Color(0xFFFEF2F2),
        const Color(0xFFB91C1C),
        const Color(0xFFFECACA),
      ),
      _ => (
        coachMealPlanStatusLabel(status),
        coachMealPlanStatusLabel(status) == 'Chưa duyệt'
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF3F4F6),
        coachMealPlanStatusLabel(status) == 'Chưa duyệt'
            ? const Color(0xFFDC2626)
            : const Color(0xFF4B5563),
        coachMealPlanStatusLabel(status) == 'Chưa duyệt'
            ? const Color(0xFFFECACA)
            : const Color(0xFFE5E7EB),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: textColor),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onView,
  });

  final String title;
  final List<_DraftItem> items;
  final Future<void> Function(_DraftItem)? onEdit;
  final void Function(_DraftItem) onView;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, borderColor, iconData) = _sectionColors(title);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Icon(iconData, size: 16, color: textColor),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} món',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Chưa có món nào. Bấm nút + để thêm món.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _DraftItemTile(
                      item: items[i],
                      onTap: () => onView(items[i]),
                      onEdit: onEdit == null ? null : () => onEdit!(items[i]),
                    ),
                    if (i < items.length - 1)
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  static (Color, Color, Color, IconData) _sectionColors(String title) {
    final t = title.toLowerCase();
    if (t.contains('sáng')) {
      return (
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
        const Color(0xFFFFEDD5),
        Icons.wb_sunny_rounded,
      );
    }
    if (t.contains('trưa')) {
      return (
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
        Icons.restaurant_rounded,
      );
    }
    if (t.contains('tối')) {
      return (
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        const Color(0xFFBFDBFE),
        Icons.nightlight_round,
      );
    }
    return (
      const Color(0xFFF5F3FF),
      const Color(0xFF7C3AED),
      const Color(0xFFDDD6FE),
      Icons.bakery_dining_rounded,
    );
  }
}

class _DraftItemTile extends StatelessWidget {
  const _DraftItemTile({
    required this.item,
    required this.onTap,
    required this.onEdit,
  });
  final _DraftItem item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.isCompleted || item.mealLogId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isCompleted
                    ? const Color(0xFFECFDF5)
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.restaurant_rounded,
                  size: 18,
                  color: isCompleted
                      ? const Color(0xFF047857)
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          title: Text(
            item.displayName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isCompleted
                  ? const Color(0xFF047857)
                  : const Color(0xFF111827),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatNutritionFacts(
                    quantityG: item.quantityG,
                    caloriesKcal: item.targetCalories,
                    proteinG: item.proteinG,
                    carbsG: item.carbsG,
                    fatG: item.fatG,
                  ),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 10,
                  runSpacing: 3,
                  children: [
                    if (item.plannedDate != null)
                      _ScheduleLabel(
                        icon: Icons.calendar_today_outlined,
                        text:
                            'Ngày ăn: ${mealPlannedDateLabel(item.plannedDate!)}',
                      ),
                    _ScheduleLabel(
                      icon: Icons.schedule_rounded,
                      text:
                          'Giờ ăn: ${mealScheduledTimeLabel(item.scheduledTime, mealType: item.mealType)}',
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (isCompleted)
                  Text(
                    'Đã ăn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047857),
                    ),
                  )
                else
                  Text(
                    'Chạm để xem chi tiết và công thức',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          isThreeLine: true,
          trailing: onEdit == null
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                )
              : IconButton(
                  tooltip: 'Chỉnh sửa / thay món',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF374151),
                  ),
                  onPressed: onEdit,
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ScheduleLabel extends StatelessWidget {
  const _ScheduleLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _DraftItem {
  _DraftItem({
    required this.id,
    required this.mealType,
    this.foodId,
    this.recipeId,
    required this.displayName,
    this.plannedDate,
    this.scheduledTime,
    this.targetCalories,
    this.quantityG,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.ingredients = const [],
    this.isCompleted = false,
    this.mealLogId,
  });

  factory _DraftItem.fromItem(CoachMealPlanItem it, {DateTime? fallbackDate}) =>
      _DraftItem(
        id: it.id,
        mealType: it.mealType.toLowerCase(),
        foodId: it.foodId,
        recipeId: it.recipeId,
        displayName: it.displayName,
        plannedDate: it.plannedDate ?? fallbackDate,
        scheduledTime: mealScheduledTimeLabel(
          it.scheduledTime,
          mealType: it.mealType,
        ),
        targetCalories: it.targetCalories,
        quantityG: it.quantityG,
        proteinG: it.proteinG,
        carbsG: it.carbsG,
        fatG: it.fatG,
        ingredients: it.ingredients,
        isCompleted: it.isCompleted,
        mealLogId: null,
      );

  String? id;
  final String mealType;
  String? foodId;
  String? recipeId;
  String displayName;
  DateTime? plannedDate;
  String? scheduledTime;
  int? targetCalories;
  double? quantityG;
  double? proteinG;
  double? carbsG;
  double? fatG;
  List<MealPlanIngredientPortion> ingredients;
  bool isCompleted;
  String? mealLogId;

  ClientMealPlanItemPayload toPayload() => ClientMealPlanItemPayload(
    id: id,
    mealType: mealType,
    foodId: foodId,
    recipeId: recipeId,
    plannedDate: plannedDate,
    scheduledTime: scheduledTime,
    targetCalories: targetCalories,
    quantityG: quantityG,
    ingredients: ingredients,
  );
}

class _IngredientPick {
  _IngredientPick({
    required this.id,
    required this.name,
    required this.kind,
    this.calories,
    this.quantityG,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });
  final String id;
  final String name;
  final _IngredientKind kind;
  final int? calories;
  final double? quantityG;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
}

enum _IngredientKind { food, recipe }

class _AddItemResult {
  _AddItemResult({required this.mealType, required this.pick});
  final String mealType;
  final _IngredientPick pick;
}

class _IngredientPickerSheet extends StatefulWidget {
  const _IngredientPickerSheet();
  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final _repo = FoodDiscoveryRepository();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.searchFoods(keyword: q),
        _repo.searchRecipes(keyword: q),
      ]);
      _results = [
        ...(results[0] as List).map(
          (item) => {
            'id': (item as dynamic).id,
            'name': item.nameVi,
            'type': 'food',
            'category': item.category,
            'caloriesKcal': item.caloriesKcal,
            'proteinG': item.proteinG,
            'carbsG': item.carbsG,
            'fatG': item.fatG,
            'quantityG': item.defaultServingG,
          },
        ),
        ...(results[1] as List).map(
          (item) => {
            'id': (item as dynamic).id,
            'name': item.title,
            'type': 'recipe',
            'category': 'Công thức',
            'caloriesKcal': item.totalCalories,
            'quantityG': item.defaultServingG,
          },
        ),
      ].take(20).toList();
    } catch (_) {
      _results = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn món / công thức',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên món...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: _search,
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(),
              if (!_loading && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Gõ và nhấn Enter để tìm kiếm.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              if (_results.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final it = _results[index];
                      final name = (it['name'] ?? it['Name'] ?? 'Món')
                          .toString();
                      final id = (it['id'] ?? it['Id'] ?? '').toString();
                      final calories = _int(it['caloriesKcal']);
                      final kind = it['type'] == 'recipe'
                          ? _IngredientKind.recipe
                          : _IngredientKind.food;
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                          '${(it['category'] ?? it['Category'] ?? '').toString()}\n'
                          '${formatNutritionFacts(quantityG: _double(it['quantityG']), caloriesKcal: calories, proteinG: _double(it['proteinG']), carbsG: _double(it['carbsG']), fatG: _double(it['fatG']))}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _IngredientPick(
                            id: id,
                            name: name,
                            kind: kind,
                            calories: calories,
                            quantityG: _double(it['quantityG']),
                            proteinG: _double(it['proteinG']),
                            carbsG: _double(it['carbsG']),
                            fatG: _double(it['fatG']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static int? _int(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
