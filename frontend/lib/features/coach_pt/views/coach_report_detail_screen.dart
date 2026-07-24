import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../coach_pt.dart';

/// Coach reads and reviews a single weekly report.
///
/// * Top half: data the Gymer sent (weight, body feeling, training days,
///   nutrition summary stats extracted from the ReportData blob).
/// * Bottom half: form for the Coach's feedback and optional inline
///   meal-plan adjustments. Submitting triggers:
///   - Review is saved on the report;
///   - Backend applies the inline adjustments to the Gymer's meal plan;
///   - Backend notifies the Gymer.
class CoachReportDetailScreen extends StatefulWidget {
  const CoachReportDetailScreen({super.key, required this.reportId});
  final String reportId;

  @override
  State<CoachReportDetailScreen> createState() =>
      _CoachReportDetailScreenState();
}

class _CoachReportDetailScreenState extends State<CoachReportDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _calorieCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final List<MealPlanAdjustment> _adjustments = [];
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _calorieCtrl.dispose();
    _proteinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nhận xét.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final submission = CoachReviewSubmission(
      comment: _commentCtrl.text.trim(),
      suggestedCalorieTarget: int.tryParse(_calorieCtrl.text.trim()),
      suggestedProteinTarget: int.tryParse(_proteinCtrl.text.trim()),
      adjustments: List.unmodifiable(_adjustments),
    );
    final ok = await context
        .read<CoachReportProvider>()
        .submitReview(widget.reportId, submission);
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Đã gửi đánh giá. Học viên sẽ nhận thông báo.'
            : 'Gửi thất bại. Vui lòng thử lại.'),
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _addAdjustmentDialog() async {
    String mealType = 'breakfast';
    String action = 'add';
    final dateCtrl = TextEditingController(text: _today());
    final calCtrl = TextEditingController();
    final result = await showDialog<_AdjustmentDialogResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          title: const Text('Thêm điều chỉnh lộ trình'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: action,
                  decoration: const InputDecoration(
                    labelText: 'Hành động',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'add', child: Text('Thêm')),
                    DropdownMenuItem(value: 'replace', child: Text('Thay')),
                    DropdownMenuItem(value: 'remove', child: Text('Xóa')),
                  ],
                  onChanged: (v) =>
                      setSheet(() => action = v ?? 'add'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: mealType,
                  decoration: const InputDecoration(
                    labelText: 'Bữa',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'breakfast', child: Text('Sáng')),
                    DropdownMenuItem(value: 'lunch', child: Text('Trưa')),
                    DropdownMenuItem(value: 'dinner', child: Text('Tối')),
                    DropdownMenuItem(value: 'snack', child: Text('Phụ')),
                  ],
                  onChanged: (v) =>
                      setSheet(() => mealType = v ?? 'breakfast'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ngày (yyyy-MM-dd)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: calCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Calo mục tiêu (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                _AdjustmentDialogResult(
                  action: action,
                  mealType: mealType,
                  date: dateCtrl.text.trim(),
                  calories: int.tryParse(calCtrl.text.trim()),
                ),
              ),
              child: const Text('Thêm vào danh sách'),
            ),
          ],
        ),
      ),
    );
    dateCtrl.dispose();
    calCtrl.dispose();
    if (result == null) return;
    final date = DateTime.tryParse(result.date);
    if (date == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày không hợp lệ.')),
      );
      return;
    }
    setState(() {
      _adjustments.add(MealPlanAdjustment(
        action: result.action,
        mealType: result.mealType,
        plannedDate: date,
        targetCalories: result.calories,
      ));
    });
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachReportProvider>();
    if (provider.isLoadingDetail || provider.selectedDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.detailError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(provider.detailError!),
          ),
        ),
      );
    }

    final detail = provider.selectedDetail!;
    final summary = detail.summary;
    final data = detail.reportData ?? const {};
    final nutrition = (data['nutritionSummary'] ??
            data['NutritionSummary'] ??
            const {})
        as Map<String, dynamic>;
    final adherence =
        (data['adherenceScore'] ?? data['AdherenceScore'] ?? const {})
            as Map<String, dynamic>;
    final weightLogs = (data['weightLogs'] ?? data['WeightLogs'] ?? const [])
        as List;

    return Scaffold(
      appBar: AppBar(
        title: Text('Báo cáo - ${summary.studentName}'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.send),
            label: const Text('Gửi đánh giá'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(summary: summary, nutrition: nutrition),
          const SizedBox(height: 16),
          _AdherenceCard(adherence: adherence),
          const SizedBox(height: 16),
          _WeightLogsCard(logs: weightLogs.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList()),
          const SizedBox(height: 16),
          _ReviewForm(
            commentCtrl: _commentCtrl,
            calorieCtrl: _calorieCtrl,
            proteinCtrl: _proteinCtrl,
          ),
          const SizedBox(height: 16),
          _AdjustmentsCard(
            adjustments: _adjustments,
            onAdd: _addAdjustmentDialog,
            onRemove: (a) => setState(() => _adjustments.remove(a)),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.summary, required this.nutrition});
  final CoachWeeklyReport summary;
  final Map<String, dynamic> nutrition;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final calories = _firstNumber(nutrition, const [
      'caloriesActual',
      'CaloriesActual',
      'actualCalories',
    ]);
    final protein = _firstNumber(nutrition, const [
      'proteinActualG',
      'ProteinActualG',
      'actualProtein',
    ]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.studentName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Tuần: ${_fmt(summary.weekStartDate)} → '
              '${_fmt(summary.weekStartDate.add(const Duration(days: 6)))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (summary.checkInWeight != null)
                  Expanded(
                    child: _Stat(
                      label: 'Cân nặng',
                      value:
                          '${summary.checkInWeight!.toStringAsFixed(1)} kg',
                    ),
                  ),
                if (summary.trainingDaysCount != null)
                  Expanded(
                    child: _Stat(
                      label: 'Buổi tập',
                      value: '${summary.trainingDaysCount}',
                    ),
                  ),
                if (calories != null)
                  Expanded(
                    child: _Stat(label: 'Calo TB', value: calories.toStringAsFixed(0)),
                  ),
                if (protein != null)
                  Expanded(
                    child: _Stat(label: 'Đạm TB', value: protein.toStringAsFixed(0)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  num? _firstNumber(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
    }
    return null;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.adherence});
  final Map<String, dynamic> adherence;
  @override
  Widget build(BuildContext context) {
    final score = _firstNumber(adherence, const ['score', 'Score']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Độ tuân thủ',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (score != null) ...[
              LinearProgressIndicator(
                value: (score.clamp(0, 100)) / 100,
                minHeight: 8,
              ),
              const SizedBox(height: 4),
              Text('${score.toStringAsFixed(0)} / 100'),
            ] else
              const Text('Không có dữ liệu tuân thủ.'),
          ],
        ),
      ),
    );
  }

  num? _firstNumber(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
    }
    return null;
  }
}

