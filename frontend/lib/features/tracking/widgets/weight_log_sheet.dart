import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

/// Thêm hoặc sửa log cân nặng.
Future<bool> showWeightLogSheet(
  BuildContext context, {
  WeightLogItem? existing,
  DateTime? recordedAt,
}) async {
  final repository = NutritionTrackingRepository();
  final isEdit = existing != null;
  final weightController = TextEditingController(
    text: existing != null ? existing.weightKg.toStringAsFixed(1) : '',
  );
  final fatController = TextEditingController(
    text: existing?.bodyFatPercent?.toStringAsFixed(1) ?? '',
  );

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isEdit ? 'Sửa cân nặng' : 'Thêm cân nặng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cân nặng (kg)',
              hintText: 'Ví dụ: 65.5',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: fatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Mỡ cơ thể (%) - tùy chọn',
              hintText: 'Ví dụ: 18',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(isEdit ? 'Lưu' : 'Thêm'),
        ),
      ],
    ),
  );

  if (result != true) return false;

  final weight = double.tryParse(weightController.text.trim());
  final fatText = fatController.text.trim();
  final fat = fatText.isEmpty ? null : double.tryParse(fatText);
  if (weight == null || weight <= 0 || (fatText.isNotEmpty && fat == null)) {
    return false;
  }

  final at = recordedAt ?? existing?.recordedAt ?? DateTime.now();

  if (isEdit) {
    return repository.updateWeightLog(
      existing.id,
      weightKg: weight,
      bodyFatPercent: fat,
      recordedAt: at,
    );
  }

  return repository.createWeightLog(
    weightKg: weight,
    bodyFatPercent: fat,
    recordedAt: at,
  );
}

class WeightLogsList extends StatelessWidget {
  const WeightLogsList({
    super.key,
    required this.logs,
    required this.onEdit,
    required this.onDelete,
  });

  final List<WeightLogItem> logs;
  final ValueChanged<WeightLogItem> onEdit;
  final ValueChanged<WeightLogItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Chưa có dữ liệu cân nặng trong khoảng thời gian này.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final sorted = List<WeightLogItem>.from(logs)
      ..sort((a, b) {
        final aTime = a.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cân nặng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        ...sorted.map(
          (log) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.progressBackground),
                ),
                leading: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
                title: Text(
                  '${log.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _formatRecorded(log),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') onEdit(log);
                    if (value == 'delete') onDelete(log);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatRecorded(WeightLogItem log) {
    final at = log.recordedAt;
    if (at == null) return log.bodyFatPercent != null ? 'Mỡ: ${log.bodyFatPercent!.toStringAsFixed(1)}%' : '';
    final date = '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}';
    final time = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final fat = log.bodyFatPercent != null ? ' • Mỡ ${log.bodyFatPercent!.toStringAsFixed(1)}%' : '';
    return '$date $time$fat';
  }
}
