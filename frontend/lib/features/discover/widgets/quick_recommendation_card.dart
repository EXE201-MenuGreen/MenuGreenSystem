import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';

class QuickRecommendationCard extends StatelessWidget {
  const QuickRecommendationCard({
    super.key,
    required this.isLoading,
    required this.error,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.hasAllergy = false,
    this.onRetry,
    this.onUseAll,
    this.onMealTap,
  });

  final bool isLoading;
  final String? error;
  final RecommendationItem? breakfast;
  final RecommendationItem? lunch;
  final RecommendationItem? dinner;
  final bool hasAllergy;
  final VoidCallback? onRetry;
  final VoidCallback? onUseAll;
  final void Function(RecommendationItem)? onMealTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeleton();
    }

    if (error != null) {
      return _buildError(context);
    }

    final meals = <RecommendationItem?>[breakfast, lunch, dinner];
    final hasAny = meals.any((m) => m != null);

    if (!hasAny) {
      return _buildEmpty(context);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gợi ý hôm nay',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (hasAllergy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'An toàn với dị ứng',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (i) {
            final meal = meals[i];
            if (meal == null) return const SizedBox.shrink();
            return _MealRow(
              meal: meal,
              mealIndex: i,
              onTap: onMealTap,
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUseAll,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Dùng tất cả'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: _SkeletonLine(width: 140, height: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: _SkeletonLine(width: double.infinity, height: 20),
          )),
          const SizedBox(height: 16),
          const _SkeletonLine(width: double.infinity, height: 44),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            error ?? 'Không thể tải gợi ý',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Chưa có gợi ý nào hôm nay',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.mealIndex,
    this.onTap,
  });

  final RecommendationItem meal;
  final int mealIndex;
  final void Function(RecommendationItem)? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _mealIcon(mealIndex);
    final hasMatchReason = meal.matchReason != null && meal.matchReason!.isNotEmpty;

    return InkWell(
      onTap: onTap != null ? () => onTap!(meal) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasMatchReason) ...[
                    const SizedBox(height: 2),
                    Text(
                      meal.matchReason!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.caloriesKcal.round()} kcal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${meal.proteinG.round()}g đạm · ${_formatPrice(meal.estimatedPriceVnd)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static (IconData, Color) _mealIcon(int index) {
    switch (index) {
      case 0:
        return (Icons.wb_sunny_outlined, Colors.orange);
      case 1:
        return (Icons.lunch_dining, Colors.blue);
      case 2:
        return (Icons.dinner_dining, Colors.purple);
      default:
        return (Icons.restaurant, AppColors.primary);
    }
  }

  static String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return '$price';
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
