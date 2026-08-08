import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../micro_learning/views/micro_learning_screen.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/utils/subscription_access.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../../vietnam_local/views/daily_starter_screen.dart';
import '../../vietnam_local/views/lucky_wheel_screen.dart';

enum CasualFeature { luckyWheel, dailyStarter, microLearning }

class CasualHubScreen extends StatefulWidget {
  const CasualHubScreen({
    super.key,
    this.openFeature,
    this.subscriptionRepository,
  });

  final CasualFeature? openFeature;
  final UserSubscriptionRepository? subscriptionRepository;

  @override
  State<CasualHubScreen> createState() => _CasualHubScreenState();
}

class _CasualHubScreenState extends State<CasualHubScreen> {
  late final UserSubscriptionRepository _subscriptionRepository;

  bool _loading = true;
  bool _hasAccess = false;
  bool _openedInitialFeature = false;
  SubscriptionPlan? _casualPlan;

  @override
  void initState() {
    super.initState();
    _subscriptionRepository =
        widget.subscriptionRepository ?? UserSubscriptionRepository();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final subscriptions = await _subscriptionRepository.getActive();
    List<SubscriptionPlan> plans = const [];
    try {
      plans = await _subscriptionRepository.getAvailablePlans();
    } catch (_) {}

    SubscriptionPlan? casualPlan;
    for (final plan in plans) {
      if (plan.belongsToFeatureGroup('casual')) {
        casualPlan = plan;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _hasAccess = hasCasualSubscriptionAccess(subscriptions);
      _casualPlan = casualPlan;
      _loading = false;
    });

    if (!_openedInitialFeature && widget.openFeature != null) {
      _openedInitialFeature = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFeature(widget.openFeature!);
      });
    }
  }

  Future<void> _openFeature(CasualFeature feature) async {
    if (!_hasAccess) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradePlanScreen()),
      );
      await _loadAccess();
      if (!_hasAccess || !mounted) return;
    }

    final Widget screen = switch (feature) {
      CasualFeature.luckyWheel => const LuckyWheelScreen(),
      CasualFeature.dailyStarter => const DailyStarterScreen(),
      CasualFeature.microLearning => const MicroLearningScreen(),
    };
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gói Casual',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadAccess,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _buildHero(),
                  const SizedBox(height: 22),
                  Text(
                    '3 công cụ ăn uống đơn giản',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Chọn món nhanh, bắt đầu ngày mới và học dinh dưỡng theo dữ liệu của bạn.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CasualFeatureTile(
                    icon: Icons.casino_rounded,
                    title: 'Vòng quay món ăn',
                    subtitle:
                        '10 món cá nhân hóa, loại trừ dị ứng và cân đối ngân sách.',
                    onTap: () => _openFeature(CasualFeature.luckyWheel),
                  ),
                  const SizedBox(height: 12),
                  _CasualFeatureTile(
                    icon: Icons.bolt_rounded,
                    title: 'Khởi động 1 chạm',
                    subtitle:
                        'Gợi ý theo calo còn lại và ghi nhật ký nhanh theo khung giờ.',
                    onTap: () => _openFeature(CasualFeature.dailyStarter),
                  ),
                  const SizedBox(height: 12),
                  _CasualFeatureTile(
                    icon: Icons.psychology_rounded,
                    title: 'Góc Cảm Xúc & Thèm Ăn',
                    subtitle:
                        'Gợi ý món ăn giải cứu tức thì theo tâm trạng (Stress, Buồn ngủ, Thèm ngọt...).',
                    onTap: () => _openFeature(CasualFeature.microLearning),
                  ),
                  if (!_hasAccess) ...[
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpgradePlanScreen(),
                          ),
                        );
                        await _loadAccess();
                      },
                      icon: const Icon(Icons.lock_open_rounded, size: 19),
                      label: Text(
                        _casualPlan == null
                            ? 'Xem gói Casual'
                            : _casualPlan!.isFree
                            ? 'Kích hoạt gói Casual 0đ'
                            : 'Đăng ký gói Casual • ${formatVnd(_casualPlan!.priceVnd)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3D6), Color(0xFFFFFBF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2C96D)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB020),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Casual / Simple Eater',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _hasAccess
                            ? 'ĐÃ MỞ'
                            : _casualPlan == null
                            ? 'ĐANG TẢI'
                            : formatVnd(_casualPlan!.priceVnd),
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _hasAccess
                      ? 'Gói đang hoạt động trên tài khoản của bạn.'
                      : 'Giải quyết câu hỏi “Hôm nay ăn gì?” thật nhẹ nhàng.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CasualFeatureTile extends StatelessWidget {
  const _CasualFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1E5CC)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFFD88400), size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10.8,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
