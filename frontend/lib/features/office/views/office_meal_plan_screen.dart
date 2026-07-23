import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/models/meal_plan_responses.dart';
import '../../meal_plan/models/meal_plan_requests.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/utils/subscription_access.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../widgets/office_grocery_section.dart';
import '../widgets/office_meal_roadmap.dart';
import '../widgets/office_plan_summary.dart';

class _BudgetInput {
  const _BudgetInput({required this.amount, required this.minutes});

  final int amount;
  final int minutes;
}

/// Luồng lập kế hoạch dành riêng cho Office.
///
/// Màn hình này cố ý không chứa các chức năng PT/Coach. Ngân sách được thiết
/// lập từ icon trên AppBar và kế hoạch cơm hộp được hiển thị ngay trong body.
class OfficeMealPlanScreen extends StatefulWidget {
  const OfficeMealPlanScreen({super.key});

  @override
  State<OfficeMealPlanScreen> createState() => _OfficeMealPlanScreenState();
}

class _OfficeMealPlanScreenState extends State<OfficeMealPlanScreen> {
  final AdvancedRepository _budgetRepository = AdvancedRepository();
  final MealPlanRepository _mealPlanRepository = MealPlanRepository();
  final UserSubscriptionRepository _subscriptionRepository = UserSubscriptionRepository();

