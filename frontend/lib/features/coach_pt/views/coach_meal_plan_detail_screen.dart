import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../coach_pt.dart';

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

class _CoachMealPlanDetailScreenState extends State<CoachMealPlanDetailScreen> {
  bool _dirty = false;
  String? _initializedPlanId;
  late final List<_DraftItem> _draft;

  @override
  void initState() {
    super.initState();
    _draft = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachMealPlanProvider>().loadPlanDetail(widget.planId);
    });
  }

  CoachMealPlanDetail? get _plan =>
      context.read<CoachMealPlanProvider>().selectedPlan;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
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
        _draft.addAll(entry.value.map(_DraftItem.fromItem));
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OverviewSection(plan: plan),
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
              children: _buildMealSections(context, plan, readOnly: isReadOnly),
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
        ? FoodDetailScreen(foodId: item.foodId!)
        : item.recipeId != null
        ? RecipeDetailScreen(recipeId: item.recipeId!)
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
    if (action == 'delete') {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.restaurant_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          item.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${formatNutritionFacts(quantityG: item.quantityG, caloriesKcal: item.targetCalories, proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG)}'
            '\nChạm để xem chi tiết và công thức',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
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
  });

  factory _DraftItem.fromItem(CoachMealPlanItem it) => _DraftItem(
    id: it.id,
    mealType: it.mealType.toLowerCase(),
    foodId: it.foodId,
    recipeId: it.recipeId,
    displayName: it.displayName,
    plannedDate: it.plannedDate,
    scheduledTime: it.scheduledTime,
    targetCalories: it.targetCalories,
    quantityG: it.quantityG,
    proteinG: it.proteinG,
    carbsG: it.carbsG,
    fatG: it.fatG,
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

  ClientMealPlanItemPayload toPayload() => ClientMealPlanItemPayload(
    id: id,
    mealType: mealType,
    foodId: foodId,
    recipeId: recipeId,
    plannedDate: plannedDate,
    scheduledTime: scheduledTime,
    targetCalories: targetCalories,
    quantityG: quantityG,
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
            'quantityG': 100,
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
