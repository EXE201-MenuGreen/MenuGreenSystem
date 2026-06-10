import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';
import 'ingredient_tile.dart';
import 'scan_decorations.dart';
import 'suggested_dish_card.dart';

class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.response,
    required this.onLogIngredient,
    required this.onLogSuggestedDish,
    required this.scrollController,
  });

  final CvInferenceResponse response;
  final void Function(CvIngredientItem) onLogIngredient;
  final void Function(CvSuggestedDish) onLogSuggestedDish;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phân tích thành công',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Độ tin cậy chung: ${response.luongTinCayChung ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Section 1: Raw Ingredients
                if (response.nguyenLieuThoQuetDuoc != null &&
                    response.nguyenLieuThoQuetDuoc!.isNotEmpty) ...[
                  const ScanSectionHeader(title: 'Nguyên liệu thô quét được'),
                  const SizedBox(height: 12),
                  ...response.nguyenLieuThoQuetDuoc!.map((ing) => IngredientTile(
                        item: ing,
                        onLog: () => onLogIngredient(ing),
                      )),
                  const SizedBox(height: 24),
                ],

                // Section 2: Suggested Dishes
                if (response.danhSachMonAnGoiY != null &&
                    response.danhSachMonAnGoiY!.isNotEmpty) ...[
                  const ScanSectionHeader(title: 'Thực đơn gợi ý chế biến'),
                  const SizedBox(height: 12),
                  ...response.danhSachMonAnGoiY!.map((dish) => SuggestedDishCard(
                        dish: dish,
                        onLog: () => onLogSuggestedDish(dish),
                      )),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
