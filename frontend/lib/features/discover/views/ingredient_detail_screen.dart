import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';
import '../widgets/allergy_risk_badge.dart';
import 'recipe_detail_screen.dart';

class IngredientDetailScreen extends StatefulWidget {
  const IngredientDetailScreen({
    super.key,
    required this.ingredientId,
    this.allergyMode = 'warn',
  });

  final String ingredientId;
  final String allergyMode;

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  final _repository = FoodDiscoveryRepository();
  IngredientItem? _ingredient;
  List<IngredientRecipeLink> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ingredient = await _repository.getIngredientById(
      widget.ingredientId,
      allergyMode: widget.allergyMode,
    );
    final recipes = await _repository.getIngredientRecipes(widget.ingredientId);
    if (!mounted) return;
    setState(() {
      _ingredient = ingredient;
      _recipes = recipes;
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
        title: const Text('Nguyên liệu'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _ingredient == null
              ? const Center(child: Text('Không tìm thấy nguyên liệu.'))
              : _buildBody(_ingredient!),
    );
  }

  Widget _buildBody(IngredientItem item) {
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
                  item.nameVi,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              AllergyRiskBadge(riskLevel: item.allergyRiskLevel),
            ],
          ),
          if (item.matchedAllergens.isNotEmpty) ...[
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
                'Tên nguyên liệu có thể liên quan dị ứng: ${item.matchedAllergens.join(', ')}.',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            [
              if (item.category != null) item.category!,
              if (item.caloriesKcal != null) '${item.caloriesKcal!.round()} kcal',
              if (item.unitDefault != null) item.unitDefault!,
            ].join(' · '),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          const Text('Công thức dùng nguyên liệu này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        recipeId: r.recipeId,
                        allergyMode: widget.allergyMode,
                      ),
                    ),
                  );
                },
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
}
