import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/profile_repository.dart';
import '../../auth/views/welcome_screen.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import 'personal_info_screen.dart';
import 'change_password_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _profileRepo = ProfileRepository();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final data = await _profileRepo.getMyProfile();
    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  void _handleLogout() async {
    await _profileRepo.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hồ sơ & Gói thành viên',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildMembershipCard(),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cài đặt tài khoản',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    Icons.person_outline, 
                    'Thông tin cá nhân', 
                    'Cập nhật thông tin cơ bản của bạn',
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
                      );
                      if (updated == true) {
                        _fetchProfile(); // Refresh Data
                      }
                    },
                  ),
                  _buildSettingItem(
                    Icons.lock_outline, 
                    'Đổi mật khẩu', 
                    'Thay đổi mật khẩu đăng nhập',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                  _buildSettingItem(Icons.help_outline, 'Hỗ trợ', 'Liên hệ với đội ngũ hỗ trợ 24/7'),
                  _buildSettingItem(Icons.notifications_none, 'Thông báo', 'Quản lý các thông báo nhận được'),
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final fullName = _profileData?['fullName'] ?? 'Người dùng';
    final avatarUrl = _profileData?['avatarUrl'];
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.progressBackground, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.progressBackground,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : const NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thành viên MenuGreen',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard() {
    final role = _profileData?['role'] ?? 'Free';
    final isPro = role.toLowerCase().contains('pro') || role.toLowerCase().contains('premium');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GÓI HIỆN TẠI',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro ? AppColors.primary : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPro ? 'ACTIVE' : 'FREE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPro ? 'Gói Gym Pro' : 'Gói Cơ Bản',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (isPro)
            const Text(
              'Hết hạn: 31/12/2024',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            )
          else
            const Text(
              'Nâng cấp để nhận nhiều ưu đãi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Quản lý gói', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.progressBackground, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Gia hạn', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.progressBackground, width: 1)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.progressBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textDark),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
