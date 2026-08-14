import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../../../core/network/token_storage.dart';
import '../../casual/views/casual_hub_screen.dart';
import '../repositories/profile_repository.dart';
import '../../auth/views/welcome_screen.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../../vietnam_local/views/gym_goals_screen.dart';
import '../../vietnam_local/views/local_preferences_screen.dart';
import '../../vietnam_local/views/safety_hub_screen.dart';
import '../../vietnam_local/views/planned_vs_actual_screen.dart';
import '../../vietnam_local/views/ingredient_substitution_screen.dart';
import 'personal_info_screen.dart';
import 'allergies_screen.dart';
import 'change_password_screen.dart';
import '../../notifications/views/notification_settings_screen.dart';
import '../../adaptive_reminders/views/adaptive_reminders_screen.dart';
import '../../advanced/views/advanced_features_screen.dart';
import '../../discover/providers/favorite_food_provider.dart';

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
  bool _subscriptionLoading = false;
  String? _loadError;
  bool _subscriptionActionLoading = false;
  bool _officeModeActivated = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _subscriptionLoading = true;
      _loadError = null;
    });

    try {
      final profile = await _profileRepo.getMyProfile().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });

      final subscription = await _subscriptionRepo.getCurrent().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;
      setState(() {
        _subscription = subscription;
        _subscriptionLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _subscriptionLoading = false;
        _loadError = 'Máy chủ phản hồi chậm. Kiểm tra mạng và thử lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _subscriptionLoading = false;
        _loadError = 'Không tải được dữ liệu hồ sơ.';
      });
    }
  }

  Future<void> _handleRenew() async {
    final subscription = _subscription;
    if (subscription == null || !subscription.isActive) return;

    setState(() => _subscriptionActionLoading = true);
    final result = await _subscriptionRepo.renew(
      userSubscriptionId: subscription.id,
    );
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
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
    );
    if (!mounted) return;
    if (result == 'officeActivated') {
      setState(() => _officeModeActivated = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã mở chế độ Office.')));
    }
    await _fetchData();
  }

  void _handleLogout() async {
    await context.read<FavoriteFoodProvider>().clearSession();
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
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_loadError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _loadError!,
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _fetchData,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                      /* Legacy duplicate produced by stash conflict; retained as a comment so the
   resolved implementation below remains the single executable widget tree.
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
                  _buildSettingItem(
                    Icons.notifications_none,
                    'Thông báo',
                    'Quản lý các thông báo nhận được',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    Icons.schedule_outlined,
                    'Nhắc nhở thông minh',
                    'Cài đặt giờ ăn và lịch nhắc của bạn',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdaptiveRemindersScreen(),
                        ),
                      );
                    },
                  ),
                  if ((_profileData?['role']?.toString() ?? '').toLowerCase() == 'coach')
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a7a4a), Color(0xFF2ecc71)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1a7a4a).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CoachClientsScreen(),
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sports_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          '🏋️ Không gian PT / Coach',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Quản lý học viên, lộ trình ăn uống & đánh giá tuần',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  if (_officeModeActivated)
                    _buildSettingItem(
                      Icons.business_center_outlined,
                      'Không gian Office',
                      'Ngân sách cơm hộp, kế hoạch tuần và nguyên liệu cần mua',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfficeWorkspaceScreen(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ăn uống Việt Nam',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    Icons.restaurant_menu,
                    'Kế hoạch & thực tế',
                    'So sánh kế hoạch ăn với nhật ký thực tế',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlannedVsActualScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    Icons.fitness_center,
                    'Chế độ Gym / PT',
                    'Cấu hình calo tự đổi theo ngày tập/nghỉ',
                    onTap: () {
                      final activeSub = _subscription != null &&
                              _subscription!.isCurrentlyActive &&
                              _subscription!.subscriptionPlanName.isNotEmpty
                          ? _subscription
                          : null;
                      final isPro = activeSub != null &&
                          !activeSub.subscriptionPlanName.toLowerCase().contains('free') &&
                          !activeSub.subscriptionPlanName.toLowerCase().contains('cơ bản');

                      if (!isPro) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Yêu cầu nâng cấp'),
                            content: const Text(
                              'Chế độ Gym / PT là tính năng nâng cao dành riêng cho thành viên gói cước Pro. Bạn có muốn nâng cấp gói cước ngay bây giờ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UpgradePlanScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Nâng cấp ngay'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GymGoalsScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  _buildSettingItem(
                    Icons.public,
                    'Sở thích ăn uống',
                    'Vùng miền, ngân sách, món không thích',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocalPreferencesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    Icons.casino_outlined,
                    'Vòng quay món ăn',
                    'Quay ngẫu nhiên gợi ý món ăn hôm nay cho bạn',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CasualHubScreen(
                            openFeature: CasualFeature.luckyWheel,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    Icons.swap_horiz,
                    'Thay thế nguyên liệu',
                    'Thiết lập nguyên liệu thay thế ưa thích',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IngredientSubstitutionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    Icons.shield_outlined,
                    'Bảo mật & Tuân thủ',
                    'Miễn trừ trách nhiệm, đồng ý, xuất/xoá dữ liệu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SafetyHubScreen(),
                        ),
                      );
                    },
                  ),
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
*/
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        Icons.person_outline,
                        'Thông tin cá nhân',
                        'Cập nhật thông tin cơ bản của bạn',
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PersonalInfoScreen(),
                            ),
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
                            MaterialPageRoute(
                              builder: (context) => const AllergiesScreen(),
                            ),
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
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.help_outline,
                        'Hỗ trợ',
                        'Liên hệ với đội ngũ hỗ trợ 24/7',
                      ),
                      _buildSettingItem(
                        Icons.notifications_none,
                        'Thông báo',
                        'Quản lý các thông báo nhận được',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.schedule_outlined,
                        'Nhắc nhở thông minh',
                        'Cài đặt giờ ăn và lịch nhắc của bạn',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdaptiveRemindersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.dashboard_customize_outlined,
                        'Dịch vụ & quản lý',
                        'PT review, ngân sách, coach, nguyên liệu và quản trị',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdvancedFeaturesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ăn uống Việt Nam',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        Icons.restaurant_menu,
                        'Kế hoạch & thực tế',
                        'So sánh kế hoạch ăn với nhật ký thực tế',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlannedVsActualScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.fitness_center,
                        'Chế độ Gym / PT',
                        'Cấu hình calo tự đổi theo ngày tập/nghỉ',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GymGoalsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.public,
                        'Sở thích ăn uống',
                        'Vùng miền, ngân sách, món không thích',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocalPreferencesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.casino_outlined,
                        'Vòng quay món ăn',
                        'Quay ngẫu nhiên gợi ý món ăn hôm nay cho bạn',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CasualHubScreen(
                                openFeature: CasualFeature.luckyWheel,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.swap_horiz,
                        'Thay thế nguyên liệu',
                        'Thiết lập nguyên liệu thay thế ưa thích',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const IngredientSubstitutionScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.shield_outlined,
                        'Bảo mật & Tuân thủ',
                        'Miễn trừ trách nhiệm, đồng ý, xuất/xoá dữ liệu',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SafetyHubScreen(),
                            ),
                          );
                        },
                      ),
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
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final fullName = _profileData?['fullName'] ?? 'Người dùng';
    final rawAvatar = _profileData?['avatarUrl']?.toString();
    final avatarUrl = (rawAvatar != null && rawAvatar.isNotEmpty)
        ? rawAvatar
        : null;

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
                ? const Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textSecondary,
                  )
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
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMembershipCard() {
    if (_subscriptionLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.progressBackground),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final subscription = _subscription;
    final activeSubscription =
        subscription != null &&
            subscription.isCurrentlyActive &&
            subscription.subscriptionPlanName.isNotEmpty
        ? subscription
        : null;
    final planName = _officeModeActivated
        ? 'Office'
        : activeSubscription?.subscriptionPlanName ??
              'Free (Cơ bản)';
    final isPro =
        _officeModeActivated ||
        activeSubscription != null &&
            !activeSubscription.subscriptionPlanName.toLowerCase().contains(
              'free',
            ) &&
            !activeSubscription.subscriptionPlanName.toLowerCase().contains(
              'cơ bản',
            );

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPro ? AppColors.primary : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _officeModeActivated ? 'OFFICE' : (isPro ? 'ACTIVE' : 'FREE'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
            StreamBuilder<int>(
              stream: Stream<int>.periodic(
                const Duration(minutes: 1),
                (tick) => tick,
              ),
              builder: (context, snapshot) => Text(
                'Bắt đầu: ${formatSubscriptionDate(activeSubscription.startDate)}'
                ' • Hết hạn: ${formatSubscriptionDate(activeSubscription.endDate)}\n'
                '${formatSubscriptionRemaining(activeSubscription.endDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            )
          else if (activeSubscription != null)
            Text(
              'Trạng thái: ${activeSubscription.status.translatedData}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            )
          else
            const Text(
              'Quyền Free luôn hoạt động • Không giới hạn',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                  label: const Text(
                    'Quản lý gói',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed:
                      subscription?.isActive == true &&
                          !_subscriptionActionLoading
                      ? _handleRenew
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(
                      color: AppColors.progressBackground,
                      width: 1.5,
                    ),
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
                      : const Text(
                          'Gia hạn',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.progressBackground, width: 1),
        ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
