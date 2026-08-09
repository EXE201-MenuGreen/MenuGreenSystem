import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/firebase_storage_errors.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../core/utils/safe_date_picker.dart';
import '../repositories/coach_application_repository.dart';
import 'coach_application_status_screen.dart';

class CoachApplicationScreen extends StatefulWidget {
  const CoachApplicationScreen({
    super.key,
    this.initialData,
    this.editMode = false,
  });

  final Map<String, dynamic>? initialData;
  final bool editMode;

  @override
  State<CoachApplicationScreen> createState() => _CoachApplicationScreenState();
}

class _CoachApplicationScreenState extends State<CoachApplicationScreen> {
  static const _specialtyOptions = [
    'Giảm cân, giảm mỡ',
    'Tăng cơ',
    'Body recomposition',
    'Tăng sức mạnh',
    'Functional training',
    'Cardio và sức bền',
    'Người mới bắt đầu',
    'Người lớn tuổi',
    'Phục hồi vận động',
    'Dinh dưỡng thể thao',
  ];
  static const _styleOptions = [
    'Kỷ luật',
    'Nhẹ nhàng, động viên',
    'Theo sát số liệu',
    'Linh hoạt theo lịch',
  ];
  static const _levelOptions = ['Người mới', 'Trung cấp', 'Nâng cao'];
  static const _languageOptions = ['Tiếng Việt', 'English', '한국어', '日本語'];

