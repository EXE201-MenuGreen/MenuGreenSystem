import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/token_storage.dart';
import '../../auth/views/login_screen.dart';
import '../../casual/views/casual_hub_screen.dart';
import '../../gymer/views/gymer_hub_screen.dart';
import '../../onboarding/repositories/user_ai_profile_repository.dart';
import '../models/subscription_models.dart';
import '../repositories/user_subscription_repository.dart';
import '../utils/subscription_access.dart';
import 'sepay_payment_screen.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key, this.repository});

  final UserSubscriptionRepository? repository;

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  late final UserSubscriptionRepository _repository;
  final _aiProfileRepository = UserAiProfileRepository();

  List<SubscriptionPlan> _plans = [];
  UserSubscription? _current;
  List<UserSubscription> _active = [];
  List<SubscriptionTransaction> _history = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? UserSubscriptionRepository();
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
        _repository.getActive(),
        _repository.getHistory(),
      ]);

      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<SubscriptionPlan>;
        _current = results[1] as UserSubscription?;
        _active = results[2] as List<UserSubscription>;
        _history = results[3] as List<SubscriptionTransaction>;
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

  Future<bool> _subscribe(SubscriptionPlan plan) async {
    if (plan.isBaselineFree) {
      _showResult('Gói Cơ bản đã được bật mặc định cho tài khoản.', true);
      return true;
    }

    if (!plan.isFree) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SepayPaymentScreen.subscribe(
            planTitle: plan.name,
            subscriptionPlanId: plan.id,
          ),
        ),
      );
      if (mounted) await _loadData();
      final group = plan.featureGroup?.trim().toLowerCase();
      if (group == 'gym') return _hasGymAccess;
      if (group == 'casual') return _hasCasualAccess;
      return _active.any((item) => item.subscriptionPlanId == plan.id);
    }

    setState(() => _actionLoading = true);
    final result = await _repository.subscribe(subscriptionPlanId: plan.id);
    if (!mounted) return false;
    setState(() => _actionLoading = false);

    _showResult(result.message, result.success);
    if (result.success) await _loadData();
    return result.success;
  }

  Future<void> _renew() async {
    final current = _current;
    if (current == null) return;

    final plan = _planById(current.subscriptionPlanId);
    final isPaidPlan = plan != null && !plan.isFree;

    if (isPaidPlan) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SepayPaymentScreen.renew(
            planTitle: current.subscriptionPlanName,
            userSubscriptionId: current.id,
          ),
        ),
      );
      if (mounted) await _loadData();
      return;
    }

    setState(() => _actionLoading = true);
    final result = await _repository.renew(userSubscriptionId: current.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    _showResult(result.message, result.success);
    if (result.success) await _loadData();
  }

  SubscriptionPlan? _planById(String planId) {
    for (final plan in _plans) {
      if (plan.id == planId) return plan;
    }
    return null;
  }

  SubscriptionPlan? _planForFeatureGroup(String featureGroup) {
    for (final plan in _plans) {
      if (plan.belongsToFeatureGroup(featureGroup)) return plan;
    }
    return null;
  }

  SubscriptionPlan? get _gymPlan => _planForFeatureGroup('gym');

  SubscriptionPlan? get _casualPlan => _planForFeatureGroup('casual');

  SubscriptionPlan? get _officePlan => _planForFeatureGroup('office');

  List<SubscriptionPlan> get _regularPlans => _plans.where((plan) {
    final group = plan.featureGroup?.trim().toLowerCase();
    return !plan.belongsToFeatureGroup('gym') &&
        !plan.belongsToFeatureGroup('casual') &&
        !plan.belongsToFeatureGroup('office') &&
        group != 'pro' &&
        !plan.isBaselineFree;
  }).toList();

  bool get _hasGymAccess => hasGymerSubscriptionAccess(_active);

  bool get _hasCasualAccess => hasCasualSubscriptionAccess(_active);

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

  Future<void> _activateOfficeMode() async {
    if (_actionLoading) return;

    final officePlan = _officePlan;
    if (officePlan == null) {
      _showResult('Gói Office chưa được cấu hình trên hệ thống.', false);
      return;
    }
    if (!officePlan.isFree) {
      await _subscribe(officePlan);
      return;
    }

    setState(() => _actionLoading = true);
    try {
      final alreadyActive =
          _current?.isCurrentlyActive == true &&
          _current?.subscriptionPlanId == officePlan.id;
      if (!alreadyActive) {
        final subscriptionResult = await _repository.subscribe(
          subscriptionPlanId: officePlan.id,
          note: 'Activate Office package',
        );
        if (!mounted) return;
        if (!subscriptionResult.success) {
          _showResult(subscriptionResult.message, false);
          return;
        }
      }

      final result = await _aiProfileRepository.upsert(eatingPattern: 'office');
      if (!mounted) return;
      if (result.requiresLogin) {
        await TokenStorage().clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      Navigator.of(context).pop('officeActivated');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openGymerPackage() async {
    if (_hasGymAccess) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GymerHubScreen()));
      return;
    }

    final plan = _gymPlan;
    if (plan == null) {
      _showResult(
        'Gói Gym/PT chưa được đồng bộ từ máy chủ. Vui lòng thử lại sau.',
        false,
      );
      return;
    }

    final activated = await _subscribe(plan);
    if (!mounted || !activated) return;

    setState(() => _actionLoading = true);
    try {
      await _aiProfileRepository.upsert(eatingPattern: 'gym');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }

    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GymerHubScreen()));
  }

  Future<void> _openCasualPackage() async {
    if (_hasCasualAccess) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CasualHubScreen()));
      return;
    }

    final plan = _casualPlan;
    if (plan == null) {
      _showResult(
        'Gói Casual chưa được đồng bộ từ máy chủ. Vui lòng thử lại sau.',
        false,
      );
      return;
    }

    final activated = await _subscribe(plan);
    if (!mounted || !activated) return;

    setState(() => _actionLoading = true);
    try {
      await _aiProfileRepository.upsert(eatingPattern: 'casual');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }

    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CasualHubScreen()));
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
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
                    _buildCurrentCard(),
                    const SizedBox(height: 16),
                    _UpgradeHeroCard(
                      title: 'Chọn gói dịch vụ',
                      subtitle:
                          'MenuGreen có 4 gói: Free (Cơ bản), Casual, Gym/PT và Office. Kích hoạt gói phù hợp để mở khóa tính năng.',
                      onPress: () {},
                    ),
                    const SizedBox(height: 16),
                    _CasualPackageCard(
                      plan: _casualPlan,
                      hasAccess: _hasCasualAccess,
                      busy: _actionLoading,
                      onOpen: _openCasualPackage,
                    ),
                    const SizedBox(height: 12),
                    _GymerPackageCard(
                      plan: _gymPlan,
                      hasAccess: _hasGymAccess,
                      busy: _actionLoading,
                      onOpen: _openGymerPackage,
                    ),
                    const SizedBox(height: 12),
                    _OfficePackageCard(
                      plan: _officePlan,
                      onOpen: _actionLoading ? null : _activateOfficeMode,
                      loading: _actionLoading,
                    ),
                    const SizedBox(height: 12),
                    if (_regularPlans.isEmpty)
                      const Text(
                        'Chưa có gói nào khả dụng.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ..._regularPlans.map(_buildPlanCard),
                    if (_current?.isActive == true &&
                        _current?.isBaselineFree == false) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _actionLoading ? null : _renew,
                        child: _actionLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
    final current = _current;
    final isBaselineFree = current == null || current.isBaselineFree;
    final planName = isBaselineFree ? 'Cơ bản' : current.subscriptionPlanName;
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
            planName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          if (isBaselineFree)
            const Text(
              'Trạng thái: Active • Không giới hạn',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else ...[
            StreamBuilder<int>(
              stream: Stream<int>.periodic(
                const Duration(minutes: 1),
                (tick) => tick,
              ),
              builder: (context, snapshot) => Text(
                'Trạng thái: ${current.status} • '
                '${formatSubscriptionRemaining(current.endDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (current.endDate != null)
              Text(
                'Hết hạn: ${formatSubscriptionDate(current.endDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
          ],
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
        tag: plan.tierLabel.isNotEmpty
            ? plan.tierLabel
            : plan.featureGroup ?? 'Gói',
        name: plan.name,
        price: formatVnd(plan.priceVnd),
        period: formatDurationLabel(plan.durationDays),
        ctaText: isCurrent
            ? 'Gói hiện tại'
            : (plan.isFree ? 'Đăng ký miễn phí' : 'Thanh toán QR'),
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

class _CasualPackageCard extends StatelessWidget {
  const _CasualPackageCard({
    required this.plan,
    required this.hasAccess,
    required this.busy,
    required this.onOpen,
  });

  final SubscriptionPlan? plan;
  final bool hasAccess;
  final bool busy;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final price = plan?.priceVnd;
    const features = <({IconData icon, String label})>[
      (icon: Icons.casino_rounded, label: 'Vòng quay'),
      (icon: Icons.bolt_rounded, label: '1 chạm'),
      (icon: Icons.auto_stories_rounded, label: 'Kiến thức'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5DE), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0CC7F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói Casual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ăn uống đơn giản, chọn món nhanh',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PlanTag(
                label: hasAccess
                    ? 'ĐÃ MỞ'
                    : plan == null
                    ? 'ĐANG TẢI'
                    : 'GÓI RIÊNG',
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == null ? 'Đang tải giá...' : formatVnd(price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              if (price == 0)
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 3),
                  child: Text(
                    'vĩnh viễn',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (final feature in features)
                Expanded(
                  child: _GymerPackageFeature(
                    icon: feature.icon,
                    label: feature.label,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy || plan == null ? null : onOpen,
              icon: busy
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      hasAccess
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_open_rounded,
                      size: 18,
                    ),
              label: Text(
                plan == null
                    ? 'Đang đồng bộ gói Casual'
                    : hasAccess
                    ? 'Mở không gian Casual'
                    : price == 0
                    ? 'Kích hoạt miễn phí'
                    : 'Đăng ký gói Casual',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD88400),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymerPackageCard extends StatelessWidget {
  const _GymerPackageCard({
    required this.plan,
    required this.hasAccess,
    required this.busy,
    required this.onOpen,
  });

  final SubscriptionPlan? plan;
  final bool hasAccess;
  final bool busy;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final price = plan?.priceVnd;
    const features = <({IconData icon, String label})>[
      (icon: Icons.track_changes_rounded, label: 'Mục tiêu'),
      (icon: Icons.rate_review_outlined, label: 'PT Review'),
      (icon: Icons.sports_gymnastics_rounded, label: 'Coach'),
      (icon: Icons.emoji_events_outlined, label: 'Lộ trình'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói Gym / PT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Không gian riêng cho mục tiêu thể hình',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PlanTag(
                label: hasAccess
                    ? 'ĐÃ MỞ'
                    : plan == null
                    ? 'ĐANG TẢI'
                    : 'GÓI RIÊNG',
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == null ? 'Đang tải giá...' : formatVnd(price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              if (price == 0)
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 3),
                  child: Text(
                    'vĩnh viễn',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (final feature in features)
                Expanded(
                  child: _GymerPackageFeature(
                    icon: feature.icon,
                    label: feature.label,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy || plan == null ? null : onOpen,
              icon: busy
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      hasAccess
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_open_rounded,
                      size: 18,
                    ),
              label: Text(
                plan == null
                    ? 'Đang đồng bộ gói Gym/PT'
                    : hasAccess
                    ? 'Mở không gian Gym/PT'
                    : price == 0
                    ? 'Kích hoạt miễn phí'
                    : 'Đăng ký gói Gym/PT',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymerPackageFeature extends StatelessWidget {
  const _GymerPackageFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _OfficePackageCard extends StatelessWidget {
  const _OfficePackageCard({
    required this.plan,
    required this.onOpen,
    required this.loading,
  });

  final SubscriptionPlan? plan;
  final Future<void> Function()? onOpen;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói Office',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dành cho nhịp sống văn phòng',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PlanTag(
                label: plan == null
                    ? 'ĐANG TẢI'
                    : plan!.isFree
                    ? 'MIỄN PHÍ'
                    : 'GÓI RIÊNG',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan == null ? 'Đang tải giá...' : formatVnd(plan!.priceVnd),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const _OfficeFeature(text: 'Nhắc uống nước và vận động định kỳ'),
          const _OfficeFeature(text: 'Kế hoạch cơm hộp theo calo và ngân sách'),
          const _OfficeFeature(text: 'Danh sách đi chợ cho cả tuần'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen == null || plan == null
                  ? null
                  : () => onOpen!(),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                loading
                    ? 'Đang xử lý gói Office...'
                    : plan == null
                    ? 'Đang đồng bộ gói Office'
                    : plan!.isFree
                    ? 'Mở tính năng Office'
                    : 'Đăng ký gói Office',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTag extends StatelessWidget {
  const _PlanTag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _OfficeFeature extends StatelessWidget {
  const _OfficeFeature({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        const Icon(Icons.check_circle, size: 17, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
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
                foregroundColor: emphasizedCta
                    ? Colors.white
                    : AppColors.textSecondary,
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
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.primary,
                    ),
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
