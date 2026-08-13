import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/nutrition_format.dart';
import '../models/food_models.dart';
import '../providers/favorite_food_provider.dart';
import '../repositories/food_discovery_repository.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../widgets/allergy_risk_badge.dart';
import 'recipe_detail_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.foodId,
    this.allergyMode = 'warn',
    this.plannedQuantityG,
  });

  final String foodId;
  final String allergyMode;
  final double? plannedQuantityG;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _repository = FoodDiscoveryRepository();
  FoodItem? _food;
  List<RecipeItem> _recipes = [];
  bool _loading = true;
  // Legacy local flag is retained only while the screen is mounted; the shared
  // provider below is the authoritative state used by the UI.
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final favorites = context.read<FavoriteFoodProvider>();
    final food = await _repository.getFoodById(
      widget.foodId,
      allergyMode: widget.allergyMode,
    );
    final recipes = await _repository.getFoodRecipes(widget.foodId);
    await favorites.load();
    if (!mounted) return;
    setState(() {
      _food = food;
      _recipes = recipes;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    final food = _food;
    if (food == null) {
      setState(() => _favoriteBusy = false);
      return;
    }
    final result = await context.read<FavoriteFoodProvider>().toggle(
      FavoriteFoodItem.fromFood(food),
    );
    final ok = result.isSuccess;
    if (!mounted) return;
    if (ok) {
      setState(() {
        _isFavorite = result.isFavorite;
        _favoriteBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Đã thêm yêu thích' : 'Đã bỏ yêu thích'),
        ),
      );
    } else {
      setState(() => _favoriteBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
        title: const Text('Chi tiết món'),
        actions: [
          Consumer<FavoriteFoodProvider>(
            builder: (context, favorites, _) {
              final isFavorite = favorites.isFavorite(widget.foodId);
              final isBusy =
                  _favoriteBusy || favorites.isMutating(widget.foodId);
              return IconButton(
                tooltip: isFavorite
                    ? 'B\u1ecf m\u00f3n kh\u1ecfi y\u00eau th\u00edch'
                    : 'Th\u00eam m\u00f3n v\u00e0o y\u00eau th\u00edch',
                onPressed: isBusy ? null : _toggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _food == null
          ? const Center(child: Text('Không tìm thấy món.'))
          : _buildBody(_food!),
    );
  }

  Widget _buildBody(FoodItem food) {
    final quantityG =
        food.defaultServingG?.toDouble() ?? widget.plannedQuantityG;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  food.nameVi,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AllergyRiskBadge(riskLevel: food.allergyRiskLevel),
            ],
          ),
          if (food.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: food.imageUrl!,
                width: double.infinity,
                height: 200,
                memCacheWidth: 400,
                memCacheHeight: 200,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],
          if (food.matchedAllergens.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Cảnh báo: món có thể chứa ${food.matchedAllergens.join(', ')} trùng với dị ứng của bạn.',
                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (food.description != null && food.description!.isNotEmpty)
            Text(
              food.description!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          _buildNutritionSection(food),
          const SizedBox(height: 16),
          if (quantityG != null ||
              food.estimatedPriceVnd != null ||
              food.category != null ||
              food.region != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (quantityG != null)
                  _chip(
                    'Khối lượng món: '
                    '${formatNutritionNumber(quantityG)} g',
                  ),
                if (food.estimatedPriceVnd != null)
                  _chip(_formatPrice(food.estimatedPriceVnd!)),
                if (food.category != null) _chip(food.category!),
                if (food.region != null) _chip(food.region!),
              ],
            ),
          if (food.allergenLabelsVi.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Thành phần dị ứng ghi nhận',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: food.allergenLabelsVi
                  .map((l) => Chip(label: Text(l)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Công thức liên quan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_recipes.isEmpty)
            const Text(
              'Chưa có công thức.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ..._recipes.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.title),
                subtitle: r.prepTimeMin != null
                    ? Text('${r.prepTimeMin} phút')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipeId: r.id,
                        allergyMode: widget.allergyMode,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logMeal,
              icon: const Icon(Icons.add_chart_outlined),
              label: const Text('Ghi vào nhật ký'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thông tin tham khảo, không thay tư vấn y khoa.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _logMeal() async {
    final food = _food;
    if (food == null) return;

    if (food.allergyRiskLevel == 'high') {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Text(
            'Món này có thể không phù hợp với dị ứng của bạn'
            '${food.matchedAllergens.isNotEmpty ? ' (${food.matchedAllergens.join(', ')})' : ''}. '
            'Bạn vẫn muốn ghi nhật ký?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vẫn ghi'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final ok = await showMealLogSheet(
      context,
      initialFoodId: widget.foodId,
      initialFoodName: food.nameVi,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi vào nhật ký bữa ăn')),
      );
    }
  }

  Widget _buildNutritionSection(FoodItem food) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giá trị dinh dưỡng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionItem(
                      label: 'Năng lượng',
                      value: '${food.caloriesKcal?.round() ?? 0}',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFE53935),
                      bgColor: const Color(0xFFFFEBEE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNutritionItem(
                      label: 'Đạm (Protein)',
                      value: '${food.proteinG?.round() ?? 0}',
                      unit: 'g',
                      icon: Icons.fitness_center_rounded,
                      color: const Color(0xFF1E88E5),
                      bgColor: const Color(0xFFE3F2FD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionItem(
                      label: 'Tinh bột (Carbs)',
                      value: '${food.carbsG?.round() ?? 0}',
                      unit: 'g',
                      icon: Icons.grain_rounded,
                      color: const Color(0xFFFB8C00),
                      bgColor: const Color(0xFFFFF3E0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNutritionItem(
                      label: 'Chất béo (Fat)',
                      value: '${food.fatG?.round() ?? 0}',
                      unit: 'g',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF8E24AA),
                      bgColor: const Color(0xFFF3E5F5),
                    ),
                  ),
                ],
              ),
              if (food.fiberG != null && food.fiberG! > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionItem(
                        label: 'Chất xơ (Fiber)',
                        value: '${food.fiberG!.round()}',
                        unit: 'g',
                        icon: Icons.grass_rounded,
                        color: const Color(0xFF43A047),
                        bgColor: const Color(0xFFE8F5E9),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionItem({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
    );
  }

  String _formatPrice(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formatted VNĐ';
  }
}
