import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class UpgradePlanScreen extends StatelessWidget {
  const UpgradePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gói dịch vụ',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _UpgradeHeroCard(
                title: 'Nâng cấp\nMenuGreen Pro',
                subtitle:
                    'Mở khóa các tính năng cao cấp để tối ưu hóa thói quen ăn uống và dinh dưỡng của bạn.',
                onPress: () {},
              ),
              const SizedBox(height: 16),
              const _PlanCard(
                tag: 'Cơ bản',
                name: 'Miễn phí',
                price: '0đ',
                period: '',
                ctaText: 'Gói hiện tại',
                ctaEnabled: false,
                features: [
                  'Quản lý thực đơn cơ bản',
                  'Tính toán calo theo chuẩn',
                  'Phân tích dinh dưỡng cơ bản',
                ],
              ),
              const SizedBox(height: 12),
              _PlanCard(
                tag: 'Pro Tháng/GYM',
                name: '99.000đ',
                price: '99.000đ',
                period: '/tháng',
                ctaText: 'Đăng ký ngay',
                ctaEnabled: true,
                features: const [
                  'Thực đơn nâng cao',
                  'Phân tích dinh dưỡng chi tiết',
                  'Hỗ trợ AI 24/7',
                ],
                onCta: () {},
              ),
              const SizedBox(height: 12),
              _PlanCard(
                tag: 'Pro Năm',
                name: '790.000đ',
                price: '790.000đ',
                period: '/năm',
                badgeText: 'TIẾT KIỆM NHẤT',
                badgeTrailingText: '-30%',
                ctaText: 'Dùng thử 7 ngày miễn phí',
                ctaEnabled: true,
                emphasizedCta: true,
                features: const [
                  'Tất cả tính năng bên Pro',
                  'Tiết kiệm 30% chi phí năm',
                  'Truy cập offline hoàn toàn',
                  'Hỗ trợ ưu tiên (VIP) trong 1 giờ',
                ],
                onCta: () {},
              ),
              const SizedBox(height: 18),
              const Text(
                'So sánh chi tiết tính năng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const _FeatureComparisonTable(),
              const SizedBox(height: 18),
              PrimaryButton(
                text: 'Nâng cấp Pro ngay',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const _UpgradeHeroCard({
    required this.title,
    required this.subtitle,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onPress,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String tag;
  final String name;
  final String price;
  final String period;
  final String ctaText;
  final bool ctaEnabled;
  final bool emphasizedCta;
  final List<String> features;
  final String? badgeText;
  final String? badgeTrailingText;
  final VoidCallback? onCta;

  const _PlanCard({
    required this.tag,
    required this.name,
    required this.price,
    required this.period,
    required this.ctaText,
    required this.ctaEnabled,
    required this.features,
    this.onCta,
    this.badgeText,
    this.badgeTrailingText,
    this.emphasizedCta = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: AppColors.progressBackground,
      width: emphasizedCta ? 1.5 : 1,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (badgeText != null)
                _Pill(
                  text: badgeText!,
                  trailing: badgeTrailingText,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1,
                ),
              ),
              if (period.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ctaEnabled ? onCta : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    emphasizedCta ? AppColors.primary : AppColors.progressBackground.withValues(alpha: 0.25),
                foregroundColor: emphasizedCta ? Colors.white : AppColors.textSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.progressBackground.withValues(alpha: 0.25),
                disabledForegroundColor: AppColors.textLight,
              ),
              child: Text(
                ctaText,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: emphasizedCta
                      ? Colors.white
                      : (ctaEnabled ? AppColors.textDark : AppColors.textLight),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final String? trailing;

  const _Pill({required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureComparisonTable extends StatelessWidget {
  const _FeatureComparisonTable();

  @override
  Widget build(BuildContext context) {
    const rows = <_FeatureRow>[
      _FeatureRow('Số lượng thực đơn', '01', 'Vô hạn'),
      _FeatureRow('Phân tích dinh dưỡng', false, true),
      _FeatureRow('Thực đơn theo mục tiêu', false, true),
      _FeatureRow('Đề xuất Offline', false, true),
      _FeatureRow('Hỗ trợ luyện tập', false, true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.progressBackground.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'Tính năng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Cơ bản',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Pro',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...rows.map((r) => _ComparisonRow(row: r)),
        ],
      ),
    );
  }
}

class _FeatureRow {
  final String name;
  final dynamic basic;
  final dynamic pro;

  const _FeatureRow(this.name, this.basic, this.pro);
}

class _ComparisonRow extends StatelessWidget {
  final _FeatureRow row;

  const _ComparisonRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.progressBackground, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(
              row.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(child: _cell(row.basic)),
          ),
          Expanded(
            flex: 3,
            child: Center(child: _cell(row.pro)),
          ),
        ],
      ),
    );
  }

  Widget _cell(dynamic v) {
    if (v is bool) {
      return Icon(
        v ? Icons.check : Icons.close,
        size: 18,
        color: v ? AppColors.primary : AppColors.textLight,
      );
    }
    return Text(
      '$v',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}
