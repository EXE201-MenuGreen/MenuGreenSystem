import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/health_profile_values.dart';
import '../../../../core/utils/safe_date_picker.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({
    super.key,
    required this.onNext,
    this.initialFullName,
    this.initialGender,
    this.initialDateOfBirth,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialBodyFatPercent,
    this.initialActivityLevel,
    this.initialGoal,
  });

  final Future<void> Function({
    required String fullName,
    required String gender,
    DateTime? dateOfBirth,
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
    required String activityLevel,
    required String goal,
  }) onNext;
  final String? initialFullName;
  final String? initialGender;
  final DateTime? initialDateOfBirth;
  final double? initialHeightCm;
  final double? initialWeightKg;
  final double? initialBodyFatPercent;
  final String? initialActivityLevel;
  final String? initialGoal;

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _fullNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;
  String _activityLevel = 'sedentary';
  String _goal = 'maintain weight';
  bool _saving = false;
  bool _pickingDate = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFullName != null) {
      _fullNameController.text = widget.initialFullName!;
    }
    _gender = HealthProfileValues.normalizeGender(widget.initialGender);
    _dateOfBirth = widget.initialDateOfBirth;
    if (widget.initialHeightCm != null) {
      _heightController.text = widget.initialHeightCm!.toStringAsFixed(0);
    }
    if (widget.initialWeightKg != null) {
      _weightController.text = widget.initialWeightKg!.toStringAsFixed(0);
    }
    if (widget.initialBodyFatPercent != null) {
      _bodyFatController.text = widget.initialBodyFatPercent!.toStringAsFixed(1);
    }
    if (widget.initialActivityLevel != null) {
      _activityLevel = HealthProfileValues.normalizeActivity(widget.initialActivityLevel);
    }
    if (widget.initialGoal != null) {
      _goal = HealthProfileValues.normalizeGoal(widget.initialGoal);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    if (_pickingDate) return;
    _pickingDate = true;
    try {
      final now = DateTime.now();
      final picked = await showSafeDatePicker(
        context: context,
        initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
        firstDate: DateTime(1920),
        lastDate: now,
        helpText: 'Chọn ngày sinh',
      );
      if (picked != null && mounted) setState(() => _dateOfBirth = picked);
    } finally {
      _pickingDate = false;
    }
  }

  String _dateOfBirthLabel() {
    if (_dateOfBirth == null) return 'Chọn ngày sinh (tùy chọn)';
    final d = _dateOfBirth!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      _showError('Vui lòng nhập họ và tên');
      return;
    }
    if (_gender == null || _gender!.isEmpty) {
      _showError('Vui lòng chọn giới tính');
      return;
    }

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
      fullName: fullName,
      gender: _gender!,
      dateOfBirth: _dateOfBirth,
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
            'Nhập hồ sơ và thông số để MenuGreen tính nhu cầu dinh dưỡng cho bạn.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _fullNameController,
            label: 'Họ và tên',
            hintText: 'Nhập họ tên',
          ),
          const SizedBox(height: 20),
          _buildGenderDropdown(),
          const SizedBox(height: 20),
          _buildDateOfBirthField(),
          const SizedBox(height: 24),
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
          _buildActivityDropdown(),
          const SizedBox(height: 24),
          _buildGoalDropdown(),
          const SizedBox(height: 40),
          PrimaryButton(
            text: _saving ? 'Đang lưu...' : 'Tiếp tục  →',
            onPressed: _saving ? () {} : _submit,
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
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
              value: _gender,
              hint: const Text('Chọn giới tính', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              items: HealthProfileValues.genderLabels.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDateOfBirth,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.progressBackground, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _dateOfBirthLabel(),
              style: TextStyle(
                color: _dateOfBirth == null ? AppColors.textSecondary : AppColors.textDark,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDropdown() {
    return Column(
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
              items: HealthProfileValues.activityLabels.entries
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
    );
  }

  Widget _buildGoalDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mục tiêu',
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
              value: _goal,
              items: HealthProfileValues.goalLabels.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
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
    );
  }
}
