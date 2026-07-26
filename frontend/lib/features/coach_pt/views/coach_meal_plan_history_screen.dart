import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../coach_pt.dart';
import '../providers/coach_meal_plan_provider.dart';
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
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  void _applyFilter() {
    final provider = context.read<CoachMealPlanProvider>();
    DateTime? from;
    DateTime? to;
    // Filter theo khoảng ngày (time range), KHÔNG theo planType.
    // Lý do: lộ trình "cho ngày hôm nay" có thể được tạo với
    // planType là daily / weekly / custom tuỳ chọn người dùng.
    // UI tab đang hiển thị lộ trình theo NGÀY / TUẦN / THÁNG
    // (calendar bucket), không phải theo loại planType.
    switch (_filter) {
      case _HistoryFilter.day:
        final today = DateTime.now();
        from = DateTime(today.year, today.month, today.day);
        // Bao trùm cả ngày hôm nay (đến 23:59:59.999).
        to = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
        break;
      case _HistoryFilter.week:
        final now = DateTime.now();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(monday.year, monday.month, monday.day);
        // Bao trùm cả tuần từ thứ 2 đến chủ nhật (đến 23:59:59.999).
        to = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
        break;
      case _HistoryFilter.month:
        final now = DateTime.now();
        from = DateTime(now.year, now.month, 1);
        // DateTime(year, month+1, 0) → ngày cuối tháng hiện tại.
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
        to = DateTime(now.year, now.month, lastDayOfMonth, 23, 59, 59, 999);
        break;
      case _HistoryFilter.all:
        from = null;
        to = null;
        break;
    }
    if (_range != null) {
      from = _range!.start;
      to = DateTime(
        _range!.end.year,
        _range!.end.month,
        _range!.end.day,
        23,
        59,
        59,
        999,
      );
    }
    provider.setFilters(from: from, to: to);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lộ trình - ${widget.clientName}'),
        actions: [
          IconButton(
            tooltip: 'Chọn khoảng ngày',
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            value: _filter,
            onChanged: (v) {
              setState(() {
                _filter = v;
                _range = null;
              });
              _applyFilter();
            },
          ),
          if (_range != null) _RangeHint(range: _range!),
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

class _RangeHint extends StatelessWidget {
  const _RangeHint({required this.range});
  final DateTimeRange range;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${_fmt(range.start)} → ${_fmt(range.end)}',
          style: Theme.of(context).textTheme.bodySmall,
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
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.plans.isEmpty) {
      return _ErrorState(
        message: provider.error!,
        onRetry: provider.refresh,
      );
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
                  Text('${plan.planType.toUpperCase()}'
                      '${plan.startDate != null
                          ? "  ·  ${_fmtRange(plan.startDate, plan.endDate)}"
                          : ''}'),
                  if (plan.coachName != null && plan.coachName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('Bởi PT: ${plan.coachName}',
                              style: Theme.of(context).textTheme.bodySmall),
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
                        Text('${plan.targetCalories} kcal',
                            style: Theme.of(context).textTheme.titleSmall),
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
                await provider.loadPlanDetail(plan.id);
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: CoachMealPlanDetailScreen(planId: plan.id),
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

  static String _fmtRange(DateTime? start, DateTime? end) {
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
    if (start == null && end == null) return '';
    if (start != null && end != null) return '${d(start)} – ${d(end)}';
    return d(start ?? end!);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 120),
      children: const [
        Center(child: Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey)),
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
