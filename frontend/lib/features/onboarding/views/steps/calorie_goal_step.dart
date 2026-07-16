import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class CalorieGoalStep extends StatefulWidget {
  const CalorieGoalStep({
    super.key,
    required this.onFinish,
    this.isSubmitting = false,
    this.initialCalories = 2500,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.goal,
  });

  final Future<void> Function(int targetCalories) onFinish;
  final bool isSubmitting;
  final int initialCalories;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? goal;

  @override
  State<CalorieGoalStep> createState() => _CalorieGoalStepState();
}

class _CalorieGoalStepState extends State<CalorieGoalStep> {
  late double _calories;

  @override
  void initState() {
    super.initState();
    _calories = widget.initialCalories.toDouble().clamp(1200, 3500);
  }

  @override
  void didUpdateWidget(CalorieGoalStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCalories != widget.initialCalories) {
      _calories = widget.initialCalories.toDouble().clamp(1200, 3500);
    }
  }

  Future<void> _finish() async {
    if (widget.isSubmitting) return;
    await widget.onFinish(_calories.round());
  }

  String _hintText() {
    final parts = <String>[];
    if (widget.heightCm != null && widget.weightKg != null) {
      parts.add('${widget.heightCm!.toStringAsFixed(0)} cm, ${widget.weightKg!.toStringAsFixed(0)} kg');
    }
    if (widget.goal != null && widget.goal!.isNotEmpty) {
      parts.add('mục tiêu: ${widget.goal}');
    }
    if (parts.isEmpty) {
      return 'Dựa trên chỉ số của bạn, mức ${_calories.toInt()} kcal là gợi ý khởi đầu. Bạn có thể điều chỉnh bằng thanh trượt.';
    }
    return 'Dựa trên ${parts.join(' · ')}, mức ${_calories.toInt()} kcal là gợi ý từ hệ thống. Kéo thanh trượt nếu bạn muốn điều chỉnh.';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            '${_calories.toInt()} kcal',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                    const Text(
                      'Điều chỉnh mức calo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      '${_calories.toInt()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('1200', style: TextStyle(color: AppColors.textLight)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbColor: AppColors.primary,
                          trackHeight: 6,
                          activeTickMarkColor: AppColors.primary,
                        ),
                        child: Slider(
                          value: _calories,
                          min: 1200,
                          max: 3500,
                          divisions: 23,
                          onChanged: (val) => setState(() => _calories = val),
                        ),
                      ),
                    ),
                    const Text('3500', style: TextStyle(color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Kéo để thay đổi mục tiêu của bạn',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.progressBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hintText(),
                    style: const TextStyle(color: AppColors.textDark, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: widget.isSubmitting ? 'Đang hoàn tất...' : 'Xác nhận mục tiêu',
            onPressed: widget.isSubmitting ? () {} : _finish,
          ),
        ],
      ),
    );
  }
}
