import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/views/login_screen.dart';
import '../../profile/repositories/profile_repository.dart';
import '../repositories/coach_application_repository.dart';
import 'coach_application_screen.dart';
import 'coach_main_screen.dart';

class CoachApplicationStatusScreen extends StatefulWidget {
  const CoachApplicationStatusScreen({super.key, required this.initialData});

  final Map<String, dynamic> initialData;

  @override
  State<CoachApplicationStatusScreen> createState() =>
      _CoachApplicationStatusScreenState();
}

class _CoachApplicationStatusScreenState
    extends State<CoachApplicationStatusScreen> {
  final _repository = CoachApplicationRepository();
  late Map<String, dynamic> _data;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
  }

  String get _status =>
      (_data['applicationStatus'] ?? 'Draft').toString().toLowerCase();

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final data = await _repository.getMine();
      if (!mounted) return;
      setState(() => _data = data);
      if (_status == 'approved') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CoachMainScreen()),
          (_) => false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _logout() async {
    await ProfileRepository().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(_status);
    final canEdit =
        _status == 'draft' ||
        _status == 'needsrevision' ||
        _status == 'rejected';
    final reviewNote = (_data['reviewNote'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Xác minh hồ sơ PT',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.textDark),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 36),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, size: 44, color: config.color),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                config.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                config.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (reviewNote.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phản hồi từ Admin',
                              style: TextStyle(
                                color: Color(0xFF9A3412),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              reviewNote,
                              style: const TextStyle(
                                color: Color(0xFF9A3412),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (canEdit)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CoachApplicationScreen(initialData: _data),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    _status == 'draft'
                        ? 'Hoàn thiện hồ sơ'
                        : 'Chỉnh sửa và gửi lại',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              if (_status == 'pendingreview')
                OutlinedButton.icon(
                  onPressed: _refreshing ? null : _refresh,
                  icon: _refreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Kiểm tra trạng thái'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'approved':
        return const _StatusConfig(
          icon: Icons.verified_rounded,
          color: AppColors.primary,
          title: 'Hồ sơ đã được xác minh',
          description: 'Bạn có thể bắt đầu nhận yêu cầu kết nối từ học viên.',
        );
      case 'needsrevision':
        return const _StatusConfig(
          icon: Icons.edit_note_rounded,
          color: Color(0xFFEA580C),
          title: 'Hồ sơ cần bổ sung',
          description:
              'Hãy cập nhật những nội dung Admin yêu cầu và gửi lại hồ sơ.',
        );
      case 'rejected':
        return const _StatusConfig(
          icon: Icons.cancel_outlined,
          color: Color(0xFFDC2626),
          title: 'Hồ sơ chưa được chấp nhận',
          description:
              'Bạn có thể điều chỉnh thông tin theo phản hồi và gửi lại.',
        );
      case 'suspended':
        return const _StatusConfig(
          icon: Icons.lock_outline_rounded,
          color: Color(0xFFDC2626),
          title: 'Tài khoản PT đang bị tạm ngưng',
          description: 'Vui lòng liên hệ MenuGreen để được hỗ trợ.',
        );
      case 'pendingreview':
        return const _StatusConfig(
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFD97706),
          title: 'Hồ sơ đang chờ duyệt',
          description:
              'Admin đang kiểm tra thông tin và chứng chỉ của bạn. Bạn sẽ nhận được thông báo khi có kết quả.',
        );
      default:
        return const _StatusConfig(
          icon: Icons.assignment_outlined,
          color: AppColors.primary,
          title: 'Hoàn thiện hồ sơ PT',
          description:
              'Cung cấp thông tin nghề nghiệp để Admin xác minh tài khoản của bạn.',
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}
