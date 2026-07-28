import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../coach_pt.dart';
import 'coach_create_meal_plan_screen.dart';
import 'coach_meal_plan_detail_screen.dart';

enum _HistoryFilter { day, week, month, all }

/// Coach views the full history of a single Gymer's meal plans.
///
/// Pushed when the Coach picks a Gymer from
/// [CoachMealPlanSelectClientScreen]. Filter by day / week / month / all.
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
    // Filter theo planType trên DB (DAILY/WEEKLY/MONTHLY), không theo overlap range.
    // Lý do: user than "tab Ngày" hiện vẫn thấy plan DAILY 26/07 dù bấm Tuần/Tháng/Tất cả.
    // Filter theo range overlap với StartDate=26/07 sẽ match mọi bucket vì 26/07
    // luôn nằm trong [today..today+1year]. Filter theo planType mới đúng ngữ nghĩa
    // "Ngày = chỉ plan DAILY, Tuần = chỉ plan WEEKLY, ...".
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
      appBar: AppBar(title: Text('Lộ trình - ${widget.clientName}')),
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
        icon: const Icon(Icons.add),
        label: const Text('Tạo lộ trình'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SegmentedButton<_HistoryFilter>(
        segments: const [
          ButtonSegment(
            value: _HistoryFilter.day,
            label: Text('Ngày'),
            icon: Icon(Icons.today),
          ),
          ButtonSegment(
            value: _HistoryFilter.week,
            label: Text('Tuần'),
            icon: Icon(Icons.view_week),
          ),
          ButtonSegment(
            value: _HistoryFilter.month,
            label: Text('Tháng'),
            icon: Icon(Icons.calendar_month),
          ),
          ButtonSegment(
            value: _HistoryFilter.all,
            label: Text('Tất cả'),
            icon: Icon(Icons.all_inclusive),
          ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.plans.isEmpty) {
      return _ErrorState(message: provider.error!, onRetry: provider.refresh);
    }
    if (provider.plans.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        itemCount: provider.plans.length,
        itemBuilder: (context, index) {
          final plan = provider.plans[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(
                plan.title.isNotEmpty ? plan.title : 'Lộ trình',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.startDate != null
                        ? '${plan.planType.toUpperCase()}  ·  ${_fmtPlanDate(plan.planType, plan.startDate, plan.endDate)}'
                        : plan.planType.toUpperCase(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _PlanStatusChip(status: plan.status),
                  ),
                  if (plan.coachName != null && plan.coachName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bởi PT: ${plan.coachName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  if (plan.totalItems != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(
                        value: plan.totalItems == 0
                            ? 0
                            : (plan.completedItems ?? 0) / plan.totalItems!,
                        minHeight: 6,
                      ),
                    ),
                ],
              ),
              trailing: plan.targetCalories != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${plan.targetCalories} kcal',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (plan.totalItems != null)
                          Text(
                            '${plan.completedItems ?? 0}/${plan.totalItems} món',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    )
                  : null,
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
                // Navigator.push completes as soon as pop is requested, while
                // the reverse transition may still keep the route's Overlay
                // and provider dependents mounted. Wait for full teardown
                // before refreshing state or showing a SnackBar.
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
            ),
          );
        },
      ),
    );
  }

  static String _dmy(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  /// Format ngày hiển thị tuỳ theo loại plan (thêm năm cho rõ ràng):
  /// - Daily   → chỉ 1 ngày  ("26/07/2026")
  /// - Weekly  → range 7 ngày ("26/07/2026 – 01/08/2026")
  /// - Monthly → range tháng   ("26/07/2026 – 25/08/2026")
  /// - Custom / khác → range `start – end`
  static String _fmtPlanDate(String planType, DateTime? start, DateTime? end) {
    if (start == null) return '';
    final type = planType.toLowerCase();
    if (type == 'daily') {
      // daily: start == end theo design (chỉ 1 ngày). Hiển thị 1 lần.
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
    final normalized = status.toLowerCase();
    final approved = normalized == 'approved';
    final label = coachMealPlanStatusLabel(status);
    final color = approved ? Colors.green : Colors.orange;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 120),
      children: const [
        Center(
          child: Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
        ),
        SizedBox(height: 16),
        Text(
          'Học viên chưa có lộ trình nào trong khoảng đã chọn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
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
              ElevatedButton.icon(
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
