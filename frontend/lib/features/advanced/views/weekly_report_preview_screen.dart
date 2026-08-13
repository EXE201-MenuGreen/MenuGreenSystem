import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../history/views/history_view.dart';
import '../../vietnam_local/models/vietnam_local_models.dart';
import '../../vietnam_local/repositories/vietnam_local_repositories.dart';

class WeeklyReportPreviewScreen extends StatefulWidget {
  const WeeklyReportPreviewScreen({
    super.key,
    required this.weekStart,
    this.repository,
    this.dataThrough,
    this.midWeek = false,
  });

  final DateTime weekStart;
  final PlannedVsActualRepository? repository;
  final DateTime? dataThrough;
  final bool midWeek;

  @override
  State<WeeklyReportPreviewScreen> createState() =>
      _WeeklyReportPreviewScreenState();
}

class _WeeklyReportPreviewScreenState extends State<WeeklyReportPreviewScreen> {
  late final PlannedVsActualRepository _repository;
  PlannedVsActualSummary? _summary;
  AdherenceScore? _adherence;
  bool _loading = true;
  String? _error;

  DateTime get _weekStart => DateUtils.dateOnly(widget.weekStart);
  DateTime get _weekEnd => widget.dataThrough == null
      ? _weekStart.add(const Duration(days: 6))
      : DateUtils.dateOnly(widget.dataThrough!);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PlannedVsActualRepository();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final results = await Future.wait<Object>([
      _repository.getSummary(from: _weekStart, to: _weekEnd),
      _repository.getAdherenceScore(from: _weekStart, to: _weekEnd),
    ]);
    if (!mounted) return;

    final summaryResult = results[0] as ApiResult<PlannedVsActualSummary>;
    final adherenceResult = results[1] as ApiResult<AdherenceScore>;
    if (!summaryResult.success || summaryResult.data == null) {
      setState(() {
        _loading = false;
        _error = summaryResult.translatedMessage;
      });
      return;
    }

