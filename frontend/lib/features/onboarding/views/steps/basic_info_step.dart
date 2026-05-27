import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class BasicInfoStep extends StatefulWidget {
  final VoidCallback onNext;
  const BasicInfoStep({super.key, required this.onNext});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  static const Map<String, String> _activityItems = {
    'Sedentary': 'Ít vận động',
    'Light': 'Vận động nhẹ',
    'Moderate': 'Vận động vừa',
    'Active': 'Năng động',
    'VeryActive': 'Rất năng động',
  };

  String? _activityLevel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Thông tin cơ bản',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 12),
          const Text(
            'Vui lòng nhập thông tin để MenuGreen tính toán nhu cầu dinh dưỡng của bạn.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 40),
          const CustomTextField(
            label: 'Chiều cao (cm)',
            hintText: 'Ví dụ: 170',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const CustomTextField(
            label: 'Cân nặng (kg)',
            hintText: 'Ví dụ: 65',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const CustomTextField(
            label: 'Tuổi',
            hintText: 'Ví dụ: 25',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          // Simple Dropdown mockup
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mức độ hoạt động',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.progressBackground, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _activityLevel,
                    hint: const Text('Chọn mức độ hoạt động', style: TextStyle(color: AppColors.textDark, fontSize: 14)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    items: _activityItems.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _activityLevel = val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: 'Tiếp tục  →',
            onPressed: widget.onNext,
          ),
        ],
      ),
    );
  }
}
