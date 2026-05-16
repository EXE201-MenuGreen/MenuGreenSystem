import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class CalorieGoalStep extends StatefulWidget {
  final VoidCallback onFinish;
  const CalorieGoalStep({super.key, required this.onFinish});

  @override
  State<CalorieGoalStep> createState() => _CalorieGoalStepState();
}

class _CalorieGoalStepState extends State<CalorieGoalStep> {
  double _calories = 2500;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text('${_calories.toInt()} kcal', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Mức calo hàng ngày lý tưởng của bạn', style: AppTextStyles.subtitle),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Điều chỉnh mức calo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text('${_calories.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('1200', style: TextStyle(color: AppColors.textLight)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.progressBackground,
                          thumbColor: AppColors.primary,
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: _calories,
                          min: 1200,
                          max: 3500,
                          divisions: 23, // every 100 kcal
                          onChanged: (val) {
                            setState(() {
                              _calories = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const Text('3500', style: TextStyle(color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Kéo để thay đổi mục tiêu của bạn', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.progressBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dựa trên chỉ số cơ thể và mức độ hoạt động của bạn, 2500 kcal là mức năng lượng phù hợp để duy trì cân nặng ổn định.',
                    style: TextStyle(color: AppColors.textDark, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: 'Xác nhận mục tiêu',
            onPressed: widget.onFinish,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            child: const Text('Tính toán lại chỉ số cơ thể', style: TextStyle(color: AppColors.textSecondary)),
          )
        ],
      ),
    );
  }
}
