import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class RecommendedMealCard extends StatelessWidget {
  const RecommendedMealCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.calories,
    this.imageUrl,
    required this.onTap,
    this.color = AppColors.primary,
    this.bgColor = const Color(0xFFE8F5E9),
  });

  final String title;
  final String subtitle;
  final int calories;
  final String? imageUrl;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.progressBackground),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  size: 32,
                  color: color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$calories kcal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendedMealSection extends StatelessWidget {
  const RecommendedMealSection({
    super.key,
    this.onViewAll,
    required this.onItemTap,
    required this.items,
  });

  final VoidCallback? onViewAll;
  final void Function(RecommendedMealItem item) onItemTap;
  final List<RecommendedMealItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gợi ý hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: const Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return RecommendedMealCard(
                title: item.title,
                subtitle: item.subtitle,
                calories: item.calories,
                color: item.color,
                bgColor: item.bgColor,
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecommendedMealItem {
  final String title;
  final String subtitle;
  final int calories;
  final String? imageUrl;
  final Color color;
  final Color bgColor;
  final dynamic data;

  const RecommendedMealItem({
    required this.title,
    required this.subtitle,
    required this.calories,
    this.imageUrl,
    this.color = AppColors.primary,
    this.bgColor = const Color(0xFFE8F5E9),
    this.data,
  });
}
