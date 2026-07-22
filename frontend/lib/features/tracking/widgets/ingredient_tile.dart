import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

class IngredientTile extends StatelessWidget {
  const IngredientTile({
    super.key,
    required this.item,
    required this.onLog,
  });

  final CvIngredientItem item;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.tenNguyenLieu,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.khoiLuongUocTinhG.toStringAsFixed(0)} g',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onLog,
            tooltip: 'Thêm nguyên liệu',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