    setState(() {
      _summary = summaryResult.data;
      _adherence = adherenceResult.data;
      _loading = false;
      _error = adherenceResult.success
          ? null
          : adherenceResult.translatedMessage;
    });
  }

  List<PlannedVsActualDay> get _days {
    final details = _summary?.details ?? const <PlannedVsActualDay>[];
    final dayCount = _weekEnd.difference(_weekStart).inDays + 1;
    return List.generate(dayCount, (index) {
      final date = _weekStart.add(Duration(days: index));
      for (final day in details) {
        if (DateUtils.isSameDay(day.date, date)) return day;
      }
      return PlannedVsActualDay(
        date: date,
        planned: const PlannedNutrition(),
        actual: const PlannedNutrition(),
      );
    });
  }

  int get _daysNeedingReview {
    final today = DateUtils.dateOnly(DateTime.now());
    return _days.where((day) {
      if (DateUtils.dateOnly(day.date).isAfter(today)) return false;
      return !_hasActualData(day.actual);
    }).length;
  }

  Future<void> _openDay(PlannedVsActualDay day) async {
    final openHistory = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _WeeklyDayDetailSheet(day: day),
    );
    if (openHistory != true || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => HistoryView(initialDate: day.date)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: Text(
          widget.midWeek
              ? 'Chuẩn bị báo cáo giữa tuần'
              : 'Chuẩn bị báo cáo tuần',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _summary == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Tiếp tục tạo báo cáo'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Không tải được dữ liệu báo cáo tuần.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildIntro(),
          const SizedBox(height: 14),
          _buildSummaryCard(),
          if (_daysNeedingReview > 0) ...[
            const SizedBox(height: 14),
            _buildMissingDataNotice(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              'Điểm bám sát chưa tải được: $_error',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Dữ liệu từng ngày',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chạm vào một ngày để xem calories và macro chi tiết.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final day in _days)
            _WeeklyDayCard(day: day, onTap: () => _openDay(day)),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFE8D7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.calendar_view_week, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_shortDate(_weekStart)} – ${_shortDate(_weekEnd)}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kiểm tra dữ liệu hệ thống đã tổng hợp trước khi gửi cho PT.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

  Widget _buildSummaryCard() {
    final summary = _summary!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan tuần',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryProgress(
            label: 'Calories',
            actual: summary.totalActual.caloriesKcal,
            planned: summary.totalPlanned.caloriesKcal,
            unit: 'kcal',
          ),
          const SizedBox(height: 14),
          _SummaryProgress(
            label: 'Protein',
            actual: summary.totalActual.proteinG,
            planned: summary.totalPlanned.proteinG,
            unit: 'g',
          ),
          if (_adherence != null) ...[
            const Divider(height: 28),
            Row(
              children: [
                const Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Điểm bám sát kế hoạch',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_adherence!.overallScore.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingDataNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Có $_daysNeedingReview ngày chưa có dữ liệu thực tế. '
              'Bạn vẫn có thể gửi báo cáo, nhưng nên kiểm tra và bổ sung trước.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryProgress extends StatelessWidget {
  const _SummaryProgress({
    required this.label,
    required this.actual,
    required this.planned,
    required this.unit,
  });

  final String label;
  final double actual;
  final double planned;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ratio = planned <= 0 ? 0.0 : actual / planned;
    final progress = ratio.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${actual.toStringAsFixed(0)} / ${planned.toStringAsFixed(0)} $unit',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            color: ratio > 1.1 ? Colors.orange : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _WeeklyDayCard extends StatelessWidget {
  const _WeeklyDayCard({required this.day, required this.onTap});

  final PlannedVsActualDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _dayStatus(day);
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: status.color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(status.icon, color: status.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weekdayName(day.date.weekday)}, ${_shortDate(day.date)}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${day.actual.caloriesKcal.toStringAsFixed(0)} / '
                    '${day.planned.caloriesKcal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'kcal thực tế / kế hoạch',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyDayDetailSheet extends StatelessWidget {
  const _WeeklyDayDetailSheet({required this.day});

  final PlannedVsActualDay day;

  @override
  Widget build(BuildContext context) {
    final status = _dayStatus(day);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_weekdayName(day.date.weekday)}, ${_shortDate(day.date)}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NutritionBlock(
                    title: 'Kế hoạch',
                    nutrition: day.planned,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NutritionBlock(
                    title: 'Thực tế',
                    nutrition: day.actual,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Mở nhật ký ngày này'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionBlock extends StatelessWidget {
  const _NutritionBlock({
    required this.title,
    required this.nutrition,
    required this.color,
  });

  final String title;
  final PlannedNutrition nutrition;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${nutrition.caloriesKcal.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'P ${nutrition.proteinG.toStringAsFixed(0)}g  •  '
            'C ${nutrition.carbsG.toStringAsFixed(0)}g\n'
            'F ${nutrition.fatG.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayStatus {
  const _DayStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

_DayStatus _dayStatus(PlannedVsActualDay day) {
  final today = DateUtils.dateOnly(DateTime.now());
  if (DateUtils.dateOnly(day.date).isAfter(today)) {
    return const _DayStatus(
      'Chưa đến ngày',
      AppColors.textSecondary,
      Icons.schedule,
    );
  }

  final hasPlanned = _hasNutritionData(day.planned);
  final hasActual = _hasActualData(day.actual);
  if (!hasPlanned && !hasActual) {
    return const _DayStatus(
      'Chưa có kế hoạch hoặc nhật ký',
      Color(0xFFD97706),
      Icons.warning_amber_rounded,
    );
  }
  if (!hasActual) {
    return const _DayStatus(
      'Chưa ghi nhận dữ liệu thực tế',
      Color(0xFFD97706),
      Icons.warning_amber_rounded,
    );
  }
  if (!hasPlanned) {
    return const _DayStatus(
      'Có nhật ký ngoài kế hoạch',
      Color(0xFF2563EB),
      Icons.info_outline,
    );
  }

  final deviation =
      (day.actual.caloriesKcal - day.planned.caloriesKcal) /
      day.planned.caloriesKcal;
  if (deviation.abs() <= 0.1) {
    return const _DayStatus(
      'Bám sát kế hoạch',
      AppColors.primary,
      Icons.check_circle_outline,
    );
  }
  final percent = (deviation.abs() * 100).round();
  if (deviation > 0) {
    return _DayStatus(
      'Vượt $percent% calories',
      const Color(0xFFDC2626),
      Icons.trending_up,
    );
  }
  return _DayStatus(
    'Thiếu $percent% calories',
    const Color(0xFF0284C7),
    Icons.trending_down,
  );
}

bool _hasActualData(PlannedNutrition value) => _hasNutritionData(value);

bool _hasNutritionData(PlannedNutrition value) =>
    value.caloriesKcal > 0 ||
    value.proteinG > 0 ||
    value.carbsG > 0 ||
    value.fatG > 0;

String _weekdayName(int weekday) => switch (weekday) {
  DateTime.monday => 'Thứ Hai',
  DateTime.tuesday => 'Thứ Ba',
  DateTime.wednesday => 'Thứ Tư',
  DateTime.thursday => 'Thứ Năm',
  DateTime.friday => 'Thứ Sáu',
  DateTime.saturday => 'Thứ Bảy',
  DateTime.sunday => 'Chủ Nhật',
  _ => '',
};

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
