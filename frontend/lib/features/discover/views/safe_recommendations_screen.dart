import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../models/food_models.dart';
import '../providers/favorite_food_provider.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../repositories/recommendation_repository.dart';
import 'food_detail_screen.dart';
import 'recipe_detail_screen.dart';

class SafeRecommendationsScreen extends StatefulWidget {
  const SafeRecommendationsScreen({super.key, this.allergyMode = 'warn'});

  final String allergyMode;

  @override
  State<SafeRecommendationsScreen> createState() =>
      _SafeRecommendationsScreenState();
}

class _SafeRecommendationsScreenState extends State<SafeRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  final _repository = RecommendationRepository();
  final _mealPlanRepository = MealPlanRepository();
  bool _savingPlan = false;
  late final TabController _tabController;

  bool _excludeAllergies = true;
  int _targetCalories = 2000;
  final int _budgetVnd = 50000;
  bool _loading = false;
  String? _error;

  List<RecommendationItem> _calories = [];
  List<RecommendationItem> _lunch = [];
  List<RecommendationItem> _eco = [];
  DailyMenuPlan? _dailyMenu;

  @override
  void initState() {
    super.initState();
    context.read<FavoriteFoodProvider>().load();
    _tabController = TabController(length: 4, vsync: this);
    _loadTargetCalories();
    _loadTab(0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadTab(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTargetCalories() async {
    try {
      final summary = await NutritionTrackingRepository().getDailySummary(
        DateTime.now(),
      );
      if (!mounted || summary == null) return;
      final target = summary.targetCalories.round();
      if (target > 0) setState(() => _targetCalories = target);
    } catch (_) {
      // Giữ mặc định 2000.
    }
  }

  Future<void> _loadTab(int index) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      switch (index) {
        case 0:
          _calories = await _repository.recommendCalories(
            targetCalories: _targetCalories,
            excludeUserAllergies: _excludeAllergies,
          );
        case 1:
          _lunch = await _repository.recommendLunch(
            targetCalories: (_targetCalories * 0.35).round(),
            budgetVnd: _budgetVnd,
            excludeUserAllergies: _excludeAllergies,
          );
        case 2:
          _eco = await _repository.recommendEco(
            budgetVnd: _budgetVnd,
            limitMinutes: 30,
            excludeUserAllergies: _excludeAllergies,
          );
        case 3:
          _dailyMenu = await _repository.recommendDailyMenu(
            targetCalories: _targetCalories,
            excludeUserAllergies: _excludeAllergies,
          );
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được gợi ý. Thử lại sau.';
      });
    }
  }

  void _openItem(RecommendationItem item) {
    if (item.isFood) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(
            foodId: item.id,
            allergyMode: widget.allergyMode,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipeId: item.id,
            allergyMode: widget.allergyMode,
          ),
        ),
      );
    }
  }

  void _openDailyItem(DailyMenuPlanItem item) {
    if (item.isFood) {
      final foodId = item.foodId ?? item.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FoodDetailScreen(foodId: foodId, allergyMode: widget.allergyMode),
        ),
      );
    } else {
      final recipeId = item.recipeId ?? item.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipeId: recipeId,
            allergyMode: widget.allergyMode,
          ),
        ),
      );
    }
  }

  Future<void> _saveDailyMenuAsPlan() async {
    final plan = _dailyMenu;
    if (plan == null || plan.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có thực đơn để lưu.')));
      return;
    }

    setState(() => _savingPlan = true);
    try {
      await _mealPlanRepository.createFromDailyMenu(
        plannedDate: DateTime.now(),
        targetCalories: plan.targetCalories > 0
            ? plan.targetCalories
            : _targetCalories,
        items: plan.items.map((e) => e.toPlanItemJson()).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu kế hoạch ăn hôm nay.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _savingPlan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Gợi ý an toàn'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Loại món trùng dị ứng'),
                  subtitle: const Text('ExcludeUserAllergies — mặc định bật'),
                  value: _excludeAllergies,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _excludeAllergies = v);
                    _loadTab(_tabController.index);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mục tiêu: $_targetCalories kcal/ngày',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _loadTab(_tabController.index),
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Calories'),
              Tab(text: 'Bữa trưa'),
              Tab(text: 'Tiết kiệm'),
              Tab(text: 'Cả ngày'),
            ],
          ),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_calories),
                _buildList(_lunch),
                _buildList(_eco),
                _buildDailyMenu(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Gợi ý rule-based, ưu tiên an toàn dị ứng. Không thay tư vấn y khoa.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<RecommendationItem> items) {
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (!_loading && items.isEmpty) {
      return const Center(child: Text('Chưa có gợi ý phù hợp.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${item.type} · ${item.caloriesKcal.round()} kcal · ${item.estimatedPriceVnd}đ · ${item.cookingTimeMin} phút',
          ),
          trailing: Consumer<FavoriteFoodProvider>(
            builder: (context, favorites, _) {
              if (!item.isFood) return const Icon(Icons.chevron_right);
              final isFavorite = favorites.isFavorite(item.id);
              final isBusy = favorites.isMutating(item.id);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isFavorite
                        ? 'B\u1ecf m\u00f3n kh\u1ecfi y\u00eau th\u00edch'
                        : 'Th\u00eam m\u00f3n v\u00e0o y\u00eau th\u00edch',
                    onPressed: isBusy
                        ? null
                        : () async {
                            final result = await favorites.toggle(
                              FavoriteFoodItem.fromRecommendation(item),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: result.isSuccess
                                    ? AppColors.primary
                                    : Colors.red.shade700,
                              ),
                            );
                          },
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColors.primary,
                          ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              );
            },
          ),
          onTap: () => _openItem(item),
        );
      },
    );
  }

  Widget _buildDailyMenu() {
    final plan = _dailyMenu;
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (plan == null || plan.items.isEmpty) {
      return const Center(child: Text('Chưa có thực đơn gợi ý.'));
    }
    const slots = ['Bữa sáng', 'Bữa trưa', 'Bữa tối', 'Bữa phụ'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tổng ~${plan.totalCalories} kcal (mục tiêu ${plan.targetCalories})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _savingPlan ? null : _saveDailyMenuAsPlan,
          icon: _savingPlan
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.bookmark_add_outlined),
          label: const Text('Lưu làm kế hoạch hôm nay'),
        ),
        const SizedBox(height: 12),
        ...List.generate(plan.items.length, (i) {
          final item = plan.items[i];
          final label = i < slots.length ? slots[i] : 'Bữa ${i + 1}';
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            title: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            subtitle: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            trailing: Text('${item.targetCalories} kcal'),
            onTap: () => _openDailyItem(item),
          );
        }),
      ],
    );
  }
}
