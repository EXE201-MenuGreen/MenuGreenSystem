import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../coach_pt.dart';
import 'coach_create_meal_plan_screen.dart';
import 'coach_meal_plan_detail_screen.dart';

enum _HistoryFilter { day, week, month, all }

/// Coach views the full history of a single Gymer's meal plans.
/// Filter by day / week / month / all with a modern, high-end design.
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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  void _applyFilter() {
    setState(() => _currentPage = 0);
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
    final provider = context.watch<CoachMealPlanProvider>();
    final unapprovedCount = provider.plans.where((p) {
      final s = p.status.toLowerCase();
      return s == 'active' || s == 'unapproved' || s == 'pending';
    }).length;

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
          // Header Banner Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF135A37), Color(0xFF1A7A4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A7A4A).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Quản lý & tạo lộ trình dinh dưỡng (${provider.plans.length} bản ghi)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (unapprovedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$unapprovedCount chưa duyệt',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Filter Segment Bar
          _FilterBar(
            value: _filter,
            onChanged: (v) {
              setState(() => _filter = v);
              _applyFilter();
            },
          ),

          // Main Plans List with 5 items per page pagination
          Expanded(
            child: _PlanList(
              currentPage: _currentPage,
              onPageChanged: (p) => setState(() => _currentPage = p),
              itemsPerPage: 5,
            ),
          ),
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
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          _buildFilterChip(
            context,
            filter: _HistoryFilter.all,
            label: 'Tất cả',
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            filter: _HistoryFilter.day,
            label: 'Ngày',
            icon: Icons.today_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            filter: _HistoryFilter.week,
            label: 'Tuần',
            icon: Icons.view_week_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            filter: _HistoryFilter.month,
            label: 'Tháng',
            icon: Icons.calendar_month_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required _HistoryFilter filter,
    required String label,
    required IconData icon,
  }) {
    final isSelected = value == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.currentPage,
    required this.onPageChanged,
    this.itemsPerPage = 5,
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final int itemsPerPage;

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

    final allPlans = provider.plans;
    final totalPages = (allPlans.length / itemsPerPage).ceil();
    final safePage = totalPages == 0
        ? 0
        : (currentPage >= totalPages ? totalPages - 1 : currentPage);
    final pagePlans = allPlans
        .skip(safePage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              itemCount: pagePlans.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = pagePlans[index];
                final completed = plan.completedItems ?? 0;
                final total = plan.totalItems ?? 0;
                final progress = total > 0 ? (completed / total) : 0.0;
                final titleStr = coachMealPlanDisplayTitle(
                  title: plan.title,
                  planType: plan.planType,
                  startDate: plan.startDate,
                );

                final s = plan.status.toLowerCase();
                final isUnapproved =
                    s == 'active' || s == 'unapproved' || s == 'pending';
                final isApproved = s == 'approved';

                final cardBorderColor = isUnapproved
                    ? const Color(0xFFFECACA)
                    : (isApproved
                          ? const Color(0xFFA7F3D0)
                          : Colors.grey.shade200);

                final shadowColor = isUnapproved
                    ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                    : (isApproved
                          ? const Color(0xFF047857).withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03));

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cardBorderColor,
                      width: isUnapproved ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
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
                        final submitted = await navigator.push<bool>(
                          detailRoute,
                        );
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
                            // Header Row: Icon + Title + Calorie Pill
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE8F5E9),
                                        Color(0xFFC8E6C9),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titleStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                          color: Color(0xFF111827),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              coachMealPlanTypeLabel(
                                                plan.planType,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          if (plan.startDate != null) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                _fmtPlanDate(
                                                  plan.planType,
                                                  plan.startDate,
                                                  plan.endDate,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (plan.targetCalories != null) ...[
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFFEDD5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .local_fire_department_rounded,
                                              size: 13,
                                              color: Color(0xFFEA580C),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${plan.targetCalories} kcal',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                                color: Color(0xFFEA580C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (total > 0) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          '$completed/$total món',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            // Progress Bar
                            if (total > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5.5,
                                  color: AppColors.primary,
                                  backgroundColor: const Color(0xFFECFDF5),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Bottom Row: Status Badge + Arrow Button
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
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
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
                                const Spacer(),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Pagination Bar (rendered if totalPages > 1)
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prev Page
                  IconButton(
                    onPressed: safePage > 0
                        ? () => onPageChanged(safePage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                      side: BorderSide(
                        color: safePage > 0
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Page Numbers
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalPages, (i) {
                      final isCurrent = i == safePage;
                      return GestureDetector(
                        onTap: () => onPageChanged(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCurrent ? 30 : 26,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(width: 10),
                  // Next Page
                  IconButton(
                    onPressed: safePage < totalPages - 1
                        ? () => onPageChanged(safePage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                      side: BorderSide(
                        color: safePage < totalPages - 1
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
      'active' || 'unapproved' => (
        'Chưa duyệt',
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        const Color(0xFFFECACA),
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
        coachMealPlanStatusLabel(status) == 'Chưa duyệt'
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF3F4F6),
        coachMealPlanStatusLabel(status) == 'Chưa duyệt'
            ? const Color(0xFFDC2626)
            : const Color(0xFF4B5563),
        coachMealPlanStatusLabel(status) == 'Chưa duyệt'
            ? const Color(0xFFFECACA)
            : const Color(0xFFE5E7EB),
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: textColor),
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
