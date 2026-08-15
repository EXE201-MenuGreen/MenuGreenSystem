import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator_fixed.dart';
import '../../tracking/models/latest_weight_log.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';

class WeightLogSheet extends StatefulWidget {
  const WeightLogSheet({super.key, this.initialWeightLog});

  /// Optional pre-fetched latest weight log. When supplied the sheet
  /// skips the network fetch on open and uses these values as the
  /// starting form state. The parent usually passes `null` and lets the
  /// sheet fetch on its own; pre-fetching is useful for callers that
  /// already have the data and want a fully synchronous open.
  final LatestWeightLog? initialWeightLog;

  @override
  State<WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<WeightLogSheet> {
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  final _repo = NutritionTrackingRepository();
  bool _loading = false;
  bool _prefilled = false;
  LatestWeightLog? _latestLog;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialWeightLog;
    if (initial != null) {
      _prefill(initial);
    } else {
      _fetchLatestInBackground();
    }
  }

  /// Apply [log] values to the controllers. Called once when the
  /// latest log is known so the user never sees a blank form when they
  /// already have a recent weight entry.
  void _prefill(LatestWeightLog log) {
    if (_prefilled) return;
    _prefilled = true;
    _latestLog = log;
    final formattedWeight = _formatForInput(log.weightKg);
    if (formattedWeight != null) {
      _weightController.text = formattedWeight;
    }
    if (log.bodyFatPercent != null) {
      final formattedFat = _formatForInput(log.bodyFatPercent!);
      if (formattedFat != null) {
        _fatController.text = formattedFat;
      }
    }
    if (mounted) setState(() {});
  }

  /// Strip trailing ".0" so the input looks like "75" instead of "75.0"
  /// while still accepting decimal input.
  String? _formatForInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  Future<void> _fetchLatestInBackground() async {
    final latest = await _repo.getLatestWeightLog();
    if (latest == null || !mounted) return;
    _prefill(latest);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final bodyFat = double.tryParse(_fatController.text.trim());
      final latest = _latestLog;
      final latestDate = latest?.recordedAt?.toLocal();
      final isLatestFromToday =
          latest != null &&
          latest.id.isNotEmpty &&
          latestDate != null &&
          DateUtils.isSameDay(latestDate, DateTime.now());
      final saved = isLatestFromToday
          ? await _repo.updateWeightLog(
              latest.id,
              weightKg: weight,
              bodyFatPercent: bodyFat,
              recordedAt: DateTime.now(),
            )
          : await _repo.createWeightLog(
              weightKg: weight,
              bodyFatPercent: bodyFat,
            );
      if (!saved) throw StateError('Weight log request failed');
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiMessageTranslator.translate(
              'Weight log saved successfully.',
              errorCode: 'WEIGHT_LOG_SAVED',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không lưu được. Thử lại.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _prefilled ? 'Cập nhật cân nặng' : 'Ghi cân nặng',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _prefilled
                ? 'Đã điền số đo gần nhất. Chỉ lưu khi bạn có số đo mới.'
                : 'Ghi số đo hiện tại để theo dõi thay đổi theo thời gian. Tỷ lệ mỡ là tùy chọn.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cân nặng (kg)',
              hintText: _prefilled ? 'Đã điền sẵn từ lần log gần nhất' : null,
              filled: true,
              fillColor: AppColors.progressBackground.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tỷ lệ mỡ (%) - tùy chọn',
              filled: true,
              fillColor: AppColors.progressBackground.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Lưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
