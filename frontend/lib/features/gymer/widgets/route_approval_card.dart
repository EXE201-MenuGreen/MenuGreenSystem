import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Phase 8: Reusable card widget for the 2-tab Gymer journey screen.
/// Shows a PtReviewRequest with status, targets, week, and action button.
///
/// Tabs:
/// - Tab 1 ("Tôi gửi PT"): user creates report, status Pending -> Reviewed -> Applied/Rejected
///   Action: "Apply" (Tab 1) when status == Reviewed.
/// - Tab 2 ("PT gửi tôi"): coach sends PersonalProgram, status Pending -> Accepted/Rejected
///   Action: "Chấp nhận" (Tab 2) when status == Pending.
class RouteApprovalCard extends StatelessWidget {
  const RouteApprovalCard({
    super.key,
    required this.request,
    required this.direction,
    this.onAction,
    this.onTap,
  });

  /// Raw response map from /api/PtReview/my-requests or /api/PtReview/my-personal-programs.
  final Map<String, dynamic> request;

  /// 'sent' = Gymer -> PT (Tab 1), 'received' = Coach -> Gymer (Tab 2).
  final String direction;

  /// Triggered when user taps the primary action button.
  final VoidCallback? onAction;

  /// Triggered when user taps the card body (for opening detail screen).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = (request['status'] ?? '').toString();
    final title = direction == 'received'
        ? (request['title']?.toString() ?? 'Lộ trình cá nhân từ PT')
        : (request['requestType']?.toString() == 'RouteApproval'
              ? 'Yêu cầu duyệt lộ trình'
              : 'Báo cáo tuần');
    final description = (request['description'] ??
            request['ptComment'] ??
            request['coachComment'] ??
            '')
        .toString();
    final weekStart = request['weekStartDate']?.toString() ?? '';
    final calories = request['suggestedCalorieTarget'];
    final protein = request['suggestedProteinTarget'];
    final createdAt = request['createdAt']?.toString();
    final durationWeeks = request['durationWeeks'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    direction == 'received'
                        ? Icons.assignment_ind_rounded
                        : Icons.send_rounded,
                    size: 18,
                    color: direction == 'received'
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  _StatusChip(status: status, direction: direction),
                ],
              ),
              const SizedBox(height: 8),
              if (weekStart.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tuần $weekStart',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (durationWeeks != null && durationWeeks > 0) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$durationWeeks tuần',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (calories != null || protein != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (calories != null)
                      _TargetChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '${calories} kcal',
                        color: const Color(0xFFE65100),
                      ),
                    if (calories != null && protein != null)
                      const SizedBox(width: 8),
                    if (protein != null)
                      _TargetChip(
                        icon: Icons.fitness_center_rounded,
                        label: '${protein}g protein',
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ],
              if (_primaryActionLabel(status, direction) != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: direction == 'received'
                          ? AppColors.primary
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: onAction,
                    child: Text(_primaryActionLabel(status, direction)!),
                  ),
                ),
              ],
              if (createdAt != null && createdAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tạo lúc ${_formatDate(createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String? _primaryActionLabel(String status, String direction) {
    final s = status.toLowerCase();
    if (direction == 'received') {
      // Coach -> Gymer (PersonalProgram)
      if (s == 'pending') return 'Chấp nhận lộ trình';
      return null;
    } else {
      // Gymer -> PT (WeeklyReport / RouteApproval)
      if (s == 'reviewed') return 'Áp dụng gợi ý';
      return null;
    }
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final pad = (int n) => n.toString().padLeft(2, '0');
      return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.direction});
  final String status;
  final String direction;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final (label, color) = switch (s) {
      'pending' => ('Chờ phản hồi', const Color(0xFFFFA000)),
      'reviewed' => ('Đã duyệt', AppColors.primary),
      'accepted' => ('Đã chấp nhận', const Color(0xFF2E7D32)),
      'applied' => ('Đã áp dụng', const Color(0xFF2E7D32)),
      'rejected' => ('Đã từ chối', const Color(0xFFD32F2F)),
      _ => (status, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}