  final _repository = CoachApplicationRepository();
  final _storage = FirebaseStorageService();
  final _tokenStorage = TokenStorage();

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _experience = TextEditingController();
  final _achievements = TextEditingController();

  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _uploadingKey;
  String _gender = '';
  DateTime? _dateOfBirth;
  String _avatarUrl = '';
  String _identityDocumentUrl = '';
  final Set<String> _languages = {};
  final Set<String> _specialties = {};
  final Set<String> _styles = {};
  final Set<String> _levels = {};
  final List<_CertificateDraft> _certificates = [];
  final List<String> _galleryUrls = [];
  bool _mediaConsent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.initialData ?? await _repository.getMine();
      _applyData(data);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyData(Map<String, dynamic> data) {
    _fullName.text = (data['fullName'] ?? '').toString();
    _phone.text = (data['phoneNumber'] ?? '').toString();
    _city.text = (data['city'] ?? '').toString();
    _headline.text = (data['headline'] ?? '').toString();
    _bio.text = (data['bio'] ?? '').toString();
    _experience.text = (data['experienceYears'] ?? 0).toString();
    _achievements.text = (data['achievements'] ?? '').toString();
    _avatarUrl = (data['avatarUrl'] ?? '').toString();
    _identityDocumentUrl = (data['identityDocumentUrl'] ?? '').toString();
    _gender = (data['gender'] ?? '').toString();
    _dateOfBirth = DateTime.tryParse((data['dateOfBirth'] ?? '').toString());
    _replaceSet(_languages, data['languages']);
    _replaceSet(_styles, data['coachingStyles']);
    _replaceSet(_levels, data['clientLevels']);
    final specialty = data['specialty'];
    if (specialty != null) {
      _specialties
        ..clear()
        ..addAll(
          specialty
              .toString()
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty),
        );
    }
    _certificates.clear();
    final certificates = data['certificates'];
    if (certificates is List) {
      for (final item in certificates.whereType<Map>()) {
        _certificates.add(
          _CertificateDraft.fromMap(Map<String, dynamic>.from(item)),
        );
      }
    }
    if (_certificates.isEmpty) _certificates.add(_CertificateDraft());
    _galleryUrls
      ..clear()
      ..addAll(_stringList(data['galleryUrls']));
    if (widget.editMode && _galleryUrls.isNotEmpty) _mediaConsent = true;
  }

  void _replaceSet(Set<String> target, dynamic value) {
    target
      ..clear()
      ..addAll(_stringList(value));
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<String?> _userId() async {
    var userId = await _tokenStorage.getUserId();
    if (userId != null && userId.isNotEmpty) return userId;
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return null;
    userId = JwtUtils.tryGetUserId(token);
    if (userId != null) await _tokenStorage.saveUserId(userId);
    return userId;
  }

  Future<String?> _pickAndUpload(String category, {bool square = false}) async {
    if (!FirebaseStorageService.isSupported) {
      _showMessage('Upload ảnh chỉ hỗ trợ trên Android/iOS.');
      return null;
    }
    final userId = await _userId();
    if (userId == null) {
      _showMessage('Không xác định được tài khoản. Vui lòng đăng nhập lại.');
      return null;
    }
    final picked = await _storage.pickCoachApplicationImage(square: square);
    if (picked == null) return null;
    setState(() => _uploadingKey = category);
    try {
      return await _storage.uploadCoachApplicationImage(
        userId: userId,
        category: category,
        imageFile: File(picked.path),
      );
    } catch (error) {
      _showMessage(localizeFirebaseStorageError(error));
      return null;
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  Map<String, dynamic> _payload() {
    String? validDate(String value) {
      final trimmed = value.trim();
      return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed) ? trimmed : null;
    }

    return {
      'fullName': _fullName.text.trim(),
      'avatarUrl': _avatarUrl,
      'dateOfBirth': _dateOfBirth == null ? null : _apiDate(_dateOfBirth!),
      'gender': _gender,
      'phoneNumber': _phone.text.trim(),
      'city': _city.text.trim(),
      'languages': _languages.toList(),
      'headline': _headline.text.trim(),
      'bio': _bio.text.trim(),
      'experienceYears': int.tryParse(_experience.text.trim()) ?? 0,
      'specialties': _specialties.toList(),
      'coachingStyles': _styles.toList(),
      'clientLevels': _levels.toList(),
      'certificates': _certificates
          .map(
            (item) => {
              'name': item.name,
              'issuer': item.issuer,
              'credentialNumber': item.credentialNumber,
              'issuedDate': validDate(item.issuedDate),
              'expiryDate': validDate(item.expiryDate),
              'imageUrl': item.imageUrl,
            },
          )
          .toList(),
      'galleryUrls': _galleryUrls,
      'achievements': _achievements.text.trim(),
      'identityDocumentUrl': _identityDocumentUrl.isEmpty
          ? null
          : _identityDocumentUrl,
    };
  }

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _saveDraft() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.saveDraft(_payload());
      if (mounted) _showMessage('Đã lưu bản nháp hồ sơ PT.');
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.saveDraft(_payload());
      if (!mounted) return;
      _showMessage('Đã cập nhật hồ sơ PT.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    final error = _submissionError();
    if (error != null) {
      _showMessage(error);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await _repository.submit(_payload());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CoachApplicationStatusScreen(initialData: data),
        ),
        (_) => false,
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _submissionError() {
    if (_fullName.text.trim().isEmpty || _avatarUrl.isEmpty) {
      return 'Vui lòng nhập họ tên và tải ảnh đại diện.';
    }
    if (_dateOfBirth == null ||
        _phone.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      return 'Vui lòng hoàn thành ngày sinh, số điện thoại và khu vực.';
    }
    if (_languages.isEmpty) return 'Vui lòng chọn ít nhất một ngôn ngữ.';
    if (_headline.text.trim().isEmpty || _bio.text.trim().length < 80) {
      return 'Tiêu đề nghề nghiệp là bắt buộc và phần giới thiệu cần ít nhất 80 ký tự.';
    }
    if (_specialties.isEmpty) return 'Vui lòng chọn ít nhất một chuyên môn.';
    if (_certificates.isEmpty ||
        _certificates.any(
          (item) =>
              item.name.trim().isEmpty ||
              item.issuer.trim().isEmpty ||
              item.imageUrl.isEmpty,
        )) {
      return 'Mỗi chứng chỉ cần có tên, đơn vị cấp và ảnh minh chứng.';
    }
    if (_identityDocumentUrl.isEmpty) {
      return 'Vui lòng tải ảnh giấy tờ xác minh.';
    }
    if (_galleryUrls.isEmpty) {
      return 'Vui lòng thêm ít nhất một ảnh hoạt động nghề nghiệp.';
    }
    if (!_mediaConsent) {
      return 'Bạn cần xác nhận quyền sử dụng các hình ảnh đã tải.';
    }
    return null;
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else if (widget.editMode) {
      _saveProfileChanges();
    } else {
      _submit();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    _showMessage(error.toString().replaceFirst('Exception: ', ''));
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _city.dispose();
    _headline.dispose();
    _bio.dispose();
    _experience.dispose();
    _achievements.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        automaticallyImplyLeading: widget.editMode,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.editMode ? 'Chỉnh sửa hồ sơ PT' : 'Hoàn thiện hồ sơ PT',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : widget.editMode
                ? _saveProfileChanges
                : _saveDraft,
            child: Text(widget.editMode ? 'Lưu' : 'Lưu nháp'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: Column(
                children: [
                  _progressHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: _stepContent(),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _loading ? null : _bottomActions(),
    );
  }

  Widget _progressHeader() {
    const labels = ['Cá nhân', 'Nghề nghiệp', 'Xác minh & hình ảnh'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index <= _step
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              labels.length,
              (index) => Text(
                labels[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: index == _step
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: index == _step
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _personalStep();
      case 1:
        return _professionalStep();
      default:
        return Column(
          children: [
            _verificationStep(),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 28),
            _mediaStep(),
          ],
        );
    }
  }

  Widget _sectionIntro(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionIntro(
          'Thông tin cá nhân',
          'Thông tin liên hệ và giấy tờ chỉ được Admin sử dụng để xác minh.',
        ),
        Center(child: _avatarPicker()),
        const SizedBox(height: 24),
        _field(_fullName, 'Họ và tên *', hint: 'Nguyễn Văn An'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _dateField()),
            const SizedBox(width: 12),
            Expanded(child: _genderField()),
          ],
        ),
        const SizedBox(height: 16),
        _field(
          _phone,
          'Số điện thoại *',
          hint: '09xxxxxxxx',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _field(_city, 'Tỉnh/Thành phố *', hint: 'TP. Hồ Chí Minh'),
        const SizedBox(height: 20),
        _chipGroup('Ngôn ngữ sử dụng *', _languageOptions, _languages),
      ],
    );
  }

  Widget _professionalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionIntro(
          'Hồ sơ nghề nghiệp',
          'Giúp học viên hiểu rõ thế mạnh và phong cách đồng hành của bạn.',
        ),
        _field(
          _headline,
          'Tiêu đề hồ sơ *',
          hint: 'PT giảm mỡ và tăng cơ cho người mới',
          maxLength: 120,
        ),
        const SizedBox(height: 16),
        _field(
          _bio,
          'Giới thiệu bản thân *',
          hint:
              'Chia sẻ kinh nghiệm, phương pháp và đối tượng học viên phù hợp...',
          maxLines: 6,
          maxLength: 1000,
        ),
        const SizedBox(height: 16),
        _field(
          _experience,
          'Số năm kinh nghiệm *',
          hint: '3',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _chipGroup(
          'Chuyên môn (tối đa 5) *',
          _specialtyOptions,
          _specialties,
          maxSelection: 5,
        ),
        const SizedBox(height: 20),
        _chipGroup('Phong cách huấn luyện', _styleOptions, _styles),
        const SizedBox(height: 20),
        _chipGroup('Trình độ học viên phù hợp', _levelOptions, _levels),
      ],
    );
  }

  Widget _verificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionIntro(
          'Chứng chỉ và xác minh',
          'Admin sẽ đối chiếu giấy tờ trước khi gắn huy hiệu PT đã xác minh.',
        ),
        for (var index = 0; index < _certificates.length; index++) ...[
          _certificateCard(index),
          const SizedBox(height: 14),
        ],
        OutlinedButton.icon(
          onPressed: _certificates.length >= 10
              ? null
              : () => setState(() => _certificates.add(_CertificateDraft())),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm chứng chỉ'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _imageUploadCard(
          title: 'Giấy tờ xác minh danh tính *',
          description:
              'Ảnh CCCD hoặc giấy tờ hợp lệ. Gymer không nhìn thấy ảnh này.',
          imageUrl: _identityDocumentUrl,
          uploading: _uploadingKey == 'identity',
          onUpload: () async {
            final url = await _pickAndUpload('identity');
            if (url != null && mounted) {
              setState(() => _identityDocumentUrl = url);
            }
          },
        ),
      ],
    );
  }

  Widget _mediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionIntro(
          'Hình ảnh và thành tích',
          'Thêm ảnh hoạt động thực tế để hồ sơ của bạn đáng tin cậy hơn.',
        ),
        _field(
          _achievements,
          'Thành tích nổi bật',
          hint: 'Cuộc thi, cột mốc nghề nghiệp hoặc kết quả huấn luyện...',
          maxLines: 4,
          maxLength: 800,
        ),
        const SizedBox(height: 20),
        const Text(
          'Thư viện hình ảnh *',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tối đa 8 ảnh. Chỉ sử dụng ảnh học viên khi đã được đồng ý.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _galleryUrls.length + (_galleryUrls.length < 8 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _galleryUrls.length) return _galleryAddButton();
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_galleryUrls[index], fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filled(
                    tooltip: 'Xóa ảnh',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        setState(() => _galleryUrls.removeAt(index)),
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        CheckboxListTile(
          value: _mediaConsent,
          onChanged: (value) => setState(() => _mediaConsent = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: const Text(
            'Tôi xác nhận có quyền sử dụng các hình ảnh đã tải lên.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sau khi gửi, hồ sơ sẽ được khóa chỉnh sửa trong thời gian Admin xét duyệt.',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarPicker() {
    final hasImage = _avatarUrl.isNotEmpty;
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFFE8EFEC),
              backgroundImage: hasImage ? NetworkImage(_avatarUrl) : null,
              child: hasImage
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      size: 52,
                      color: AppColors.textSecondary,
                    ),
            ),
            if (_uploadingKey == 'avatar')
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _uploadingKey == null
              ? () async {
                  final url = await _pickAndUpload('avatar', square: true);
                  if (url != null && mounted) setState(() => _avatarUrl = url);
                }
              : null,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(hasImage ? 'Đổi ảnh đại diện' : 'Tải ảnh đại diện *'),
        ),
      ],
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final date = await showSafeDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime(now.year - 25),
          firstDate: DateTime(1940),
          lastDate: DateTime(now.year - 18, now.month, now.day),
          helpText: 'Chọn ngày sinh',
        );
        if (date != null && mounted) setState(() => _dateOfBirth = date);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration('Ngày sinh *'),
        child: Text(
          _dateOfBirth == null
              ? 'Chọn ngày'
              : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
          style: TextStyle(
            color: _dateOfBirth == null
                ? AppColors.textSecondary
                : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _genderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender.isEmpty ? null : _gender,
      decoration: _inputDecoration('Giới tính'),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Nam')),
        DropdownMenuItem(value: 'Female', child: Text('Nữ')),
        DropdownMenuItem(value: 'Other', child: Text('Khác')),
      ],
      onChanged: (value) => setState(() => _gender = value ?? ''),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: maxLines > 1
          ? TextCapitalization.sentences
          : TextCapitalization.words,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _chipGroup(
    String title,
    List<String> options,
    Set<String> selected, {
    int? maxSelection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: active,
              showCheckmark: true,
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: active ? AppColors.primary : const Color(0xFFDDE3E0),
              ),
              onSelected: (value) {
                if (value &&
                    maxSelection != null &&
                    selected.length >= maxSelection) {
                  _showMessage('Bạn chỉ được chọn tối đa $maxSelection mục.');
                  return;
                }
                setState(
                  () => value ? selected.add(option) : selected.remove(option),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _certificateCard(int index) {
    final item = _certificates[index];
    final uploadKey = 'certificate_$index';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chứng chỉ ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_certificates.length > 1)
                IconButton(
                  tooltip: 'Xóa chứng chỉ',
                  onPressed: () =>
                      setState(() => _certificates.removeAt(index)),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _draftField(
            'Tên chứng chỉ *',
            item.name,
            (value) => item.name = value,
          ),
          const SizedBox(height: 12),
          _draftField(
            'Đơn vị cấp *',
            item.issuer,
            (value) => item.issuer = value,
          ),
          const SizedBox(height: 12),
          _draftField(
            'Mã chứng chỉ',
            item.credentialNumber,
            (value) => item.credentialNumber = value,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _draftField(
                  'Ngày cấp',
                  item.issuedDate,
                  (value) => item.issuedDate = value,
                  hint: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _draftField(
                  'Hết hạn',
                  item.expiryDate,
                  (value) => item.expiryDate = value,
                  hint: 'YYYY-MM-DD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _imageUploadCard(
            title: 'Ảnh chứng chỉ *',
            description: 'Chụp rõ tên chứng chỉ và đơn vị cấp.',
            imageUrl: item.imageUrl,
            uploading: _uploadingKey == uploadKey,
            onUpload: () async {
              final url = await _pickAndUpload(uploadKey);
              if (url != null && mounted) setState(() => item.imageUrl = url);
            },
          ),
        ],
      ),
    );
  }

  Widget _draftField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? hint,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }

  Widget _imageUploadCard({
    required String title,
    required String description,
    required String imageUrl,
    required bool uploading,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDDE3E0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFE8EFEC),
              child: uploading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : imageUrl.isEmpty
                  ? const Icon(
                      Icons.image_outlined,
                      color: AppColors.textSecondary,
                    )
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: uploading ? null : onUpload,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 38),
                  ),
                  child: Text(imageUrl.isEmpty ? 'Tải ảnh lên' : 'Thay ảnh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryAddButton() {
    final uploading = _uploadingKey == 'gallery';
    return InkWell(
      onTap: uploading
          ? null
          : () async {
              final url = await _pickAndUpload('gallery');
              if (url != null && mounted) setState(() => _galleryUrls.add(url));
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3E0)),
        ),
        child: Center(
          child: uploading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 4),
                    Text('Thêm ảnh', style: TextStyle(fontSize: 11)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _step > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: _saving || _uploadingKey != null ? null : _next,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _step == 2
                            ? widget.editMode
                                  ? 'Lưu thay đổi'
                                  : 'Gửi hồ sơ xét duyệt'
                            : 'Tiếp tục',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateDraft {
  _CertificateDraft({
    this.name = '',
    this.issuer = '',
    this.credentialNumber = '',
    this.issuedDate = '',
    this.expiryDate = '',
    this.imageUrl = '',
  });

  factory _CertificateDraft.fromMap(Map<String, dynamic> map) {
    return _CertificateDraft(
      name: (map['name'] ?? '').toString(),
      issuer: (map['issuer'] ?? '').toString(),
      credentialNumber: (map['credentialNumber'] ?? '').toString(),
      issuedDate: (map['issuedDate'] ?? '').toString(),
      expiryDate: (map['expiryDate'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
    );
  }

  String name;
  String issuer;
  String credentialNumber;
  String issuedDate;
  String expiryDate;
  String imageUrl;
}
