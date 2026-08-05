import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';

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
    final cardWidth = context.valueForDevice(
      phone: 170.0,
      tablet: 200.0,
      desktop: 220.0,
    );
    final imageHeight = context.valueForDevice(
      phone: 90.0,
      tablet: 100.0,
      desktop: 110.0,
    );
    final borderRadius = context.valueForDevice(
      phone: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );
    final padding = context.valueForDevice(
      phone: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );
    final titleFontSize = context.valueForDevice(
      phone: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );
    final iconSize = context.valueForDevice(
      phone: 38.0,
      tablet: 44.0,
      desktop: 50.0,
    );
    final badgePaddingH = context.valueForDevice(
      phone: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );
    final badgePaddingV = context.valueForDevice(
      phone: 4.0,
      tablet: 5.0,
      desktop: 6.0,
    );
    final subtitlePaddingH = context.valueForDevice(
      phone: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );
    final subtitlePaddingV = context.valueForDevice(
      phone: 3.0,
      tablet: 4.0,
      desktop: 4.0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: context.valueForDevice(phone: 14.0, tablet: 16.0, desktop: 18.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Icon area with gradient overlay
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bgColor,
                    color.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant,
                      size: iconSize,
                      color: color,
                    ),
                  ),
                  // Calorie badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, size: 12, color: color),
                          const SizedBox(width: 2),
                          Text(
                            '$calories',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: subtitlePaddingH, vertical: subtitlePaddingV),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
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

    final sectionPadding = context.valueForDevice(
      phone: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    final headerPaddingH = context.valueForDevice(
      phone: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    final headerPaddingV = context.valueForDevice(
      phone: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    final borderRadius = context.valueForDevice(
      phone: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with gradient
          Container(
            padding: EdgeInsets.symmetric(horizontal: headerPaddingH, vertical: headerPaddingV),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gợi ý hôm nay',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem thêm',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Horizontal scroll
          Padding(
            padding: EdgeInsets.all(sectionPadding),
            child: SizedBox(
              height: 168.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
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
          ),
        ],
      ),
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
