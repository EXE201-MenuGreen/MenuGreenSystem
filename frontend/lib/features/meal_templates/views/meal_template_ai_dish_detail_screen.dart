import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/meal_template_models.dart';

class AiScanDishDetailScreen extends StatelessWidget {
  const AiScanDishDetailScreen({
    super.key,
    required this.dishName,
    required this.ingredients,
    required this.quantityG,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sourceType,
  });

  final String dishName;
  final List<MealTemplateIngredient> ingredients;
  final double quantityG;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? sourceType;

  bool get _isAiScan =>
      (sourceType ?? '').toLowerCase() == 'aiscan' ||
      (sourceType ?? '').toLowerCase() == 'ai_scan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Chi tiết món ăn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isAiScan) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Từ AI Scan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              dishName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${quantityG.toStringAsFixed(0)} g — ước tính cho một khẩu phần',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _buildNutritionCard(),
            const SizedBox(height: 24),
            const Text(
              'Nguyên liệu cấu thành',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${ingredients.length} nguyên liệu',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (ingredients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Món này chưa có thông tin nguyên liệu chi tiết.',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...ingredients.map(_buildIngredientTile),
            const SizedBox(height: 16),
            const Text(
              'Thông tin tham khảo, không thay tư vấn y khoa.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dinh dưỡng ước tính',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Năng lượng', '${caloriesKcal.round()} kcal'),
              _metric('Đạm', '${proteinG.toStringAsFixed(1)} g'),
              _metric('Tinh bột', '${carbsG.toStringAsFixed(1)} g'),
              _metric('Chất béo', '${fatG.toStringAsFixed(1)} g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(MealTemplateIngredient ingredient) {
    final quantityLabel = ingredient.unit.trim().isEmpty
        ? ingredient.quantity.toStringAsFixed(0)
        : '${ingredient.quantity.toStringAsFixed(0)} ${ingredient.unit}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            quantityLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
