import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../discover/views/safe_recommendations_screen.dart';
import '../models/meal_plan_models.dart';
import '../repositories/meal_plan_repository.dart';

class MealPlanTodayScreen extends StatefulWidget {
  const MealPlanTodayScreen({super.key, this.onMealLogged});

  final VoidCallback? onMealLogged;

  @override
  State<MealPlanTodayScreen> createState() => _MealPlanTodayScreenState();
}

class _MealPlanTodayScreenState extends State<MealPlanTodayScreen> {
  final _repository = MealPlanRepository();
  UserMealPlan? _plan;
  MealPlanAdherence? _adherence;
  bool _loading = true;
  String? _error;
  String? _completingItemId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = DateTime.now();
      final plan = await _repository.getByDate(today);
      final adherence = await _repository.getAdherence(today);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _adherence = adherence;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được kế hoạch hôm nay.';
      });
    }
  }

  Future<void> _completeItem(MealPlanItemModel item) async {
    setState(() => _completingItemId = item.id);
    try {
      await _repository.completeItem(item.id);
      widget.onMealLogged?.call();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận bữa ăn theo kế hoạch.')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Không ghi nhận được.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiMessageTranslator.translate(msg))),
      );
    } finally {
      if (mounted) setState(() => _completingItemId = null);
    }
  }

  void _openDiscover() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SafeRecommendationsScreen()),
    ).then((_) => _load());
  }

  void _openItem(MealPlanItemModel item) {
    if (item.isFood && item.foodId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: item.foodId!),
        ),
      );
    } else if (item.recipeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipeId: item.recipeId!,
            plannedQuantityG: item.quantityG,
            plannedIngredients: item.ingredients,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch hôm nay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : _plan == null || _plan!.items.isEmpty
          ? _buildEmpty()
          : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có kế hoạch cho hôm nay.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo từ gợi ý thực đơn an toàn hoặc thêm món trong Khám phá.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _openDiscover,
            child: const Text('Mở gợi ý & lưu kế hoạch'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final plan = _plan!;
    final adherence = _adherence;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (adherence != null && adherence.totalCount > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tuân thủ kế hoạch',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${adherence.completedCount}/${adherence.totalCount} bữa · '
                      '~${adherence.actualKcal.round()}/${adherence.plannedKcal} kcal',
                    ),
                    if (adherence.deviationPercent != null)
                      Text(
                        'Lệch ${adherence.deviationPercent!.toStringAsFixed(0)}% so với kế hoạch',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu ~${plan.targetCalories} kcal',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...plan.items.map(_buildItemTile),
        ],
      ),
    );
  }

  Widget _buildItemTile(MealPlanItemModel item) {
    final busy = _completingItemId == item.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openItem(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealTypeLabelVi(item.mealType),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatNutritionFacts(
                        quantityG: item.quantityG,
                        caloriesKcal: item.targetCalories,
                        proteinG: item.proteinG,
                        carbsG: item.carbsG,
                        fatG: item.fatG,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (item.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Đã ăn',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: busy ? null : () => _completeItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Đã ăn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
