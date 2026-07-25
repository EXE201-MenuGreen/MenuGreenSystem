import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/utils/subscription_access.dart';
import '../../subscription/widgets/premium_paywall_widget.dart';
import '../../home/widgets/weight_log_sheet.dart';
import '../models/vietnam_local_models.dart';
import '../providers/gym_goals_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/views/notification_inbox_screen.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../meal_plan/models/meal_plan_models.dart';
import '../../meal_plan/models/meal_plan_requests.dart';
import '../../advanced/repositories/advanced_repository.dart';

/// Gym/PT Goal workflow — `2.13 Gym/PT Goal-Based Workflow`.
class GymGoalsScreen extends StatefulWidget {
  const GymGoalsScreen({super.key});

  @override
  State<GymGoalsScreen> createState() => _GymGoalsScreenState();
}

class _GymGoalsScreenState extends State<GymGoalsScreen> {
  final _subRepo = UserSubscriptionRepository();
  bool _subLoading = true;
  bool _hasProAccess = false;
  UserMealPlan? _todayPlan;
  bool _loadingPlan = true;
  bool _isSentToPt = false;
  Map<String, dynamic>? _activeRouteReq;
  int _suggestionPage = 0;
  int _activeSuggestionPage = 0;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    setState(() {
      _subLoading = true;
    });

