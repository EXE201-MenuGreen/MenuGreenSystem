import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../repositories/profile_repository.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _profileRepo = ProfileRepository();
  bool _isLoading = true;
  bool _isSaving = false;

  final _fullNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _gender;
  String? _activityLevel;
  String? _goal;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final data = await _profileRepo.getMyProfile();
    if (data != null && mounted) {
      setState(() {
        _fullNameController.text = data['fullName'] ?? '';
        _heightController.text = data['heightCm']?.toString() ?? '';
        _weightController.text = data['weightKg']?.toString() ?? '';
        _gender = data['gender'];
        _activityLevel = data['activityLevel'];
        _goal = data['goal'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    
    final updateData = {
      'fullName': _fullNameController.text,
      'gender': _gender,
      'heightCm': double.tryParse(_heightController.text),
      'weightKg': double.tryParse(_weightController.text),
      'activityLevel': _activityLevel,
      'goal': _goal,
    };

    final result = await _profileRepo.updateMyProfile(updateData);
    
    setState(() => _isSaving = false);
    
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to refresh parent
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Thông tin cá nhân', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Họ và tên',
                    hintText: 'Nhập họ tên',
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    label: 'Giới tính',
                    value: _gender,
                    items: const {'Male': 'Nam', 'Female': 'Nữ', 'Other': 'Khác'},
                    onChanged: (val) => setState(() => _gender = val),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _heightController,
                          label: 'Chiều cao (cm)',
                          hintText: 'VD: 170',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _weightController,
                          label: 'Cân nặng (kg)',
                          hintText: 'VD: 65',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    label: 'Mức độ hoạt động',
                    value: _activityLevel,
                    items: const {
                      'Sedentary': 'Ít vận động',
                      'Light': 'Vận động nhẹ',
                      'Moderate': 'Vận động vừa',
                      'Active': 'Năng động',
                      'VeryActive': 'Rất năng động',
                    },
                    onChanged: (val) => setState(() => _activityLevel = val),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    label: 'Mục tiêu cá nhân',
                    value: _goal,
                    items: const {
                      'LoseWeight': 'Giảm cân',
                      'Maintain': 'Duy trì vóc dáng',
                      'GainWeight': 'Tăng cân',
                      'BuildMuscle': 'Tăng cơ',
                    },
                    onChanged: (val) => setState(() => _goal = val),
                  ),
                  const SizedBox(height: 40),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : PrimaryButton(
                          text: 'Lưu thay đổi',
                          onPressed: _handleSave,
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // If backend returns a value not in our list (e.g. empty string), we shouldn't crash
    if (value != null && !items.containsKey(value)) {
      value = null;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
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
              value: value,
              hint: const Text('Chưa chọn', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: items.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
