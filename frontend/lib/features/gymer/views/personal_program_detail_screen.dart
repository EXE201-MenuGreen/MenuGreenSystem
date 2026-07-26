import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../../advanced/repositories/advanced_repository.dart';

/// Phase 8: Detail screen for a PersonalProgram sent by coach.
/// Shown when user taps a RouteApprovalCard in Tab 2 ("PT gửi tôi").
/// On Accept, calls /api/PtReview/personal-programs/{id}/accept.
class PersonalProgramDetailScreen extends StatefulWidget {
  const PersonalProgramDetailScreen({super.key, required this.program});
  final Map<String, dynamic> program;

  @override
  State<PersonalProgramDetailScreen> createState() =>
      _PersonalProgramDetailScreenState();
}

class _PersonalProgramDetailScreenState
    extends State<PersonalProgramDetailScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final id = widget.program['id'].toString();
      await AdvancedRepository().acceptPersonalProgram(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiMessageTranslator.translate(error.toString())),
        ),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    final status = (p['status'] ?? '').toString().toLowerCase();
    final isPending = status == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(p['title']?.toString() ?? 'Lộ trình cá nhân từ PT'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isPending)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Khi chấp nhận, mục tiêu calo/macro sẽ được cập nhật vào HealthProfile của bạn.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          if (isPending) const SizedBox(height: 16),
          _Section(
            title: 'Tổng quan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Mô tả', p['description']?.toString() ?? '(không có)'),
                _Row('Tuần bắt đầu', p['weekStartDate']?.toString() ?? ''),
                _Row(
                  'Thời lượng',
                  '${p['durationWeeks'] ?? '?'} tuần',
                ),
                _Row(
                  'Trạng thái',
                  _statusLabel(status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Mục tiêu dinh dưỡng',
            child: Column(
              children: [
                _TargetRow(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Calories/ngày',
                  value: '${p['targetCaloriesDaily'] ?? '?'} kcal',
                  color: const Color(0xFFE65100),
                ),
                _TargetRow(
                  icon: Icons.fitness_center_rounded,
                  label: 'Protein',
                  value: '${p['targetProteinG'] ?? '?'} g',
                  color: AppColors.primary,
                ),
                _TargetRow(
                  icon: Icons.bakery_dining_rounded,
                  label: 'Carbs',
                  value: '${p['targetCarbsG'] ?? '?'} g',
                  color: const Color(0xFF8D6E63),
                ),
                _TargetRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Fat',
                  value: '${p['targetFatG'] ?? '?'} g',
                  color: const Color(0xFFFFA000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if ((p['coachComment']?.toString().isNotEmpty ?? false))
            _Section(
              title: 'Ghi chú từ PT',
              child: Text(
                p['coachComment'].toString(),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textDark,
                  height: 1.5,
                ),
              ),
            ),
          if (p['acceptedAt'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bạn đã chấp nhận lộ trình này vào ${p['acceptedAt']}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isPending)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _accepting ? null : _accept,
              child: _accepting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Chấp nhận lộ trình',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) {
    return switch (s) {
      'pending' => 'Chờ bạn phản hồi',
      'accepted' => 'Đã chấp nhận',
      'rejected' => 'Đã từ chối',
      _ => s,
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(không có)' : value,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}