    try {
      final subscriptions = await _subRepo.getActive();
      final hasAccess = hasGymerSubscriptionAccess(subscriptions);

      setState(() {
        _hasProAccess = hasAccess;
        _subLoading = false;
      });

      if (hasAccess) {
        _loadGymData();
      }
    } catch (_) {
      setState(() {
        _hasProAccess = false;
        _subLoading = false;
      });
    }
  }

  void _loadGymData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<GymGoalsProvider>();
      await provider.loadProfile();
      if (!mounted) return;
      await provider.loadPlan(top: 10);
      await _loadTodayPlan();
      await _checkPtRequestStatus();
    });
  }

  Future<void> _loadTodayPlan() async {
    if (!_hasProAccess) return;
    setState(() {
      _loadingPlan = true;
    });
    try {
      final plan = await MealPlanRepository().getByDate(DateTime.now());
      setState(() {
        _todayPlan = plan;
        _loadingPlan = false;
      });
    } catch (_) {
      setState(() {
        _loadingPlan = false;
      });
    }
  }

  Future<void> _loadTodayPlanQuietly() async {
    if (!_hasProAccess) return;
    try {
      final plan = await MealPlanRepository().getByDate(DateTime.now());
      if (mounted) {
        setState(() {
          _todayPlan = plan;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkPtRequestStatus() async {
    if (!_hasProAccess) return;
    try {
      final today = DateTime.now();
      final daysToMonday = today.weekday - 1;
      final monday = today.subtract(Duration(days: daysToMonday));
      final weekStartStr =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

      final reqs = await AdvancedRepository().ptRequests();
      // Find if there is an active RouteApproval request for the current week (pending or reviewed)
      final activeReq = reqs.firstWhere((r) {
        final weekStart = (r['weekStartDate'] ?? '').toString();
        final status = (r['status'] ?? '').toString().toLowerCase();
        final reqType = (r['requestType'] ?? '').toString().toLowerCase();
        return weekStart.startsWith(weekStartStr) &&
            (status == 'pending' || status == 'reviewed') &&
            (reqType.isEmpty || reqType == 'routeapproval');
      }, orElse: () => <String, dynamic>{});

      if (mounted) {
        setState(() {
          _isSentToPt = activeReq.isNotEmpty;
          _activeRouteReq = activeReq.isNotEmpty ? activeReq : null;
        });
      }
    } catch (e) {
      debugPrint('Error checking PT request status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chế độ Gym / PT',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.textDark,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationInboxScreen(),
                        ),
                      );
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _subLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : !_hasProAccess
            ? const PremiumPaywallWidget(
                featureName: 'Chế độ Gym / PT',
                featureDescription:
                    'Kích hoạt gói Gym/PT để dùng mục tiêu calo, protein và lịch tập chuyên biệt.',
              )
            : Consumer<GymGoalsProvider>(
                builder: (context, provider, _) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await provider.loadProfile();
                      await provider.loadPlan(top: 10);
                      await _loadTodayPlan();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        InfoCard(
                          icon: Icons.fitness_center,
                          title: _goalLabel(
                            provider.profile?.goalMode ?? 'maintain',
                          ),
                          subtitle: _scheduleSummary(provider.profile),
                          value: _calorieSummary(provider.profile),
                          footnote:
                              'Ngưỡng an toàn: tối thiểu 1200 kcal/ngày (theo NHS).',
                          trailing: TextButton(
                            onPressed: () =>
                                _openEditor(context, provider.profile),
                            child: const Text('Cấu hình'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBodyTargetsCard(provider),
                        const SizedBox(height: 16),
                        _buildRecalibrateCard(provider),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: SectionHeader(
                                title: 'Lộ trình ăn uống hôm nay',
                                icon: Icons.restaurant_menu,
                                subtitle:
                                    'Phân loại chi tiết và đồng bộ nhật ký PT',
                              ),
                            ),
                            if (_todayPlan != null &&
                                _todayPlan!.items.isNotEmpty)
                              TextButton.icon(
                                onPressed: _clearTodayPlan,
                                icon: const Icon(
                                  Icons.delete_sweep,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Xóa hết món',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPlanList(provider),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              provider.errorMessage!,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _goalLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'cut':
        return 'Cắt giảm mỡ (Cut)';
      case 'bulk':
        return 'Tăng cơ (Bulk)';
      case 'recomp':
        return 'Tái cấu trúc cơ thể (Recomp)';
      case 'maintain':
      default:
        return 'Duy trì (Maintain)';
    }
  }

  String _scheduleSummary(GymGoalProfile? p) {
    if (p == null) return 'Đang tải cấu hình...';
    final schedule = p.weeklyTrainingSchedule.trim();
    if (schedule.isEmpty) return 'Chưa thiết lập lịch tập';
    return 'Ngày tập: $schedule'
        '${p.restDaysPerWeek != null ? ' • Nghỉ ${p.restDaysPerWeek} ngày/tuần' : ''}';
  }

  String _calorieSummary(GymGoalProfile? p) {
    if (p == null) return '—';
    final train = p.trainingDayTargetCalories;
    final rest = p.restDayTargetCalories;
    if (train == null && rest == null) return 'Chưa thiết lập';
    return 'Tập: ${train ?? '—'} kcal • Nghỉ: ${rest ?? '—'} kcal';
  }

  bool _hasGoalConfig(GymGoalProfile? p) {
    if (p == null) return false;
    return p.trainingDayTargetCalories != null ||
        p.restDayTargetCalories != null ||
        p.dailyDetails.isNotEmpty ||
        p.weeklyDetails.isNotEmpty ||
        p.monthlyDetails.isNotEmpty;
  }

  Widget _buildRecalibrateCard(GymGoalsProvider provider) {
    final last = provider.lastRecalibration;
    return InfoCard(
      icon: Icons.tune,
      title: 'Hiệu chỉnh mục tiêu',
      subtitle: last == null
          ? 'Đánh giá cân nặng tuần qua và điều chỉnh calo tự động.'
          : 'Gợi ý hiện tại: ${last.suggestedTargetCalories} kcal',
      footnote: last == null
          ? null
          : ApiMessageTranslator.translate(last.reason),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: provider.isRecalibrating ? null : provider.recalibrate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: provider.isRecalibrating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text(
            'Hiệu chỉnh ngay',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyTargetsCard(GymGoalsProvider provider) {
    final profile = provider.profile;
    final weight = profile?.targetWeightKg;
    final bodyFat = profile?.targetBodyFatPercent;
    final targetText = [
      if (weight != null) '${weight.toStringAsFixed(1)} kg',
      if (bodyFat != null) '${bodyFat.toStringAsFixed(1)}% mỡ',
    ].join(' • ');

    return InfoCard(
      icon: Icons.monitor_weight_outlined,
      title: 'Chỉ số cơ thể mục tiêu',
      subtitle: targetText.isEmpty
          ? 'Thiết lập cân nặng và tỷ lệ mỡ mục tiêu trong cấu hình gym.'
          : targetText,
      footnote:
          'Ghi chỉ số định kỳ để hệ thống so sánh xu hướng và hiệu chỉnh mục tiêu.',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final saved = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const WeightLogSheet(),
            );
            if (saved == true && mounted) {
              await provider.recalibrate();
            }
          },
          icon: const Icon(Icons.add_chart_outlined, size: 18),
          label: const Text('Cập nhật cân nặng / % mỡ'),
        ),
      ),
    );
  }

  Widget _buildPlanList(GymGoalsProvider provider) {
    if (_loadingPlan) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    // Hiển thị items có origin = 'gym' hoặc null/empty (tương thích dữ liệu cũ)
    final gymItems =
        _todayPlan?.items
            .where(
              (x) =>
                  x.origin == null ||
                  x.origin!.isEmpty ||
                  x.origin?.toLowerCase() == 'gym',
            )
            .toList() ??
        [];
    if (gymItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner prompting user to initialize plan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Chưa có lộ trình ăn uống hôm nay.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hãy bấm nút dưới đây để khởi tạo lộ trình ăn uống chia theo bữa.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _initializePlanFromSuggestions(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: const Text(
                    'Khởi tạo lộ trình',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (_hasGoalConfig(provider.profile)) ...[
            const SizedBox(height: 20),
            const Text(
              'Gợi ý thực đơn hôm nay từ AI:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            if (provider.planSuggestions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.progressBackground),
                ),
                child: const Text(
                  'Chưa có gợi ý thực đơn.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final suggestions = provider.planSuggestions;
                  const itemsPerPage = 5;
                  final totalItems = suggestions.length;
                  final totalPages = (totalItems / itemsPerPage).ceil();

                  if (_suggestionPage >= totalPages) {
                    _suggestionPage = (totalPages - 1)
                        .clamp(0, totalItems)
                        .toInt();
                  }

                  final startIndex = _suggestionPage * itemsPerPage;
                  final endIndex = (startIndex + itemsPerPage).clamp(
                    0,
                    totalItems,
                  );
                  final currentPageItems = totalItems == 0
                      ? []
                      : suggestions.sublist(startIndex, endIndex);

                  return Column(
                    children: [
                      for (final item in currentPageItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.progressBackground,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.type.toLowerCase().contains('recipe')
                                        ? Icons.menu_book
                                        : Icons.restaurant,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name.isEmpty
                                            ? 'Món gợi ý'
                                            : item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.caloriesKcal.toStringAsFixed(0)} kcal • '
                                        'P ${item.proteinG.toStringAsFixed(0)}g • '
                                        'Điểm ${item.score.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (totalPages > 1) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _suggestionPage > 0
                                  ? () => setState(() => _suggestionPage--)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              'Trang ${_suggestionPage + 1} / $totalPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            IconButton(
                              onPressed: _suggestionPage < totalPages - 1
                                  ? () => setState(() => _suggestionPage++)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ],
      );
    }

    return _buildTodayMealPlan(provider);
  }

  Widget _buildTodayMealPlan(GymGoalsProvider provider) {
    final slots = ['breakfast', 'lunch', 'dinner', 'snack'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in slots) ...[
          _buildMealSlot(slot, provider),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        if (_isSentToPt) ...[
          if (_activeRouteReq != null &&
              _activeRouteReq!['status']?.toString().toLowerCase() ==
                  'reviewed')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Lộ trình đã được PT duyệt!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if ((_activeRouteReq!['ptComment'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nhận xét từ PT: ${_activeRouteReq!['ptComment']}',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _loadingPlan = true);
                        try {
                          await AdvancedRepository().ptAction(
                            _activeRouteReq!['reportId'].toString(),
                            'apply',
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã áp dụng lộ trình dinh dưỡng thành công!',
                                ),
                              ),
                            );
                          }
                          _loadGymData();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi áp dụng lộ trình: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _loadingPlan = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Áp dụng lộ trình mới'),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lộ trình đã được gửi cho PT duyệt và đã bị khóa chỉnh sửa.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendToPt,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Gửi lộ trình cho PT duyệt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        if (_hasGoalConfig(provider.profile)) ...[
          const SizedBox(height: 32),
          const Text(
            'Danh sách món ăn gợi ý hôm nay từ AI:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn nút "Gán" để thêm món gợi ý này vào các bữa chính hoặc phụ trong lộ trình của bạn.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (provider.planSuggestions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.progressBackground),
              ),
              child: const Text(
                'Chưa có gợi ý thực đơn.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Builder(
              builder: (context) {
                // Chỉ check gym items để so sánh với suggestions
                final gymItems =
                    _todayPlan?.items
                        .where(
                          (x) =>
                              x.origin == null ||
                              x.origin!.isEmpty ||
                              x.origin?.toLowerCase() == 'gym',
                        )
                        .toList() ??
                    [];
                final addedIds = gymItems
                    .map(
                      (x) =>
                          (x.foodId ?? x.recipeId ?? '').trim().toLowerCase(),
                    )
                    .where((s) => s.isNotEmpty)
                    .toSet();

                debugPrint('GymGoals: gym items size = ${gymItems.length}');
                for (final x in gymItems) {
                  debugPrint(
                    'GymGoals:   item id=${x.id}, foodId=${x.foodId}, recipeId=${x.recipeId}, name=${x.displayName}, origin=${x.origin}',
                  );
                }
                debugPrint('GymGoals: addedIds: $addedIds');

                final remainingSuggestions = provider.planSuggestions
                    .where((x) => !addedIds.contains(x.id.trim().toLowerCase()))
                    .toList();

                debugPrint(
                  'GymGoals: remainingSuggestions size = ${remainingSuggestions.length}',
                );

                if (remainingSuggestions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.progressBackground),
                    ),
                    child: const Text(
                      'Đã thêm tất cả món gợi ý vào lộ trình hôm nay.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                const itemsPerPage = 5;
                final totalItems = remainingSuggestions.length;
                final totalPages = (totalItems / itemsPerPage).ceil();

                if (_activeSuggestionPage >= totalPages) {
                  _activeSuggestionPage = (totalPages - 1)
                      .clamp(0, totalItems)
                      .toInt();
                }

                final startIndex = _activeSuggestionPage * itemsPerPage;
                final endIndex = (startIndex + itemsPerPage).clamp(
                  0,
                  totalItems,
                );
                final currentPageItems = totalItems == 0
                    ? []
                    : remainingSuggestions.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    for (final item in currentPageItems) ...[
                      Builder(
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.progressBackground,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    final bool isFood = !item.type
                                        .toLowerCase()
                                        .contains('recipe');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => isFood
                                            ? FoodDetailScreen(foodId: item.id)
                                            : RecipeDetailScreen(
                                                recipeId: item.id,
                                              ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            item.type.toLowerCase().contains(
                                                  'recipe',
                                                )
                                                ? Icons.menu_book
                                                : Icons.restaurant,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name.isEmpty
                                                    ? 'Món gợi ý'
                                                    : item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textDark,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.caloriesKcal.toStringAsFixed(0)} kcal • '
                                                'P ${item.proteinG.toStringAsFixed(0)}g • '
                                                'Điểm ${item.score.toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!_isSentToPt)
                                          PopupMenuButton<String>(
                                            icon: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.add,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'Gán',
                                                    style: TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onSelected: (mealType) =>
                                                _addPlanItem(mealType, item),
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'breakfast',
                                                child: Text('Bữa sáng'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'lunch',
                                                child: Text('Bữa trưa'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'dinner',
                                                child: Text('Bữa tối'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'snack',
                                                child: Text(
                                                  'Bữa phụ / Ăn thêm',
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (totalPages > 1) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _activeSuggestionPage > 0
                                ? () => setState(() => _activeSuggestionPage--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            'Trang ${_activeSuggestionPage + 1} / $totalPages',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          IconButton(
                            onPressed: _activeSuggestionPage < totalPages - 1
                                ? () => setState(() => _activeSuggestionPage++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildMealSlot(String mealType, GymGoalsProvider provider) {
    // Chỉ hiển thị items có origin = 'gym' (từ AI Gym Goals)
    final items =
        _todayPlan?.items
            .where(
              (x) =>
                  x.mealType.toLowerCase() == mealType &&
                  (x.origin == null ||
                      x.origin!.isEmpty ||
                      x.origin?.toLowerCase() == 'gym'),
            )
            .toList() ??
        [];
    final color = _mealSlotColor(mealType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header slot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(_mealSlotIcon(mealType), color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  _mealSlotTitle(mealType),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Text(
                    '${items.fold<int>(0, (sum, item) => sum + item.targetCalories)} kcal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          // Items list
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Chưa có món ăn nào.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            )
          else
            Column(
              children: [
                for (final item in items)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        item.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${item.targetCalories} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () {
                        if (item.isFood && item.foodId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodDetailScreen(foodId: item.foodId!),
                            ),
                          );
                        } else if (item.recipeId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(recipeId: item.recipeId!),
                            ),
                          );
                        }
                      },
                      trailing: _isSentToPt
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              onPressed: () => _deletePlanItem(item),
                            ),
                    ),
                  ),
              ],
            ),
          // Add button
          if (_hasGoalConfig(provider.profile) && !_isSentToPt)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () => _showAddSuggestionSheet(mealType),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 36),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm món từ gợi ý'),
              ),
            ),
        ],
      ),
    );
  }

  String _mealSlotTitle(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
      default:
        return 'Bữa phụ / Ăn thêm';
    }
  }

  IconData _mealSlotIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.light_mode_outlined;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nights_stay_outlined;
      case 'snack':
      default:
        return Icons.coffee_outlined;
    }
  }

  Color _mealSlotColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFF2563EB);
      case 'lunch':
        return const Color(0xFFD97706);
      case 'dinner':
        return const Color(0xFF7C3AED);
      case 'snack':
      default:
        return const Color(0xFF10B981);
    }
  }

  Future<void> _initializePlanFromSuggestions(GymGoalsProvider provider) async {
    if (!_hasGoalConfig(provider.profile) || provider.planSuggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn chưa cấu hình mục tiêu Gym / PT. Vui lòng thiết lập trước.',
          ),
        ),
      );
      return;
    }
    setState(() => _loadingPlan = true);
    try {
      final list = <Map<String, dynamic>>[];
      final shuffled = List<LocalRecommendationItem>.from(
        provider.planSuggestions,
      )..shuffle();
      final usedIds = <String>{};
      int assignedCount = 0;

      for (final s in shuffled) {
        if (assignedCount >= 4) break;

        final idStr = s.id.toString();
        if (usedIds.contains(idStr)) continue;
        usedIds.add(idStr);

        String mealType = 'breakfast';
        if (assignedCount == 1) {
          mealType = 'lunch';
        } else if (assignedCount == 2) {
          mealType = 'dinner';
        } else if (assignedCount == 3) {
          mealType = 'snack';
        }

        list.add({
          'mealType': mealType,
          'foodId': s.type.toLowerCase().contains('recipe')
              ? null
              : s.id.toString(),
          'recipeId': s.type.toLowerCase().contains('recipe')
              ? s.id.toString()
              : null,
          'targetCalories': s.caloriesKcal.round(),
          'origin': 'gym', // Tạo bởi AI Gym Goals
        });

        assignedCount++;
      }

      await MealPlanRepository().createFromDailyMenu(
        plannedDate: DateTime.now(),
        targetCalories: provider.profile?.trainingDayTargetCalories ?? 2000,
        items: list,
      );
      await _loadTodayPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khởi tạo lộ trình thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiMessageTranslator.translate(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _clearTodayPlan() async {
    if (_todayPlan == null) return;
    setState(() => _loadingPlan = true);
    try {
      final itemsToDelete = List<MealPlanItemModel>.from(_todayPlan!.items);
      for (final item in itemsToDelete) {
        await MealPlanRepository().deleteItem(_todayPlan!.id, item.id);
      }
      await _loadTodayPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã làm sạch lộ trình ăn uống hôm nay.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể làm sạch lộ trình. Vui lòng thử lại sau.')));
      }
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _deletePlanItem(MealPlanItemModel item) async {
    if (_todayPlan == null) return;

    // Save original items list in case we need to revert
    final originalItems = List<MealPlanItemModel>.from(_todayPlan!.items);

    // Optimistically remove item from UI immediately
    setState(() {
      _todayPlan!.items.removeWhere((x) => x.id == item.id);
    });

    try {
      await MealPlanRepository().deleteItem(_todayPlan!.id, item.id);
      await _loadTodayPlanQuietly();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa món ăn khỏi lộ trình.')),
        );
      }
    } catch (e) {
      // Revert UI to original state on failure
      setState(() {
        _todayPlan = UserMealPlan(
          id: _todayPlan!.id,
          title: _todayPlan!.title,
          planType: _todayPlan!.planType,
          startDate: _todayPlan!.startDate,
          targetCalories: _todayPlan!.targetCalories,
          items: originalItems,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể xóa món ăn khỏi lộ trình. Vui lòng thử lại.')));
      }
    }
  }

  Future<void> _addPlanItem(
    String mealType,
    LocalRecommendationItem item,
  ) async {
    if (_todayPlan == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempItem = MealPlanItemModel(
      id: tempId,
      mealType: mealType,
      foodId: item.type.toLowerCase().contains('recipe') ? null : item.id,
      recipeId: item.type.toLowerCase().contains('recipe') ? item.id : null,
      targetCalories: item.caloriesKcal.round(),
      isCompleted: false,
      foodName: item.type.toLowerCase().contains('recipe') ? null : item.name,
      recipeName: item.type.toLowerCase().contains('recipe') ? item.name : null,
      sourceEntityType: item.type,
    );

    // Optimistically add item to UI immediately
    setState(() {
      _todayPlan!.items.add(tempItem);
    });

    try {
      await MealPlanRepository().addItem(
        _todayPlan!.id,
        AddItemRequest(
          mealType: mealType,
          foodId: item.type.toLowerCase().contains('recipe')
              ? null
              : item.id.toString(),
          recipeId: item.type.toLowerCase().contains('recipe')
              ? item.id.toString()
              : null,
          targetCalories: item.caloriesKcal.round(),
          origin: 'gym', // Tạo bởi AI Gym Goals
        ),
      );
      await _loadTodayPlanQuietly();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm món ăn vào lộ trình.')),
        );
      }
    } catch (e) {
      // Revert UI to original state on failure
      setState(() {
        _todayPlan!.items.removeWhere((x) => x.id == tempId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể thêm món ăn vào lộ trình. Vui lòng thử lại.')));
      }
    }
  }

  void _showAddSuggestionSheet(String mealType) {
    final provider = context.read<GymGoalsProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm món gợi ý vào ${_mealSlotTitle(mealType)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.planSuggestions.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có gợi ý. Hãy cấu hình gym trước.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.planSuggestions.length,
                        itemBuilder: (context, index) {
                          final item = provider.planSuggestions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(
                                item.type.toLowerCase().contains('recipe')
                                    ? Icons.menu_book
                                    : Icons.restaurant,
                                color: AppColors.primary,
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.caloriesKcal.round()} kcal • P ${item.proteinG.round()}g',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _addPlanItem(mealType, item);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendToPt() async {
    setState(() => _loadingPlan = true);
    try {
      final coaches = await AdvancedRepository().myCoaches();
      if (coaches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bạn chưa liên kết với PT nào. Vui lòng kết nối với PT trước.',
              ),
            ),
          );
        }
        return;
      }

      final today = DateTime.now();
      final daysToMonday = today.weekday - 1;
      final monday = today.subtract(Duration(days: daysToMonday));
      final weekStartStr =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

      await AdvancedRepository().createPtReport(
        weekStartStr,
        7,
        requestType: 'RouteApproval',
      );
      await _checkPtRequestStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu duyệt lộ trình thành công đến PT!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể gửi lộ trình cho HLV. Vui lòng thử lại sau.')));
      }
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    GymGoalProfile? profile,
  ) async {
    final updated = await Navigator.push<GymGoalProfile?>(
      context,
      MaterialPageRoute(builder: (_) => GymGoalsEditorScreen(initial: profile)),
    );
    if (updated != null && context.mounted) {
      final provider = context.read<GymGoalsProvider>();
      final ok = await provider.save(updated);
      if (!ok) return;
      await provider.loadPlan(top: 10);
    }
  }
}

class GymGoalsEditorScreen extends StatefulWidget {
  const GymGoalsEditorScreen({super.key, this.initial});

  final GymGoalProfile? initial;

  @override
  State<GymGoalsEditorScreen> createState() => _GymGoalsEditorScreenState();
}

class _GymGoalsEditorScreenState extends State<GymGoalsEditorScreen> {
  late final Set<String> _selectedDays;
  late final List<GymDayDetail> _dailyDetails;
  late final List<GymWeeklyDetail> _weeklyDetails;
  late final List<GymMonthlyDetail> _monthlyDetails;
  late String _goalMode;

  late final TextEditingController _targetWeight;
  late final TextEditingController _targetBodyFat;
  late final TextEditingController _generalNotes;

  late final TextEditingController _calController;
  late final TextEditingController _minCalController;
  late final TextEditingController _maxCalController;
  late final TextEditingController _minProteinController;
  late final TextEditingController _maxProteinController;
  late final TextEditingController _notesController;

  int _activeTab = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isDayTraining = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _selectedDays = (init?.weeklyTrainingSchedule ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    _dailyDetails = List<GymDayDetail>.from(init?.dailyDetails ?? []);
    _weeklyDetails = List<GymWeeklyDetail>.from(init?.weeklyDetails ?? []);
    _monthlyDetails = List<GymMonthlyDetail>.from(init?.monthlyDetails ?? []);
    _goalMode = init?.goalMode ?? 'maintain';

    _targetWeight = TextEditingController(
      text: init?.targetWeightKg?.toString() ?? '',
    );
    _targetBodyFat = TextEditingController(
      text: init?.targetBodyFatPercent?.toString() ?? '',
    );
    _generalNotes = TextEditingController(text: init?.notes ?? '');

    _calController = TextEditingController();
    _minCalController = TextEditingController();
    _maxCalController = TextEditingController();
    _minProteinController = TextEditingController();
    _maxProteinController = TextEditingController();
    _notesController = TextEditingController();

    _loadSelectedConfig();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _initializing = false);
    });
  }

  @override
  void dispose() {
    _targetWeight.dispose();
    _targetBodyFat.dispose();
    _generalNotes.dispose();
    _calController.dispose();
    _minCalController.dispose();
    _maxCalController.dispose();
    _minProteinController.dispose();
    _maxProteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDisplayDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m';
  }

  String _formatMonth(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  String _formatDisplayDateFull(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  String _formatDisplayWeek(DateTime date) {
    final mon = _getMonday(date);
    final sun = mon.add(const Duration(days: 6));
    return 'Tuần từ ${_formatDisplayDate(mon)} đến ${_formatDisplayDate(sun)}';
  }

  String _formatDisplayMonthFull(DateTime date) {
    return 'Tháng ${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _getDayName(DateTime date) {
    const names = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return names[date.weekday] ?? 'Monday';
  }

  void _loadSelectedConfig() {
    if (_activeTab == 0) {
      final dateStr = _formatDate(_selectedDate);
      final index = _dailyDetails.indexWhere((e) => e.dateString == dateStr);
      if (index >= 0) {
        final d = _dailyDetails[index];
        _isDayTraining = d.isTraining;
        _calController.text = d.customCalories?.toString() ?? '';
        _minCalController.text = d.minCalories?.toString() ?? '';
        _maxCalController.text = d.maxCalories?.toString() ?? '';
        _minProteinController.text = d.minProteinG?.toString() ?? '';
        _maxProteinController.text = d.maxProteinG?.toString() ?? '';
        _notesController.text = d.customNotes ?? '';
      } else {
        _isDayTraining = false;
        _calController.clear();
        _minCalController.clear();
        _maxCalController.clear();
        _minProteinController.clear();
        _maxProteinController.clear();
        _notesController.clear();
      }
    } else if (_activeTab == 1) {
      final weekStartStr = _formatDate(_getMonday(_selectedDate));
      final index = _weeklyDetails.indexWhere(
        (e) => e.weekStartDateString == weekStartStr,
      );
      if (index >= 0) {
        final w = _weeklyDetails[index];
        _calController.text = w.customCalories?.toString() ?? '';
        _minCalController.text = w.minCalories?.toString() ?? '';
        _maxCalController.text = w.maxCalories?.toString() ?? '';
        _minProteinController.text = w.minProteinG?.toString() ?? '';
        _maxProteinController.text = w.maxProteinG?.toString() ?? '';
        _notesController.text = w.customNotes ?? '';
      } else {
        _calController.clear();
        _minCalController.clear();
        _maxCalController.clear();
        _minProteinController.clear();
        _maxProteinController.clear();
        _notesController.clear();
      }
    } else {
      final monthStr = _formatMonth(_selectedDate);
      final index = _monthlyDetails.indexWhere(
        (e) => e.monthString == monthStr,
      );
      if (index >= 0) {
        final m = _monthlyDetails[index];
        _calController.text = m.customCalories?.toString() ?? '';
        _minCalController.text = m.minCalories?.toString() ?? '';
        _maxCalController.text = m.maxCalories?.toString() ?? '';
        _minProteinController.text = m.minProteinG?.toString() ?? '';
        _maxProteinController.text = m.maxProteinG?.toString() ?? '';
        _notesController.text = m.customNotes ?? '';
      } else {
        _calController.clear();
        _minCalController.clear();
        _maxCalController.clear();
        _minProteinController.clear();
        _maxProteinController.clear();
        _notesController.clear();
      }
    }
  }

  void _saveSelectedConfig() {
    final customCal = int.tryParse(_calController.text.trim());
    final minCal = int.tryParse(_minCalController.text.trim());
    final maxCal = int.tryParse(_maxCalController.text.trim());
    final minProt = int.tryParse(_minProteinController.text.trim());
    final maxProt = int.tryParse(_maxProteinController.text.trim());
    final notes = _notesController.text.trim();

    if (_activeTab == 0) {
      final dateStr = _formatDate(_selectedDate);
      final index = _dailyDetails.indexWhere((e) => e.dateString == dateStr);
      final hasData =
          customCal != null ||
          minCal != null ||
          maxCal != null ||
          minProt != null ||
          maxProt != null ||
          notes.isNotEmpty;

      final updated = GymDayDetail(
        dayOfWeek: _getDayName(_selectedDate),
        dateString: dateStr,
        isTraining: _isDayTraining,
        customCalories: customCal,
        minCalories: minCal,
        maxCalories: maxCal,
        minProteinG: minProt,
        maxProteinG: maxProt,
        customNotes: notes.isEmpty ? null : notes,
      );

      if (index >= 0) {
        _dailyDetails[index] = updated;
      } else if (hasData) {
        _dailyDetails.add(updated);
      }
    } else if (_activeTab == 1) {
      final weekStartStr = _formatDate(_getMonday(_selectedDate));
      final index = _weeklyDetails.indexWhere(
        (e) => e.weekStartDateString == weekStartStr,
      );
      final hasData =
          customCal != null ||
          minCal != null ||
          maxCal != null ||
          minProt != null ||
          maxProt != null ||
          notes.isNotEmpty;

      final updated = GymWeeklyDetail(
        weekStartDateString: weekStartStr,
        customCalories: customCal,
        minCalories: minCal,
        maxCalories: maxCal,
        minProteinG: minProt,
        maxProteinG: maxProt,
        customNotes: notes.isEmpty ? null : notes,
      );

      if (index >= 0) {
        if (hasData) {
          _weeklyDetails[index] = updated;
        } else {
          _weeklyDetails.removeAt(index);
        }
      } else if (hasData) {
        _weeklyDetails.add(updated);
      }
    } else {
      final monthStr = _formatMonth(_selectedDate);
      final index = _monthlyDetails.indexWhere(
        (e) => e.monthString == monthStr,
      );
      final hasData =
          customCal != null ||
          minCal != null ||
          maxCal != null ||
          minProt != null ||
          maxProt != null ||
          notes.isNotEmpty;

      final updated = GymMonthlyDetail(
        monthString: monthStr,
        customCalories: customCal,
        minCalories: minCal,
        maxCalories: maxCal,
        minProteinG: minProt,
        maxProteinG: maxProt,
        customNotes: notes.isEmpty ? null : notes,
      );

      if (index >= 0) {
        if (hasData) {
          _monthlyDetails[index] = updated;
        } else {
          _monthlyDetails.removeAt(index);
        }
      } else if (hasData) {
        _monthlyDetails.add(updated);
      }
    }
  }

  void _clearSelectedConfig() {
    setState(() {
      if (_activeTab == 0) {
        final dateStr = _formatDate(_selectedDate);
        _dailyDetails.removeWhere((e) => e.dateString == dateStr);
      } else if (_activeTab == 1) {
        final weekStartStr = _formatDate(_getMonday(_selectedDate));
        _weeklyDetails.removeWhere(
          (e) => e.weekStartDateString == weekStartStr,
        );
      } else {
        final monthStr = _formatMonth(_selectedDate);
        _monthlyDetails.removeWhere((e) => e.monthString == monthStr);
      }
      _loadSelectedConfig();
    });
  }

  bool _hasCurrentOverride() {
    if (_activeTab == 0) {
      final dateStr = _formatDate(_selectedDate);
      return _dailyDetails.any((e) => e.dateString == dateStr);
    } else if (_activeTab == 1) {
      final weekStartStr = _formatDate(_getMonday(_selectedDate));
      return _weeklyDetails.any((e) => e.weekStartDateString == weekStartStr);
    } else {
      final monthStr = _formatMonth(_selectedDate);
      return _monthlyDetails.any((e) => e.monthString == monthStr);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    _saveSelectedConfig();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadSelectedConfig();
      });
    }
  }

  Future<void> _selectWeek(BuildContext context) async {
    _saveSelectedConfig();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN MỘT NGÀY TRONG TUẦN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadSelectedConfig();
      });
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    _saveSelectedConfig();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN MỘT NGÀY TRONG THÁNG',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadSelectedConfig();
      });
    }
  }

  GymGoalProfile _build() {
    return GymGoalProfile(
      goalMode: _goalMode,
      weeklyTrainingSchedule: _selectedDays.join(','),
      targetWeightKg: double.tryParse(
        _targetWeight.text.trim().replaceAll(',', '.'),
      ),
      targetBodyFatPercent: double.tryParse(
        _targetBodyFat.text.trim().replaceAll(',', '.'),
      ),
      notes: _generalNotes.text.trim().isEmpty
          ? null
          : _generalNotes.text.trim(),
      dailyDetails: _dailyDetails,
      weeklyDetails: _weeklyDetails,
      monthlyDetails: _monthlyDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cấu hình gym',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          TextButton(
            onPressed: () {
              _saveSelectedConfig();
              Navigator.pop<GymGoalProfile?>(context, _build());
            },
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chế độ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['cut', 'maintain', 'bulk', 'recomp']
                    .map(
                      (e) => ChoiceChip(
                        label: Text(_label(e)),
                        selected: _goalMode.toLowerCase() == e,
                        onSelected: (_) => setState(() => _goalMode = e),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Ngày'),
                    _buildTabButton(1, 'Tuần'),
                    _buildTabButton(2, 'Tháng'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_activeTab == 0)
                _buildSelectorTile(
                  label: 'Chọn ngày cấu hình',
                  value: _formatDisplayDateFull(_selectedDate),
                  onTap: () => _selectDate(context),
                )
              else if (_activeTab == 1)
                _buildSelectorTile(
                  label: 'Chọn tuần cấu hình',
                  value: _formatDisplayWeek(_selectedDate),
                  onTap: () => _selectWeek(context),
                )
              else
                _buildSelectorTile(
                  label: 'Chọn tháng cấu hình',
                  value: _formatDisplayMonthFull(_selectedDate),
                  onTap: () => _selectMonth(context),
                ),
              const SizedBox(height: 20),
              Text(
                _activeTab == 0
                    ? 'Cấu hình chi tiết ngày ${_formatDisplayDateFull(_selectedDate)}'
                    : _activeTab == 1
                    ? 'Cấu hình chi tiết tuần'
                    : 'Cấu hình chi tiết tháng',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              if (_activeTab == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chế độ hoạt động:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Nghỉ ngơi'),
                          selected: !_isDayTraining,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isDayTraining = false);
                            }
                          },
                          selectedColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tập luyện'),
                          selected: _isDayTraining,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isDayTraining = true);
                            }
                          },
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _buildStepperField(
                label: 'Calo mục tiêu (kcal)',
                controller: _calController,
                step: 50,
                minValue: 0,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStepperField(
                      label: 'Calo tối thiểu',
                      controller: _minCalController,
                      step: 50,
                      minValue: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStepperField(
                      label: 'Calo tối đa',
                      controller: _maxCalController,
                      step: 50,
                      minValue: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStepperField(
                      label: 'Protein tối thiểu (g)',
                      controller: _minProteinController,
                      step: 5,
                      minValue: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStepperField(
                      label: 'Protein tối đa (g)',
                      controller: _maxProteinController,
                      step: 5,
                      minValue: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú cho cấp độ này',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              if (_hasCurrentOverride()) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _clearSelectedConfig,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Xóa cấu hình ngày/tuần/tháng này',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Mục tiêu chung',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDoubleStepperField(
                      label: 'Cân nặng mục tiêu (kg)',
                      controller: _targetWeight,
                      step: 0.5,
                      minValue: 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDoubleStepperField(
                      label: '% mỡ mục tiêu',
                      controller: _targetBodyFat,
                      step: 0.5,
                      minValue: 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _generalNotes,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú chung',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeTab != index) {
            setState(() {
              _saveSelectedConfig();
              _activeTab = index;
              _loadSelectedConfig();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required TextEditingController controller,
    required int step,
    int? minValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.progressBackground.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  final val = int.tryParse(controller.text.trim()) ?? 0;
                  final newVal = val - step;
                  if (minValue == null || newVal >= minValue) {
                    controller.text = newVal.toString();
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                onPressed: () {
                  final val = int.tryParse(controller.text.trim()) ?? 0;
                  final newVal = val + step;
                  controller.text = newVal.toString();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleStepperField({
    required String label,
    required TextEditingController controller,
    required double step,
    double? minValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.progressBackground.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  final val =
                      double.tryParse(
                        controller.text.trim().replaceAll(',', '.'),
                      ) ??
                      0.0;
                  final newVal = val - step;
                  if (minValue == null || newVal >= minValue) {
                    controller.text = newVal.toStringAsFixed(1);
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                onPressed: () {
                  final val =
                      double.tryParse(
                        controller.text.trim().replaceAll(',', '.'),
                      ) ??
                      0.0;
                  final newVal = val + step;
                  controller.text = newVal.toStringAsFixed(1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _label(String mode) {
    switch (mode) {
      case 'cut':
        return 'Siết cơ';
      case 'bulk':
        return 'Xả cơ';
      case 'recomp':
        return 'Giảm mỡ tăng cơ';
      default:
        return 'Giữ cân';
    }
  }
}
