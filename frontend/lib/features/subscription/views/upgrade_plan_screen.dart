import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/subscription_models.dart';
import '../repositories/user_subscription_repository.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  final _repository = UserSubscriptionRepository();

  List<SubscriptionPlan> _plans = [];
  UserSubscription? _current;
  List<SubscriptionTransaction> _history = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repository.getAvailablePlans(),
        _repository.getCurrent(),
        _repository.getHistory(),
      ]);

      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<SubscriptionPlan>;
        _current = results[1] as UserSubscription?;
        _history = results[2] as List<SubscriptionTransaction>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu gói thành viên';
        _loading = false;
      });
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    setState(() => _actionLoading = true);
    final result = await _repository.subscribe(subscriptionPlanId: plan.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    _showResult(result.message, result.success);
    if (result.success) await _loadData();
  }

  Future<void> _renew() async {
    final current = _current;
    if (current == null) return;

    setState(() => _actionLoading = true);
    final result = await _repository.renew(userSubscriptionId: current.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    _showResult(result.message, result.success);
    if (result.success) await _loadData();
  }

  Future<void> _cancel() async {
    final current = _current;
    if (current == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy gói thành viên'),
        content: Text(
          'Bạn có chắc muốn hủy gói "${current.subscriptionPlanName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy gói', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    final result = await _repository.cancel(userSubscriptionId: current.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    _showResult(result.message, result.success);
    if (result.success) await _loadData();
  }

  void _showResult(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.primary : Colors.red,
      ),
    );
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
          'Gói dịch vụ',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading || _actionLoading ? null : _loadData,
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_current != null) _buildCurrentCard(),
                    if (_current != null) const SizedBox(height: 16),
                    _UpgradeHeroCard(
                      title: 'Nâng cấp\nMenuGreen Pro',
                      subtitle:
                          'Chọn gói phù hợp để mở khóa tính năng dinh dưỡng nâng cao.',
                      onPress: () {},
                    ),
                    const SizedBox(height: 16),
                    if (_plans.isEmpty)
                      const Text(
                        'Chưa có gói nào khả dụng.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ..._plans.map(_buildPlanCard),
                    if (_current?.isActive == true) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _actionLoading ? null : _renew,
                        child: _actionLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Gia hạn gói hiện tại'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _actionLoading ? null : _cancel,
                        child: const Text(
                          'Hủy gói',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Lịch sử giao dịch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._history.map(_buildHistoryItem),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentCard() {
    final current = _current!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GÓI ĐANG DÙNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            current.subscriptionPlanName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trạng thái: ${current.status} • Còn ${current.daysRemaining} ngày',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (current.endDate != null)
            Text(
              'Hết hạn: ${formatSubscriptionDate(current.endDate)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrent =
        _current?.subscriptionPlanId == plan.id && _current?.isActive == true;
    final features = _planFeatures(plan);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PlanCard(
        tag: plan.tierLabel.isNotEmpty ? plan.tierLabel : plan.featureGroup ?? 'Gói',
        name: plan.name,
        price: formatVnd(plan.priceVnd),
        period: formatDurationLabel(plan.durationDays),
        ctaText: isCurrent ? 'Gói hiện tại' : 'Đăng ký ngay',
        ctaEnabled: !isCurrent && !_actionLoading,
        emphasizedCta: !plan.isFree && plan.durationDays >= 365,
        features: features,
        onCta: isCurrent ? null : () => _subscribe(plan),
      ),
    );
  }

  List<String> _planFeatures(SubscriptionPlan plan) {
    if (plan.description != null && plan.description!.trim().isNotEmpty) {
      return plan.description!
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    return [
      if (plan.durationDays > 0) 'Thời hạn ${plan.durationDays} ngày',
      if (plan.featureGroup != null && plan.featureGroup!.isNotEmpty)
        'Nhóm tính năng: ${plan.featureGroup}',
      'Giá ${formatVnd(plan.priceVnd)}',
    ];
  }

  Widget _buildHistoryItem(SubscriptionTransaction item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.transactionType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  formatSubscriptionDate(item.transactionDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.amount > 0 ? formatVnd(item.amount) : '—',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
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
    this.emphasizedCta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.progressBackground,
          width: emphasizedCta ? 1.5 : 1,
        ),
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
          Text(
            tag,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
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
                backgroundColor: emphasizedCta
                    ? AppColors.primary
                    : AppColors.progressBackground.withValues(alpha: 0.25),
                foregroundColor:
                    emphasizedCta ? Colors.white : AppColors.textSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            (feature) => Padding(
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
                      feature,
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
