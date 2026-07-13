import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../widgets/allergy_risk_badge.dart';
import 'recipe_detail_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.foodId,
    this.allergyMode = 'warn',
  });

  final String foodId;
  final String allergyMode;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _repository = FoodDiscoveryRepository();
  FoodItem? _food;
  List<RecipeItem> _recipes = [];
  bool _loading = true;
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final food = await _repository.getFoodById(widget.foodId, allergyMode: widget.allergyMode);
    final recipes = await _repository.getFoodRecipes(widget.foodId);
    final favorites = await _repository.getFavorites();
    if (!mounted) return;
    setState(() {
      _food = food;
      _recipes = recipes;
      _isFavorite = favorites.any((f) => f.foodId == widget.foodId);
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    final ok = _isFavorite
        ? await _repository.removeFavorite(widget.foodId)
        : await _repository.addFavorite(widget.foodId);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _isFavorite = !_isFavorite;
        _favoriteBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFavorite ? 'Đã thêm yêu thích' : 'Đã bỏ yêu thích')),
      );
    } else {
      setState(() => _favoriteBusy = false);
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
          IconButton(
            onPressed: _favoriteBusy ? null : _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : AppColors.primary,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _food == null
              ? const Center(child: Text('Không tìm thấy món.'))
              : _buildBody(_food!),
    );
  }

  Widget _buildBody(FoodItem food) {
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              AllergyRiskBadge(riskLevel: food.allergyRiskLevel),
            ],
          ),
          if (food.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                food.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
            Text(food.description!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (food.caloriesKcal != null) _chip('${food.caloriesKcal!.round()} kcal'),
              if (food.proteinG != null) _chip('${food.proteinG!.round()}g đạm'),
              if (food.carbsG != null) _chip('C ${food.carbsG!.round()}g'),
              if (food.fatG != null) _chip('F ${food.fatG!.round()}g'),
              if (food.fiberG != null) _chip('Chất xơ ${food.fiberG!.round()}g'),
              if (food.defaultServingG != null) _chip('${food.defaultServingG}g/khẩu phần'),
              if (food.estimatedPriceVnd != null) _chip(_formatPrice(food.estimatedPriceVnd!)),
              if (food.category != null) _chip(food.category!),
              if (food.region != null) _chip(food.region!),
            ],
          ),
          if (food.allergenLabelsVi.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Thành phần dị ứng ghi nhận', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: food.allergenLabelsVi.map((l) => Chip(label: Text(l))).toList(),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Công thức liên quan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_recipes.isEmpty)
            const Text('Chưa có công thức.', style: TextStyle(color: AppColors.textSecondary))
          else
            ..._recipes.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.title),
                subtitle: r.prepTimeMin != null ? Text('${r.prepTimeMin} phút') : null,
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vẫn ghi')),
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

  Widget _chip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
    );
  }

  String _formatPrice(int amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K đ';
    return '$amount đ';
  }
}
