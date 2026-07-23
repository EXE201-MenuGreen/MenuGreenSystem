import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../advanced/views/advanced_features_screen.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../../vietnam_local/views/gym_goals_screen.dart';
import 'premium_programs_screen.dart';

enum GymerFeature { goals, companion, programs }

class GymerHubScreen extends StatefulWidget {
  const GymerHubScreen({super.key, this.openFeature});

  final GymerFeature? openFeature;

  @override
  State<GymerHubScreen> createState() => _GymerHubScreenState();
}

class _GymerHubScreenState extends State<GymerHubScreen> {
  final _subscriptionRepository = UserSubscriptionRepository();

  bool _loading = true;
  bool _hasAccess = false;
  bool _openedInitialFeature = false;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final access = await _subscriptionRepository.getFeatureAccess();
    if (!mounted) return;

    setState(() {
      _hasAccess = access.hasGym;
      _loading = false;
    });

    if (!_openedInitialFeature && widget.openFeature != null) {
      _openedInitialFeature = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFeature(widget.openFeature!);
      });
    }
  }

  Future<void> _openFeature(GymerFeature feature) async {
    if (!_hasAccess) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradePlanScreen()),
      );
      await _loadAccess();
      if (!_hasAccess || !mounted) return;
    }

    final Widget screen = switch (feature) {
      GymerFeature.goals => const GymGoalsScreen(),
      GymerFeature.companion => const AdvancedFeaturesScreen(
        gymerOnly: true,
        initialIndex: 0,
      ),
      GymerFeature.programs => const PremiumProgramsScreen(),
    };

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gói Gym / PT',
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
                    '3 công cụ dành cho Gymer',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Mỗi công cụ là một luồng riêng, dữ liệu vẫn đồng bộ với hồ sơ dinh dưỡng của bạn.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
                    children: [
                      _GymerFeatureTile(
                        icon: Icons.track_changes_rounded,
                        title: 'Mục tiêu Gym',
                        subtitle: 'Calo, protein và lịch tập',
                        onTap: () => _openFeature(GymerFeature.goals),
                      ),
                      _GymerFeatureTile(
                        icon: Icons.people_alt_outlined,
                        title: 'HLV & PT Review',
                        subtitle: 'Kết nối HLV và gửi báo cáo cho PT',
                        onTap: () => _openFeature(GymerFeature.companion),
                      ),
                      _GymerFeatureTile(
                        icon: Icons.emoji_events_outlined,
                        title: 'Lộ trình',
                        subtitle: 'Theo dõi chương trình 8–12 tuần',
                        onTap: () => _openFeature(GymerFeature.programs),
                      ),
                    ],
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
                      label: const Text('Kích hoạt gói Gym/PT 0đ'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 27,
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
                        'Gói Gymer',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
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
                        _hasAccess ? 'ĐÃ MỞ' : '0Đ',
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
                      : 'Không gian riêng cho mục tiêu thể hình và PT.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    height: 1.35,
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

class _GymerFeatureTile extends StatelessWidget {
  const _GymerFeatureTile({
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
            border: Border.all(color: AppColors.progressBackground),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const Spacer(),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
