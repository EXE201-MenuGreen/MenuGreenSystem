import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../coach_pt.dart';
import 'coach_create_meal_plan_screen.dart';
import 'coach_meal_plan_detail_screen.dart';

enum _HistoryFilter { day, week, month, all }

/// Coach views the full history of a single Gymer's meal plans.
///
/// Filter by day / week / month / all.
class CoachMealPlanHistoryScreen extends StatefulWidget {
  const CoachMealPlanHistoryScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;

  @override
  State<CoachMealPlanHistoryScreen> createState() =>
      _CoachMealPlanHistoryScreenState();
}

class _CoachMealPlanHistoryScreenState
    extends State<CoachMealPlanHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  void _applyFilter() {
    final provider = context.read<CoachMealPlanProvider>();
    String? planType;
    switch (_filter) {
      case _HistoryFilter.day:
        planType = 'daily';
        break;
      case _HistoryFilter.week:
        planType = 'weekly';
        break;
      case _HistoryFilter.month:
        planType = 'monthly';
        break;
      case _HistoryFilter.all:
        planType = null;
        break;
    }
    provider.setFilters(planType: planType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          'Lộ trình - ${widget.clientName}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            value: _filter,
            onChanged: (v) {
              setState(() => _filter = v);
              _applyFilter();
            },
          ),
          const Expanded(child: _PlanList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'createMealPlanBtn',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Tạo lộ trình',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        onPressed: _pushCreate,
      ),
    );
  }

  Future<void> _pushCreate() async {
    final provider = context.read<CoachMealPlanProvider>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: CoachCreateMealPlanScreen(
            clientId: widget.clientId,
            clientName: widget.clientName,
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});
  final _HistoryFilter value;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SegmentedButton<_HistoryFilter>(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return const Color(0xFF6B7280);
            }),
            elevation: WidgetStateProperty.resolveWith<double>((states) {
              if (states.contains(WidgetState.selected)) {
                return 1;
              }
              return 0;
            }),
            side: WidgetStateProperty.all(BorderSide.none),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          segments: const [
            ButtonSegment(
              value: _HistoryFilter.day,
              label: Text(
                'Ngày',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              icon: Icon(Icons.today_rounded, size: 16),
            ),
            ButtonSegment(
              value: _HistoryFilter.week,
              label: Text(
                'Tuần',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              icon: Icon(Icons.view_week_rounded, size: 16),
            ),
            ButtonSegment(
              value: _HistoryFilter.month,
              label: Text(
                'Tháng',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              icon: Icon(Icons.calendar_month_rounded, size: 16),
            ),
            ButtonSegment(
              value: _HistoryFilter.all,
              label: Text(
                'Tất cả',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              icon: Icon(Icons.check_circle_outline_rounded, size: 16),
            ),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachMealPlanProvider>();
    if (provider.isLoading && provider.plans.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.error != null && provider.plans.isEmpty) {
      return _ErrorState(message: provider.error!, onRetry: provider.refresh);
    }
    if (provider.plans.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: provider.plans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final plan = provider.plans[index];
          final completed = plan.completedItems ?? 0;
          final total = plan.totalItems ?? 0;
          final progress = total > 0 ? (completed / total) : 0.0;
          final titleStr = plan.title.isNotEmpty ? plan.title : 'Lộ trình ăn uống';

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final provider = context.read<CoachMealPlanProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  await provider.loadPlanDetail(plan.id);
                  if (!messenger.mounted) return;
                  final detailRoute = MaterialPageRoute<bool>(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: CoachMealPlanDetailScreen(planId: plan.id),
                    ),
                  );
                  final submitted = await navigator.push<bool>(detailRoute);
                  await detailRoute.completed;
                  if (!messenger.mounted || submitted != true) return;
                  await provider.refresh();
                  if (!messenger.mounted) return;
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã gửi lộ trình. Gymer sẽ nhận thông báo để xem và chấp nhận.',
                        ),
                      ),
                    );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Icon + Title + Status Chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  plan.startDate != null
                                      ? '${plan.planType.toUpperCase()} · ${_fmtPlanDate(plan.planType, plan.startDate, plan.endDate)}'
                                      : plan.planType.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (plan.targetCalories != null) ...[
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${plan.targetCalories} kcal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                if (total > 0)
                                  Text(
                                    '$completed/$total món',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Status row + PT creator if available
                      Row(
                        children: [
                          _PlanStatusChip(status: plan.status),
                          if (plan.coachName != null &&
                              plan.coachName!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PT ${plan.coachName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Progress bar if items exist
                      if (total > 0) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: AppColors.primary,
                            backgroundColor: const Color(0xFFECFDF5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _dmy(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  static String _fmtPlanDate(String planType, DateTime? start, DateTime? end) {
    if (start == null) return '';
    final type = planType.toLowerCase();
    if (type == 'daily') {
      return _dmy(start);
    }
    if (end == null) return _dmy(start);
    return '${_dmy(start)} – ${_dmy(end)}';
  }
}

class _PlanStatusChip extends StatelessWidget {
  const _PlanStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final (label, bgColor, textColor, borderColor) = switch (s) {
      'approved' => (
        'Đã duyệt & gửi',
        const Color(0xFFECFDF5),
        const Color(0xFF047857),
        const Color(0xFFA7F3D0),
      ),
      'pending' || 'pendingacceptance' => (
        'Chờ Gymer chấp nhận',
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
        const Color(0xFFFDE68A),
      ),
      'rejected' => (
        'Đã từ chối',
        const Color(0xFFFEF2F2),
        const Color(0xFFB91C1C),
        const Color(0xFFFECACA),
      ),
      _ => (
        coachMealPlanStatusLabel(status),
        const Color(0xFFF3F4F6),
        const Color(0xFF4B5563),
        const Color(0xFFE5E7EB),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Chưa có lộ trình nào',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bấm nút "Tạo lộ trình" bên dưới để thiết lập kế hoạch ăn uống cho học viên.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
