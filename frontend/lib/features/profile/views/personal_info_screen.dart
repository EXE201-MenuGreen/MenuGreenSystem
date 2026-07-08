import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/health_profile_values.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/firebase_storage_errors.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../core/utils/safe_date_picker.dart';
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
  final _tokenStorage = TokenStorage();
  final _firebaseStorage = FirebaseStorageService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAvatarSaving = false;
  bool _profileChanged = false;
  String? _avatarUrl;

  final _fullNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();

  String? _gender;
  String? _activityLevel;
  String? _goal;
  DateTime? _dateOfBirth;
  bool _pickingDate = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final data = await _profileRepo.getMyProfile();
    if (data != null && mounted) {
      setState(() {
        _fullNameController.text = data['fullName']?.toString() ?? '';
        _heightController.text = _formatNum(data['heightCm']);
        _weightController.text = _formatNum(data['weightKg']);
        _bodyFatController.text = _formatNum(data['bodyFatPercent']);
        final url = data['avatarUrl']?.toString();
        _avatarUrl = (url != null && url.isNotEmpty) ? url : null;
        _gender = HealthProfileValues.normalizeGender(data['gender']?.toString());
        _activityLevel = HealthProfileValues.normalizeActivity(data['activityLevel']?.toString());
        _goal = HealthProfileValues.normalizeGoal(data['goal']?.toString());
        _dateOfBirth = _parseDate(data['dateOfBirth']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _formatNum(dynamic value) {
    if (value == null) return '';
    final n = value is num ? value.toDouble() : double.tryParse(value.toString());
    if (n == null) return '';
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s.split('T').first);
  }

  String? _dateOfBirthApiValue() {
    if (_dateOfBirth == null) return null;
    final d = _dateOfBirth!;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _dateOfBirthLabel() {
    if (_dateOfBirth == null) return 'Chưa chọn';
    final d = _dateOfBirth!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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

  Future<String?> _resolveUserId() async {
    var userId = await _tokenStorage.getUserId();
    if (userId != null && userId.isNotEmpty) return userId;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    userId = JwtUtils.tryGetUserId(token);
    if (userId != null) {
      await _tokenStorage.saveUserId(userId);
    }
    return userId;
  }

  Future<void> _handlePickAndUploadAvatar() async {
    await FirebaseBootstrap.initialize();
    if (!FirebaseBootstrap.isInitialized || !FirebaseStorageService.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload ảnh chỉ hỗ trợ trên Android/iOS. Hãy chạy app trên emulator hoặc điện thoại.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = await _resolveUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được tài khoản. Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picked = await _firebaseStorage.pickAvatarImage();
    if (picked == null) return;

    setState(() => _isAvatarSaving = true);

    try {
      final downloadUrl = await _firebaseStorage.uploadAvatar(
        userId: userId,
        imageFile: File(picked.path),
      );

      final result = await _profileRepo.updateAvatar(downloadUrl);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _avatarUrl = downloadUrl;
          _profileChanged = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật avatar thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu avatar lên server thất bại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeFirebaseStorageError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAvatarSaving = false);
    }
  }

  Future<void> _handleRemoveAvatar() async {
    setState(() => _isAvatarSaving = true);
    final result = await _profileRepo.removeAvatar();
    setState(() => _isAvatarSaving = false);

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _avatarUrl = null;
        _profileChanged = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá avatar!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xoá avatar thất bại!'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleSave() async {
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final bodyFatText = _bodyFatController.text.trim();
    final bodyFat = bodyFatText.isEmpty ? null : double.tryParse(bodyFatText);

    if (height != null && (height <= 0 || height > 300)) {
      _showError('Chiều cao không hợp lệ (50–300 cm)');
      return;
    }
    if (weight != null && (weight <= 0 || weight > 500)) {
      _showError('Cân nặng không hợp lệ (20–500 kg)');
      return;
    }
    if (bodyFatText.isNotEmpty && (bodyFat == null || bodyFat < 0 || bodyFat > 100)) {
      _showError('Tỷ lệ mỡ không hợp lệ (0–100%)');
      return;
    }

    setState(() => _isSaving = true);

    final updateData = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'gender': _gender,
      if (_dateOfBirthApiValue() != null) 'dateOfBirth': _dateOfBirthApiValue(),
      'heightCm': ?height,
      'weightKg': ?weight,
      'bodyFatPercent': ?bodyFat,
      'activityLevel': _activityLevel ?? HealthProfileValues.normalizeActivity(null),
      'goal': _goal ?? HealthProfileValues.normalizeGoal(null),
    };

    final result = await _profileRepo.updateMyProfile(updateData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại!'), backgroundColor: Colors.red),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _popWithResult() {
    Navigator.pop(context, _profileChanged ? true : null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popWithResult();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: _popWithResult,
          ),
          centerTitle: true,
          title: const Text(
            'Thông tin cá nhân',
            style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Họ và tên',
                      hintText: 'Nhập họ tên',
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Giới tính',
                      value: _gender,
                      items: HealthProfileValues.genderLabels,
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                    const SizedBox(height: 20),
                    _buildDateOfBirthField(),
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
                    CustomTextField(
                      controller: _bodyFatController,
                      label: 'Tỷ lệ mỡ cơ thể (%)',
                      hintText: 'Tùy chọn, VD: 20',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Mức độ hoạt động',
                      value: _activityLevel,
                      items: HealthProfileValues.activityLabels,
                      onChanged: (val) => setState(() => _activityLevel = val),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Mục tiêu cá nhân',
                      value: _goal,
                      items: HealthProfileValues.goalLabels,
                      onChanged: (val) => setState(() => _goal = val),
                    ),
                    const SizedBox(height: 40),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : PrimaryButton(
                            text: 'Lưu thay đổi',
                            onPressed: _handleSave,
                          ),
                    const SizedBox(height: 280),
                  ],
                ),
              ),
            ),
      ),
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
              color: Colors.white,
              border: Border.all(color: AppColors.progressBackground, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateOfBirthLabel(),
                  style: TextStyle(
                    color: _dateOfBirth == null ? AppColors.textSecondary : AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.progressBackground,
                backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
                child: !hasAvatar
                    ? const Icon(Icons.person, size: 48, color: AppColors.textSecondary)
                    : null,
              ),
              if (_isAvatarSaving)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!FirebaseStorageService.isSupported)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Upload ảnh chỉ khả dụng trên Android/iOS. Trên Windows hãy dùng emulator Android.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isAvatarSaving || !FirebaseStorageService.isSupported)
                  ? null
                  : _handlePickAndUploadAvatar,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Chọn ảnh từ thư viện'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
          if (hasAvatar) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isAvatarSaving ? null : _handleRemoveAvatar,
              child: const Text(
                'Xóa avatar',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    var selected = value;
    if (selected != null && !items.containsKey(selected)) {
      selected = null;
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
              value: selected,
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
