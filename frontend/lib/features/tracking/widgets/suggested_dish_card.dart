import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

class SuggestedDishCard extends StatelessWidget {
  const SuggestedDishCard({
    super.key,
    required this.dish,
    required this.onLog,
  });

  final CvSuggestedDish dish;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final isSafe = dish.isSafeForUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSafe ? Colors.grey[200]! : Colors.redAccent.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSafe ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSafe ? Icons.check_circle : Icons.warning,
                      size: 14,
                      color: isSafe ? Colors.green[700] : Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSafe ? 'An toàn' : 'Cảnh báo dị ứng',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSafe ? Colors.green[800] : Colors.red[800],
                      ),
                    )
                  ],
                ),
              ),
              Text(
                'Độ khả thi: ${dish.doKhaThi}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dish.tenMonAn,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dish.moTaNgan,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          if (!isSafe && dish.matchedAllergens.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Chứa chất gây dị ứng: ${dish.matchedAllergens.join(", ")}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Macros breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroText('Calo', '${dish.thongTinDinhDuongMonAn.tongCalories.toStringAsFixed(0)} kcal'),
                _buildMacroText('Protein', '${dish.thongTinDinhDuongMonAn.proteinG.toStringAsFixed(0)}g'),
                _buildMacroText('Carbs', '${dish.thongTinDinhDuongMonAn.carbsG.toStringAsFixed(0)}g'),
                _buildMacroText('Béo', '${dish.thongTinDinhDuongMonAn.fatG.toStringAsFixed(0)}g'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSafe ? AppColors.primary : Colors.grey[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.bookmark_add, size: 18, color: Colors.white),
              label: const Text(
                'Ghi vào nhật ký ăn uống',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacroText(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}
