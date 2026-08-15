import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/firebase_storage_errors.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../core/utils/safe_date_picker.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/repositories/profile_repository.dart';

class CoachProfileEditScreen extends StatefulWidget {
  const CoachProfileEditScreen({super.key});

  @override
  State<CoachProfileEditScreen> createState() => _CoachProfileEditScreenState();
}

class _CoachProfileEditScreenState extends State<CoachProfileEditScreen> {
  final _profileRepo = ProfileRepository();
  final _tokenStorage = TokenStorage();
  final _firebaseStorage = FirebaseStorageService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAvatarSaving = false;
  bool _profileChanged = false;
  String? _avatarUrl;

  final _fullNameController = TextEditingController();

  String? _gender;
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
        _avatarUrl = data['avatarUrl']?.toString();
        _gender = data['gender']?.toString();
        _dateOfBirth = _parseDate(data['dateOfBirth']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
        initialDate:
            _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
        firstDate: DateTime(1950),
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
    if (!FirebaseBootstrap.isInitialized ||
        !FirebaseStorageService.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
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
          duration: Duration(seconds: 5),
          content: Text(
            'Không xác định được tài khoản. Vui lòng đăng nhập lại.',
          ),
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
            duration: Duration(seconds: 5),
            content: Text('Cập nhật avatar thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Lưu avatar lên server thất bại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(localizeFirebaseStorageError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAvatarSaving = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final updateData = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'gender': _gender,
      if (_dateOfBirthApiValue() != null) 'dateOfBirth': _dateOfBirthApiValue(),
    };

    final result = await _profileRepo.updateMyProfile(updateData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result != null) {
      setState(() => _profileChanged = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Cập nhật thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Có lỗi xảy ra, vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
            'Chỉnh sửa hồ sơ',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                      _buildGenderDropdown(),
                      const SizedBox(height: 20),
                      _buildDateOfBirthField(),
                      const SizedBox(height: 40),
                      _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
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
              border: Border.all(
                color: AppColors.progressBackground,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateOfBirthLabel(),
                  style: TextStyle(
                    color: _dateOfBirth == null
                        ? AppColors.textSecondary
                        : AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    final genderLabels = {'Male': 'Nam', 'Female': 'Nữ', 'Other': 'Khác'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
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
              value: _gender,
              hint: const Text(
                'Chưa chọn',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              items: genderLabels.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _gender = val),
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
                    ? const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.textSecondary,
                      )
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
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
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
              onPressed:
                  (_isAvatarSaving || !FirebaseStorageService.isSupported)
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
        ],
      ),
    );
  }
}
