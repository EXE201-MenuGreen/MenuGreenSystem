import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
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
    final instructionSteps = recipe.instructions == null
        ? const <String>[]
        : _instructionSteps(recipe.instructions!);
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
          if (recipe.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: recipe.imageUrl!,
                width: double.infinity,
                height: 200,
                cacheWidth: 400,
                cacheHeight: 200,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],
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
          if (_hasMetadata(recipe)) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (recipe.prepTimeMin != null) _chip('Sơ chế ${recipe.prepTimeMin} phút'),
                if (recipe.cookTimeMin != null) _chip('Nấu ${recipe.cookTimeMin} phút'),
                if (recipe.totalTimeMin != null) _chip('Tổng ${recipe.totalTimeMin} phút'),
                if (recipe.servings != null) _chip('${recipe.servings} khẩu phần'),
                if (recipe.difficulty != null) _chip(recipe.difficulty!),
                if (recipe.mealType != null) _chip(recipe.mealType!),
                if (recipe.estimatedPriceVnd != null) _chip(_formatPrice(recipe.estimatedPriceVnd!)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text('Nguyên liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (recipe.ingredients.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.deepOrange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Công thức chưa có định lượng nguyên liệu chi tiết. '
                      'Bạn vẫn có thể thực hiện theo các bước bên dưới.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
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
          if (instructionSteps.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Hướng dẫn nấu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${instructionSteps.length} bước thực hiện',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ...instructionSteps.asMap().entries.map(
              (entry) => _instructionStepCard(
                number: entry.key + 1,
                instruction: entry.value,
                isLast: entry.key == instructionSteps.length - 1,
              ),
            ),
          ],
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

  List<String> _instructionSteps(String rawInstructions) {
    final raw = rawInstructions.trim();
    if (raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final steps = decoded
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .map(_removeStepPrefix)
            .toList();
        if (steps.isNotEmpty) return steps;
      }
    } catch (_) {
      // Some legacy recipes store instructions as plain text.
    }

    final byLine = raw
        .split(RegExp(r'[\r\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (byLine.length > 1) return byLine.map(_removeStepPrefix).toList();

    final matches = RegExp(
      r'(?:Bước|Buoc)\s*\d+\s*[:.)-]?\s*(.*?)(?=(?:Bước|Buoc)\s*\d+\s*[:.)-]?|$)',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(raw);
    final extracted = matches
        .map((match) => (match.group(1) ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return extracted.isNotEmpty ? extracted : [raw];
  }

  String _removeStepPrefix(String value) {
    return value
        .replaceFirst(
          RegExp(
            r'^(?:Bước|Buoc)\s*\d+\s*[:.)-]?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  Widget _instructionStepCard({
    required int number,
    required String instruction,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                instruction,
                style: const TextStyle(
                  color: AppColors.textDark,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMetadata(RecipeItem recipe) {
    return recipe.prepTimeMin != null ||
        recipe.cookTimeMin != null ||
        recipe.totalTimeMin != null ||
        recipe.servings != null ||
        recipe.difficulty != null ||
        recipe.mealType != null ||
        recipe.estimatedPriceVnd != null;
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