class _WeightLogsCard extends StatelessWidget {
  const _WeightLogsCard({required this.logs});
  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cân nặng trong tuần',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...logs.map((l) {
              final kg = (l['weightKg'] ?? l['WeightKg'] ?? 0).toString();
              final recorded = (l['recordedAt'] ?? l['RecordedAt'] ?? '')
                  .toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.scale),
                title: Text('$kg kg'),
                subtitle: Text(recorded),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.commentCtrl,
    required this.calorieCtrl,
    required this.proteinCtrl,
  });
  final TextEditingController commentCtrl;
  final TextEditingController calorieCtrl;
  final TextEditingController proteinCtrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đánh giá của PT',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nhận xét cho học viên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: calorieCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Calo đề xuất',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: proteinCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Đạm đề xuất (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentsCard extends StatelessWidget {
  const _AdjustmentsCard({
    required this.adjustments,
    required this.onAdd,
    required this.onRemove,
  });
  final List<MealPlanAdjustment> adjustments;
  final VoidCallback onAdd;
  final void Function(MealPlanAdjustment) onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Điều chỉnh lộ trình',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Thêm điều chỉnh',
                ),
              ],
            ),
            if (adjustments.isEmpty)
              const Text('Không có điều chỉnh nào.',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: adjustments
                    .asMap()
                    .entries
                    .map((entry) {
                      final a = entry.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.swap_horiz),
                        title: Text(
                            '${a.action.toUpperCase()} ${a.mealType}'),
                        subtitle: Text(
                          '${a.plannedDate.day}/${a.plannedDate.month}/${a.plannedDate.year}'
                          '${a.targetCalories != null ? " - ${a.targetCalories} kcal" : ""}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => onRemove(a),
                        ),
                      );
                    })
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentDialogResult {
  _AdjustmentDialogResult({
    required this.action,
    required this.mealType,
    required this.date,
    this.calories,
  });
  final String action;
  final String mealType;
  final String date;
  final int? calories;
}
