import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';
import '../widgets/allergy_risk_badge.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.allergyMode = 'warn',
  });

  final String recipeId;
  final String allergyMode;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _repository = FoodDiscoveryRepository();
  RecipeItem? _recipe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recipe = await _repository.getRecipeById(
      widget.recipeId,
      allergyMode: widget.allergyMode,
    );
    if (!mounted) return;
    setState(() {
      _recipe = recipe;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Công thức'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _recipe == null
              ? const Center(child: Text('Không tìm thấy công thức.'))
              : _buildBody(_recipe!),
    );
  }

  Widget _buildBody(RecipeItem recipe) {
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
                  recipe.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              AllergyRiskBadge(riskLevel: recipe.allergyRiskLevel),
            ],
          ),
          if (recipe.matchedAllergens.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Nguyên liệu/món liên quan có thể chứa: ${recipe.matchedAllergens.join(', ')}.',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
              ),
            ),
          ],
          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(recipe.description!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          const Text('Nguyên liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (recipe.ingredients.isEmpty)
            const Text('Chưa có danh sách nguyên liệu.')
          else
            ...recipe.ingredients.map(
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatIngredientLine(i),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logMeal(recipe),
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

  Future<void> _logMeal(RecipeItem recipe) async {
    if (recipe.allergyRiskLevel == 'high') {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Text(
            'Công thức này có thể không phù hợp với dị ứng của bạn'
            '${recipe.matchedAllergens.isNotEmpty ? ' (${recipe.matchedAllergens.join(', ')})' : ''}. '
            'Bạn vẫn muốn ghi nhật ký?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vẫn ghi')),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final ok = await showMealLogSheet(
      context,
      initialRecipeId: widget.recipeId,
      initialRecipeName: recipe.title,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi vào nhật ký bữa ăn')),
      );
    }
  }

  String _formatIngredientLine(RecipeIngredientItem item) {
    final name = item.ingredientName.trim().isEmpty ? 'Nguyên liệu' : item.ingredientName.trim();
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toStringAsFixed(0)
        : item.quantity.toStringAsFixed(1);
    final unit = item.unit.trim();
    final amount = unit.isEmpty ? qty : '$qty $unit';
    return item.notes != null && item.notes!.trim().isNotEmpty
        ? '$name — $amount (${item.notes!.trim()})'
        : '$name — $amount';
  }
}
