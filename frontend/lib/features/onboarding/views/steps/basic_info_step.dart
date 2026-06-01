import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({
    super.key,
    required this.onNext,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialBodyFatPercent,
    this.initialActivityLevel,
    this.initialGoal,
  });

  final Future<void> Function({
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
    required String activityLevel,
    required String goal,
  }) onNext;
  final double? initialHeightCm;
  final double? initialWeightKg;
  final double? initialBodyFatPercent;
  final String? initialActivityLevel;
  final String? initialGoal;

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  static const Map<String, String> _activityItems = {
    'sedentary': 'Ít vận động',
    'lightly active': 'Vận động nhẹ',
    'moderately active': 'Vận động vừa',
    'very active': 'Rất năng động',
  };

  static const Map<String, String> _goalItems = {
    'lose weight': 'Giảm cân',
    'maintain weight': 'Giữ cân',
    'gain weight': 'Tăng cân',
    'build muscle': 'Tăng cơ',
  };

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  String _activityLevel = 'sedentary';
  String _goal = 'maintain weight';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialHeightCm != null) {
      _heightController.text = widget.initialHeightCm!.toStringAsFixed(0);
    }
    if (widget.initialWeightKg != null) {
      _weightController.text = widget.initialWeightKg!.toStringAsFixed(0);
    }
    if (widget.initialBodyFatPercent != null) {
      _bodyFatController.text = widget.initialBodyFatPercent!.toStringAsFixed(1);
    }
    if (widget.initialActivityLevel != null &&
        _activityItems.containsKey(widget.initialActivityLevel)) {
      _activityLevel = widget.initialActivityLevel!;
    }
    if (widget.initialGoal != null && _goalItems.containsKey(widget.initialGoal)) {
      _goal = widget.initialGoal!;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final heightCm = double.tryParse(_heightController.text.trim());
    final weightKg = double.tryParse(_weightController.text.trim());
    final bodyFatText = _bodyFatController.text.trim();
    final bodyFatPercent =
        bodyFatText.isEmpty ? null : double.tryParse(bodyFatText);

    if (heightCm == null || heightCm <= 0) {
      _showError('Chiều cao không hợp lệ');
      return;
    }
    if (weightKg == null || weightKg <= 0) {
      _showError('Cân nặng không hợp lệ');
      return;
    }
    if (bodyFatText.isNotEmpty && (bodyFatPercent == null || bodyFatPercent < 0)) {
      _showError('Tỷ lệ mỡ không hợp lệ');
      return;
    }

    setState(() => _saving = true);
    await widget.onNext(
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    if (mounted) setState(() => _saving = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

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
          CustomTextField(
            controller: _heightController,
            label: 'Chiều cao (cm)',
            hintText: 'Ví dụ: 170',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _weightController,
            label: 'Cân nặng (kg)',
            hintText: 'Ví dụ: 65',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _bodyFatController,
            label: 'Tỷ lệ mỡ cơ thể (%) - tùy chọn',
            hintText: 'Ví dụ: 20',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
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
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _activityLevel = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mục tiêu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
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
                    value: _goal,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    items: _goalItems.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _goal = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: _saving ? 'Đang lưu...' : 'Tiếp tục  →',
            onPressed: _saving ? () {} : _submit,
          ),
        ],
      ),
    );
  }
}
