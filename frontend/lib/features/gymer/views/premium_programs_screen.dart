import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../subscription/models/sepay_models.dart';
import '../../subscription/models/subscription_models.dart';
import '../repositories/premium_program_repository.dart';

class PremiumProgramsScreen extends StatefulWidget {
  const PremiumProgramsScreen({super.key});

  @override
  State<PremiumProgramsScreen> createState() => _PremiumProgramsScreenState();
}

class _PremiumProgramsScreenState extends State<PremiumProgramsScreen> {
  final _repository = PremiumProgramRepository();

  List<Map<String, dynamic>> _programs = const [];
  List<Map<String, dynamic>> _enrollments = const [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  Map<String, dynamic>? get _activeProgram => _firstWithStatus('active');
  Map<String, dynamic>? get _paidProgram => _firstWithStatus('paid');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getPrograms(),
        _repository.getMyPrograms(),
      ]);
      if (!mounted) return;
      setState(() {
        _programs = results[0];
        _enrollments = results[1];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _cleanError(error);
      });
    }
  }

  Map<String, dynamic>? _firstWithStatus(String status) {
    for (final item in _enrollments) {
      if (_value(item, 'status').toLowerCase() == status) return item;
    }
    return null;
  }

  Future<void> _checkout(Map<String, dynamic> program) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng ký lộ trình'),
        content: Text(
          '${_value(program, 'title')}\n\n'
          'Phí chương trình: ${formatVnd(_intValue(program, 'priceVnd'))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo mã thanh toán'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      final order = await _repository.checkout(_value(program, 'id'));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => _ProgramPaymentSheet(
          programTitle: _value(program, 'title'),
          order: order,
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _activate(Map<String, dynamic> enrollment) async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Chọn ngày bắt đầu lộ trình',
    );
    if (date == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await _repository.activate(_value(enrollment, 'id'), date);
      if (mounted) _showMessage('Đã kích hoạt lộ trình tuần đầu tiên.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openCheckIn(Map<String, dynamic> active) async {
    final weight = TextEditingController();
    final bodyFat = TextEditingController();
    final week = _intValue(active, 'currentWeek', fallback: 1);
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Check-in tuần $week',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cập nhật chỉ số để mở khóa tuần tiếp theo.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cân nặng (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyFat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Tỷ lệ mỡ (%) — không bắt buộc',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Hoàn tất check-in'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) {
      weight.dispose();
      bodyFat.dispose();
      return;
    }

    final weightValue = double.tryParse(
      weight.text.trim().replaceAll(',', '.'),
    );
    final fatValue = double.tryParse(bodyFat.text.trim().replaceAll(',', '.'));
    weight.dispose();
    bodyFat.dispose();
    if (weightValue == null) {
      _showMessage('Vui lòng nhập cân nặng hợp lệ.', error: true);
      return;
    }

    setState(() => _actionLoading = true);
    try {
      await _repository.checkIn(
        weekNumber: week,
        weightKg: weightValue,
        bodyFatPercent: fatValue,
      );
      if (mounted) _showMessage('Đã lưu check-in tuần $week.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lộ trình Gymer',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading || _actionLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _buildIntro(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _MessageCard(message: _error!),
                  ],
                  if (_paidProgram != null) ...[
                    const SizedBox(height: 14),
                    _buildPaidProgram(_paidProgram!),
                  ],
                  if (_activeProgram != null) ...[
                    const SizedBox(height: 14),
                    _buildActiveProgram(_activeProgram!),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Chương trình phù hợp',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_programs.isEmpty)
                    const _MessageCard(
                      message: 'Chưa có chương trình nào đang mở đăng ký.',
                    )
                  else
                    for (final program in _programs)
                      _ProgramCard(
                        program: program,
                        busy: _actionLoading,
                        onCheckout: () => _checkout(program),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 30),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến bộ theo từng tuần',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nhận kế hoạch dinh dưỡng, check-in chỉ số và mở khóa cột mốc trong 8–12 tuần.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidProgram(Map<String, dynamic> program) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SẴN SÀNG KÍCH HOẠT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _value(program, 'programTitle'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _actionLoading ? null : () => _activate(program),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Chọn ngày bắt đầu'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProgram(Map<String, dynamic> active) {
    final milestones = _listValue(active, 'milestones');
    final currentWeek = _intValue(active, 'currentWeek', fallback: 1);
    final completed = milestones
        .where((item) => _boolValue(item, 'isCheckedIn'))
        .length;
    final currentMilestone = milestones.where(
      (item) => _intValue(item, 'weekNumber') == currentWeek,
    );
    final canCheckIn =
        currentMilestone.isEmpty ||
        !_boolValue(currentMilestone.first, 'isCheckedIn');

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỘ TRÌNH ĐANG THAM GIA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _value(active, 'programTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActiveMetric(
                  label: 'Tuần hiện tại',
                  value: '$currentWeek',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActiveMetric(
                  label: 'Đã check-in',
                  value: '$completed/${milestones.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _actionLoading || !canCheckIn
                  ? null
                  : () => _openCheckIn(active),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white70,
              ),
              icon: Icon(
                canCheckIn ? Icons.edit_calendar_outlined : Icons.check_circle,
                size: 19,
              ),
              label: Text(
                canCheckIn
                    ? 'Check-in tuần $currentWeek'
                    : 'Tuần này đã hoàn tất',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : AppColors.primary,
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.busy,
    required this.onCheckout,
  });

  final Map<String, dynamic> program;
  final bool busy;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final weeks = _intValue(program, 'durationWeeks');
    final calories = _intValue(program, 'targetCaloriesDaily');
    final price = _intValue(program, 'priceVnd');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _value(program, 'title'),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _value(program, 'description'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.42,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.calendar_month_outlined,
                text: '$weeks tuần',
              ),
              _InfoChip(
                icon: Icons.local_fire_department_outlined,
                text: '$calories kcal/ngày',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatVnd(price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              FilledButton(
                onPressed: busy ? null : onCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Đăng ký'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramPaymentSheet extends StatelessWidget {
  const _ProgramPaymentSheet({required this.programTitle, required this.order});

  final String programTitle;
  final SepayOrder order;

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thanh toán lộ trình',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              programTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (order.qrImageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  order.qrImageUrl,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 120,
                    child: Center(child: Text('Không tải được ảnh QR.')),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                children: [
                  _PaymentRow(
                    label: 'Số tiền',
                    value: formatVnd(order.amountVnd),
                  ),
                  const SizedBox(height: 9),
                  _PaymentRow(
                    label: 'Nội dung CK',
                    value: order.copyTransferText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copy(context, order.copyTransferText),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Sao chép nội dung chuyển khoản'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sau khi ngân hàng xác nhận, kéo xuống để làm mới và kích hoạt ngày bắt đầu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveMetric extends StatelessWidget {
  const _ActiveMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

String _value(Map<String, dynamic> data, String key, [String fallback = '']) {
  final pascal = key[0].toUpperCase() + key.substring(1);
  return (data[key] ?? data[pascal] ?? fallback).toString();
}

int _intValue(Map<String, dynamic> data, String key, {int fallback = 0}) {
  final raw = data[key] ?? data[key[0].toUpperCase() + key.substring(1)];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? fallback;
}

bool _boolValue(Map<String, dynamic> data, String key) {
  final raw = data[key] ?? data[key[0].toUpperCase() + key.substring(1)];
  if (raw is bool) return raw;
  return raw?.toString().toLowerCase() == 'true';
}

List<Map<String, dynamic>> _listValue(Map<String, dynamic> data, String key) {
  final raw = data[key] ?? data[key[0].toUpperCase() + key.substring(1)];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
