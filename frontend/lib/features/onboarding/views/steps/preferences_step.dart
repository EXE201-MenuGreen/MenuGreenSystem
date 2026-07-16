import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class PreferencesStep extends StatefulWidget {
  final Future<void> Function(List<String> selectedLabels) onNext;
  const PreferencesStep({super.key, required this.onNext});

  @override
  State<PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends State<PreferencesStep> {
  bool _saving = false;

  final Map<String, bool> _prefs = {
    'Ăn uống lành mạnh': true,
    'Tiết kiệm': false,
    'Nấu nhanh': true,
    'Ăn chay': false,
  };

  final Map<String, String> _desc = {
    'Ăn uống lành mạnh': 'Ưu tiên thực phẩm sạch',
    'Tiết kiệm': 'Gợi ý nguyên liệu giá tốt nhất',
    'Nấu nhanh': 'Công thức dưới 15 phút',
    'Ăn chay': 'Món ăn hoàn toàn từ thực vật',
  };

  final Map<String, IconData> _icons = {
    'Ăn uống lành mạnh': Icons.energy_savings_leaf_outlined,
    'Tiết kiệm': Icons.savings_outlined,
    'Nấu nhanh': Icons.timer_outlined,
    'Ăn chay': Icons.eco_outlined,
  };

  Future<void> _finish() async {
    final selected = _prefs.entries.where((e) => e.value).map((e) => e.key).toList();
    setState(() => _saving = true);
    await widget.onNext(selected);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Bạn quan tâm điều gì nhất?', style: AppTextStyles.heading1, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Hãy chọn các tiêu chí giúp chúng tôi gợi ý món ăn phù hợp với phong cách sống của bạn.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._prefs.keys.map((key) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.progressBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.progressBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icons[key], color: AppColors.textDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        Text(_desc[key]!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _prefs[key]!,
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.primary
                          : AppColors.progressBackground,
                    ),
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : Colors.white,
                    ),
                    onChanged: (val) => setState(() => _prefs[key] = val),
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
          PrimaryButton(
            text: _saving ? 'Đang lưu...' : 'Tiếp tục  →',
            onPressed: _saving ? () {} : _finish,
          ),
        ],
      ),
    );
  }
}
