import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class UserTypeStep extends StatefulWidget {
  final VoidCallback onNext;
  const UserTypeStep({super.key, required this.onNext});

  @override
  State<UserTypeStep> createState() => _UserTypeStepState();
}

class _UserTypeStepState extends State<UserTypeStep> {
  int _selectedIndex = 0;

  Widget _buildTypeCard(int index, String title, String desc, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.progressBackground,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.progressBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Placeholder for image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_outlined, color: AppColors.textLight, size: 40),
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Đã chọn', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Bạn thuộc nhóm nào?', style: AppTextStyles.heading1, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Để MenuGreen gợi ý chế độ ăn phù hợp nhất cho mục tiêu của bạn.', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildTypeCard(0, 'Người tập Gym', 'Chế độ ăn giàu protein, hỗ trợ tăng cơ, giảm mỡ và phục hồi thể lực sau tập.', Icons.fitness_center),
          _buildTypeCard(1, 'Nhân viên văn phòng', 'Thực đơn cân bằng, ít béo, giàu chất xơ giúp duy trì năng lượng và sự tập trung.', Icons.laptop_mac),
          _buildTypeCard(2, 'Người dùng phổ thông', 'Duy trì vóc dáng, sức khỏe dẻo dai với các món ăn xanh, sạch và đủ chất.', Icons.spa),
          const SizedBox(height: 24),
          PrimaryButton(text: 'Tiếp tục  →', onPressed: widget.onNext),
        ],
      ),
    );
  }
}