  Map<String, dynamic>? _budget;
  MealPlanDetail? _plan;
  Map<String, dynamic>? _groceryList;
  Map<String, dynamic>? _budgetStatus;
  bool _loadingBudget = true;
  bool _loadingPlan = true;
  bool _generating = false;
  bool _savingBudget = false;
  bool _hasOfficeAccess = false;
  String? _replacingItemId;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadBudget();
    _loadExistingPlan();
  }

  Future<void> _checkAccess() async {
    try {
      final activeSubs = await _subscriptionRepository.getActive();
      final hasAccess = hasOfficeSubscriptionAccess(activeSubs);
      if (mounted) setState(() => _hasOfficeAccess = hasAccess);
    } catch (_) {}
  }

  void _showUpgradePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 26),
            SizedBox(width: 8),
            Text(
              'Kích hoạt Office VIP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Bạn cần nâng cấp gói Office VIP để mở khóa chế độ lên kế hoạch & thực đơn cơm hộp văn phòng này.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpgradePlanScreen()),
              );
            },
            child: const Text('Nâng cấp ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _value(Map<String, dynamic> source, String key, [String fallback = '']) {
    final pascalKey = key[0].toUpperCase() + key.substring(1);
    return (source[key] ?? source[pascalKey] ?? fallback).toString();
  }

  int? _number(Map<String, dynamic>? source, String key) {
    if (source == null) return null;
    return int.tryParse(_value(source, key));
  }

  String _currency(int? value) {
    if (value == null) return 'Chưa thiết lập';
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '$bufferđ';
  }

  void _notice(Object value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _loadBudget() async {
    try {
      final result = await _budgetRepository.budget();
      if (mounted) setState(() => _budget = result);
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _loadingBudget = false);
    }
  }

  Future<void> _loadExistingPlan() async {
    try {
      final plans = await _mealPlanRepository.getPlans(isActive: true);
      final officePlans = plans
          .where((plan) => plan.title.toLowerCase().contains('cơm hộp'))
          .toList()
        ..sort((a, b) {
          final aDate = a.startDate ?? DateTime(1970);
          final bDate = b.startDate ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
      if (officePlans.isEmpty) {
        if (mounted) {
          setState(() {
            _plan = null;
            _groceryList = null;
            _budgetStatus = null;
          });
        }
        return;
      }

      final detail = await _mealPlanRepository.getPlanDetail(officePlans.first.id);
      if (detail == null) {
        if (mounted) {
          setState(() {
            _plan = null;
            _groceryList = null;
            _budgetStatus = null;
          });
        }
        return;
      }
      final results = await Future.wait([
        _mealPlanRepository.getGroceryList(detail.id),
        _mealPlanRepository.getBudgetStatus(detail.id),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = detail;
        _groceryList = results[0];
        _budgetStatus = results[1];
      });
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadBudget(), _loadExistingPlan()]);
  }

  Future<void> _openBudgetSettings() async {
    if (!_hasOfficeAccess) {
      _showUpgradePrompt();
      return;
    }
    if (_loadingBudget || _savingBudget) return;
    final previousAmount = _number(_budget, 'budgetVnd');
    final previousMinutes = _number(_budget, 'timeLimitMin');
    final input = await showDialog<_BudgetInput>(
      context: context,
      builder: (_) => _OfficeBudgetDialog(
        initialAmount: previousAmount,
        initialMinutes: previousMinutes,
      ),
    );
    if (input == null || !mounted) return;

    final targetChanged = previousAmount != input.amount
        || previousMinutes != input.minutes;
    setState(() => _savingBudget = true);
    try {
      final saved = await _budgetRepository.saveBudget(
        id: _budget == null ? null : _value(_budget!, 'id'),
        amount: input.amount,
        minutes: input.minutes,
      );
      if (!mounted) return;
      setState(() {
        _budget = saved;
        if (targetChanged) {
          _plan = null;
          _groceryList = null;
          _budgetStatus = null;
        }
      });
      _notice(
        targetChanged
            ? 'Ngân sách đã thay đổi. Hãy tạo lại kế hoạch cơm hộp.'
            : 'Đã lưu mục tiêu ngân sách tuần.',
      );
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _savingBudget = false);
    }
  }

  Future<void> _generatePlan() async {
    if (!_hasOfficeAccess) {
      _showUpgradePrompt();
      return;
    }
    if (_budget == null) {
      _notice('Hãy thiết lập mục tiêu ngân sách trước khi tạo kế hoạch.');
      await _openBudgetSettings();
      return;
    }

    setState(() => _generating = true);
    try {
      final plan = await _mealPlanRepository.generateBudgetLunchboxPlan();
      final results = await Future.wait([
        _mealPlanRepository.getGroceryList(plan.id),
        _mealPlanRepository.getBudgetStatus(plan.id),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _groceryList = results[0];
        _budgetStatus = results[1];
      });
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _replaceMeal(MealPlanItemDetail item) async {
    final plan = _plan;
    if (plan == null || _replacingItemId != null) return;

    setState(() => _replacingItemId = item.id);
    try {
      final alternatives = await _mealPlanRepository.getAlternatives(
        plan.id,
        item.id,
      );
      if (!mounted) return;
      if (alternatives.isEmpty) {
        _notice(
          'Chưa có món khác phù hợp với loại bữa và thời gian nấu.',
        );
        return;
      }

      final plannedCost = _number(_budgetStatus, 'plannedCost');
      final budgetLimit = _number(_budgetStatus, 'budgetLimit');
      int? projectedCost(MealPlanItemDetail alternative) {
        if (plannedCost == null) return null;
        return plannedCost -
            (item.estimatedPriceVnd ?? 0) +
            (alternative.estimatedPriceVnd ?? 0);
      }

      bool exceedsBudget(MealPlanItemDetail alternative) {
        final projected = projectedCost(alternative);
        return projected != null &&
            budgetLimit != null &&
            projected > budgetLimit;
      }

      bool worsensBudget(MealPlanItemDetail alternative) {
        final projected = projectedCost(alternative);
        return exceedsBudget(alternative) &&
            projected != null &&
            plannedCost != null &&
            projected > plannedCost;
      }

      final selected = await showModalBottomSheet<MealPlanItemDetail>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn món thay thế',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thay “${item.displayName}” bằng món phù hợp khác.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: alternatives.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final alternative = alternatives[index];
                      final isOverBudget = exceedsBudget(alternative);
                      final isCheaper = projectedCost(alternative) != null &&
                          plannedCost != null &&
                          projectedCost(alternative)! < plannedCost;
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.restaurant_menu_outlined),
                        ),
                        title: Text(
                          alternative.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${alternative.targetCalories ?? 0} kcal · '
                                    '${_currency(alternative.estimatedPriceVnd)}',
                              ),
                              if (isOverBudget)
                                TextSpan(
                                  text: isCheaper
                                      ? '\nGiảm chi phí nhưng kế hoạch vẫn vượt ngân sách'
                                      : '\nVượt mục tiêu ngân sách',
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, alternative),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (selected == null || !mounted) return;

      if (worsensBudget(selected)) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Món này vượt ngân sách'),
            content: Text(
              'Nếu đổi sang ${selected.displayName}, chi phí dự kiến sẽ là '
              '${_currency(projectedCost(selected))} / ${_currency(budgetLimit)}. '
              'Bạn vẫn muốn đổi món?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Chọn món khác'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn đổi món'),
              ),
            ],
          ),
        );
        if (shouldContinue != true || !mounted) return;
      }

      final updatedPlan = await _mealPlanRepository.replaceItem(
        plan.id,
        item.id,
        selected.foodId ?? selected.recipeId ?? '',
      );
      final results = await Future.wait([
        _mealPlanRepository.getGroceryList(updatedPlan.id),
        _mealPlanRepository.getBudgetStatus(updatedPlan.id),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = updatedPlan;
        _groceryList = results[0];
        _budgetStatus = results[1];
      });
      _notice('Đã đổi sang ${selected.displayName}.');
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _replacingItemId = null);
    }
  }

  void _openMealRecipe(MealPlanItemDetail item) {
    final recipeId = item.recipeId;
    if (recipeId == null || recipeId.isEmpty) {
      _notice('Món này chưa được liên kết với công thức nấu.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kế hoạch cơm hộp'),
          actions: [
            IconButton(
              tooltip: 'Mục tiêu ngân sách',
              onPressed: _loadingBudget || _savingBudget ? null : _openBudgetSettings,
              icon: Badge(
                isLabelVisible: _budget == null && !_loadingBudget,
                child: _loadingBudget
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.route_outlined), text: 'Kế hoạch'),
              Tab(
                icon: Icon(Icons.shopping_basket_outlined),
                text: 'Danh sách đi chợ',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OfficeBudgetSummaryCard(
                    amount: _currency(_number(_budget, 'budgetVnd')),
                    minutes: _number(_budget, 'timeLimitMin'),
                    plannedCost: _number(_budgetStatus, 'plannedCost'),
                    budgetLimit: _number(_budgetStatus, 'budgetLimit'),
                    onEdit: _openBudgetSettings,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kế hoạch ăn uống Office',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ưu tiên bữa trưa dễ mang theo, phù hợp ngân sách và thời gian chuẩn bị của bạn.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _generating || _savingBudget ? null : _generatePlan,
                    icon: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _generating
                          ? 'Đang tạo kế hoạch...'
                          : 'Tạo kế hoạch cơm hộp',
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_loadingPlan)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_plan == null)
                    const OfficeEmptyPlanCard()
                  else ...[
                    OfficePlanOverview(plan: _plan!),
                    const SizedBox(height: 12),
                    OfficeMealRoadmapSection(
                      plan: _plan!,
                      onReplaceMeal: _replaceMeal,
                      onOpenMeal: _openMealRecipe,
                      replacingItemId: _replacingItemId,
                    ),
                  ],
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: _refresh,
              child: OfficeGroceryTab(
                data: _groceryList,
                currency: _currency,
                loading: _loadingPlan,
                hasPlan: _plan != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeBudgetDialog extends StatefulWidget {
  const _OfficeBudgetDialog({
    required this.initialAmount,
    required this.initialMinutes,
  });

  final int? initialAmount;
  final int? initialMinutes;

  @override
  State<_OfficeBudgetDialog> createState() => _OfficeBudgetDialogState();
}

class _OfficeBudgetDialogState extends State<_OfficeBudgetDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _minutesController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
    _minutesController = TextEditingController(
      text: widget.initialMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text.trim());
    final minutes = int.tryParse(_minutesController.text.trim());
    if (amount == null || amount <= 0 || minutes == null || minutes <= 0) {
      setState(() {
        _validationMessage = 'Vui lòng nhập ngân sách và thời gian hợp lệ.';
      });
      return;
    }
    Navigator.pop(
      context,
      _BudgetInput(amount: amount, minutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(child: Text('Mục tiêu ngân sách')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thiết lập ngân sách tối đa cho 7 ngày. Hệ thống chỉ tạo kế hoạch khi tổng chi phí dự kiến không vượt hạn mức này.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách tuần (VND)',
                hintText: 'Ví dụ: 350000',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Thời gian nấu tối đa (phút)',
                hintText: 'Ví dụ: 30',
                prefixIcon: Icon(Icons.schedule_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _validationMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Lưu mục tiêu'),
        ),
      ],
    );
  }
}
