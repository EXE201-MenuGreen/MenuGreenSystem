import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/profile_repository.dart';
import '../../auth/views/welcome_screen.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import 'personal_info_screen.dart';
import 'allergies_screen.dart';
import 'change_password_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.onProfileUpdated});

  final VoidCallback? onProfileUpdated;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _profileRepo = ProfileRepository();
  final _subscriptionRepo = UserSubscriptionRepository();
  Map<String, dynamic>? _profileData;
  UserSubscription? _subscription;
  bool _isLoading = true;
  bool _subscriptionActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _profileRepo.getMyProfile(),
      _subscriptionRepo.getCurrent(),
    ]);

    if (!mounted) return;
    setState(() {
      _profileData = results[0] as Map<String, dynamic>?;
      _subscription = results[1] as UserSubscription?;
      _isLoading = false;
    });
  }

  Future<void> _handleRenew() async {
    final subscription = _subscription;
    if (subscription == null || !subscription.isActive) return;

    setState(() => _subscriptionActionLoading = true);
    final result = await _subscriptionRepo.renew(userSubscriptionId: subscription.id);
    if (!mounted) return;
    setState(() => _subscriptionActionLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.primary : Colors.red,
      ),
    );

    if (result.success) await _fetchData();
  }

  Future<void> _openUpgradeScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
    );
    if (mounted) await _fetchData();
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
                        await _fetchData();
                        widget.onProfileUpdated?.call();
                      }
                    },
                  ),
                  _buildSettingItem(
                    Icons.no_food_outlined,
                    'Dị ứng thực phẩm',
                    'Quản lý danh sách dị ứng của bạn',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllergiesScreen()),
                      );
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
    final rawAvatar = _profileData?['avatarUrl']?.toString();
    final avatarUrl = (rawAvatar != null && rawAvatar.isNotEmpty) ? rawAvatar : null;

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
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 48, color: AppColors.textSecondary)
                : null,
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
    final subscription = _subscription;
    final activeSubscription = subscription != null &&
            subscription.isActive &&
            subscription.daysRemaining >= 0 &&
            subscription.subscriptionPlanName.isNotEmpty
        ? subscription
        : null;
    final planName = activeSubscription?.subscriptionPlanName ??
        subscription?.subscriptionPlanName ??
        (_profileData?['role']?.toString() ?? 'Gói Cơ Bản');
    final isPro = activeSubscription != null &&
        !activeSubscription.subscriptionPlanName.toLowerCase().contains('free') &&
        !activeSubscription.subscriptionPlanName.toLowerCase().contains('cơ bản');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.3),
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
            planName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (activeSubscription != null &&
              isPro &&
              activeSubscription.endDate != null)
            Text(
              'Hết hạn: ${formatSubscriptionDate(activeSubscription.endDate)} • Còn ${activeSubscription.daysRemaining} ngày',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            )
          else if (subscription != null)
            Text(
              'Trạng thái: ${subscription.status}',
              style: const TextStyle(
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
                  onPressed: _openUpgradeScreen,
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
                  onPressed: subscription?.isActive == true && !_subscriptionActionLoading
                      ? _handleRenew
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.progressBackground, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _subscriptionActionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gia hạn', style: TextStyle(fontWeight: FontWeight.bold)),
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
            color: AppColors.progressBackground.withValues(alpha: 0.5),
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
