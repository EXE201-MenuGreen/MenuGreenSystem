import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../tracking/models/nutrition_models.dart';

class HomeMealLogsSection extends StatelessWidget {
  const HomeMealLogsSection({
    super.key,
    required this.logs,
    required this.onAddMeal,
    this.refreshing = false,
  });

  final List<MealLogItem> logs;
  final VoidCallback onAddMeal;
  final bool refreshing;

  String _mealTypeLabel(String? mealType) {
    final value = mealType?.trim().toLowerCase() ?? '';
    switch (value) {
      case 'breakfast':
      case 'bữa sáng':
        return 'sáng';
      case 'lunch':
      case 'bữa trưa':
        return 'trưa';
      case 'dinner':
      case 'bữa tối':
        return 'tối';
      default:
        return 'phụ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                  const Color(0xFF10B981).withValues(alpha: 0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.list_alt_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nhật ký ăn uống',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: refreshing ? null : onAddMeal,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Thêm',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: logs.isEmpty
                ? _buildEmptyMealLogs()
                : _buildMealLogsList(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMealLogs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa ghi nhận bữa ăn',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy thêm bữa ăn hôm nay để tính calo.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealLogsList(List<MealLogItem> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...logs.take(4).map((meal) {
          final mealType = _mealTypeLabel(meal.mealType);
          Color tagBgColor;
          Color tagTextColor;
          if (mealType == 'sáng') {
            tagBgColor = const Color(0xFFEFF6FF);
            tagTextColor = const Color(0xFF2563EB);
          } else if (mealType == 'trưa') {
            tagBgColor = const Color(0xFFFEF3C7);
            tagTextColor = const Color(0xFFD97706);
          } else if (mealType == 'tối') {
            tagBgColor = const Color(0xFFFEE2E2);
            tagTextColor = const Color(0xFFDC2626);
          } else {
            tagBgColor = const Color(0xFFF3E8FF);
            tagTextColor = const Color(0xFF7C3AED);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tagBgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meal.isRecipe
                        ? Icons.menu_book_rounded
                        : Icons.restaurant_rounded,
                    color: tagTextColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.displayName,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bữa $mealType',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tagTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${meal.caloriesKcal.toStringAsFixed(0)} kcal',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        }),
        if (logs.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '+${logs.length - 4} bữa ăn khác',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
