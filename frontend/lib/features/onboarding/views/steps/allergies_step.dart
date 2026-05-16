import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class AllergiesStep extends StatefulWidget {
  final VoidCallback onNext;
  const AllergiesStep({super.key, required this.onNext});

  @override
  State<AllergiesStep> createState() => _AllergiesStepState();
}

class _AllergiesStepState extends State<AllergiesStep> {
  final List<Map<String, dynamic>> _allergies = [
    {'name': 'Hải sản', 'icon': Icons.set_meal_outlined},
    {'name': 'Đậu phộng', 'icon': Icons.circle_outlined},
    {'name': 'Sữa', 'icon': Icons.water_drop_outlined},
    {'name': 'Gluten', 'icon': Icons.grass_outlined},
    {'name': 'Trứng', 'icon': Icons.egg_outlined},
    {'name': 'Đậu nành', 'icon': Icons.eco_outlined},
    {'name': 'Lúa mì', 'icon': Icons.breakfast_dining_outlined},
    {'name': 'Hạt cây', 'icon': Icons.park_outlined},
  ];

  final Set<String> _selected = {'Gluten'}; // Default selection based on image

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bạn có bị dị ứng không?', style: AppTextStyles.heading1),
          const SizedBox(height: 8),
          const Text('Hãy chọn các loại thực phẩm bạn bị dị ứng để chúng tôi cá nhân hóa thực đơn an toàn cho bạn.', style: AppTextStyles.subtitle),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            itemCount: _allergies.length,
            itemBuilder: (context, index) {
              final item = _allergies[index];
              final isSelected = _selected.contains(item['name']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected ? _selected.remove(item['name']) : _selected.add(item['name']);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.progressBackground,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'], color: isSelected ? AppColors.primary : AppColors.textDark),
                            const SizedBox(height: 4),
                            Text(item['name'], style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.progressBackground),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_circle_outline, color: AppColors.textDark),
                SizedBox(width: 8),
                Text('Thêm loại dị ứng khác...', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(text: 'Hoàn tất', onPressed: widget.onNext),
        ],
      ),
    );
  }
}
