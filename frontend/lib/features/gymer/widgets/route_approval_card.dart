import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator_fixed.dart';
import '../utils/personal_program_period.dart';
import '../utils/route_approval_period.dart';

/// Reusable card widget for the 2-tab Gymer journey screen ("Lộ trình Gymer").
///
/// Tabs:
/// - Tab 1 ("Tôi gửi PT"): user creates report, status Pending -> Reviewed -> Applied/Rejected
///   Action: "Áp dụng gợi ý" (Tab 1) when status == Reviewed.
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
    String value(String key) => PersonalProgramPeriod.value(request, key);

    final status = (request['status'] ?? '').toString();
    final requestType = value('requestType');
    final isRouteApproval = requestType.trim().toLowerCase() == 'routeapproval';
    final title = direction == 'received'
        ? (request['title']?.toString() ?? 'Lộ trình cá nhân từ PT')
        : (isRouteApproval ? 'Yêu cầu duyệt lộ trình' : 'Báo cáo tuần');
    final coachComment = (request['coachComment'] ??
            request['CoachComment'] ??
            request['ptComment'] ??
            request['PtComment'] ??
            '')
        .toString()
        .trim();
    final rawDesc = (request['description'] ?? request['Description'] ?? '')
        .toString()
        .trim();

    String description = coachComment.isNotEmpty ? coachComment : rawDesc;
    final dateRangePattern = RegExp(
      r'từ\s+(\d{2}/\d{2}/\d{4})\s+đến\s+(\d{2}/\d{2}/\d{4})',
      caseSensitive: false,
    );
    description = description.replaceAllMapped(dateRangePattern, (match) {
      final d1 = match.group(1);
      final d2 = match.group(2);
      if (d1 == d2) {
        return 'ngày $d1';
      }
      return match.group(0)!;
    });

    final weekStart = value('weekStartDate');
    final calories = request['targetCaloriesDaily'] ??
        request['TargetCaloriesDaily'] ??
        request['targetCalories'] ??
        (isRouteApproval
            ? request['configuredCalorieTarget']
            : request['suggestedCalorieTarget']);
    final createdAt = (request['createdAt'] ?? request['CreatedAt'])?.toString();
    final sentScope = RouteApprovalPeriod.normalizeScope(
      requestType: requestType,
      configurationScope: value('configurationScope'),
    );
    final sentStart = DateTime.tryParse(
      value('configurationStartDate').isNotEmpty
          ? value('configurationStartDate')
          : weekStart,
    );
    final sentEnd = DateTime.tryParse(value('configurationEndDate'));
    final periodLabel = direction == 'received'
        ? PersonalProgramPeriod.periodLabel(request)
        : sentStart == null
        ? ''
        : RouteApprovalPeriod.periodLabel(
            scope: sentScope,
            start: sentStart,
            end: sentEnd,
          );
    final durationLabel = direction == 'received'
        ? PersonalProgramPeriod.durationLabel(request)
        : '';

    final isReceived = direction == 'received';
    final actionLabel = _primaryActionLabel(
      status,
      direction,
      isRouteApproval: isRouteApproval,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A7A4A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Icon Badge + Title + Status Chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF135A37), Color(0xFF1A7A4A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1A7A4A,
                            ).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isReceived
                            ? Icons.assignment_ind_rounded
                            : Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF111827),
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(status: status, direction: direction),
                  ],
                ),

                // Period & Duration row
                if (periodLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13.5,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          periodLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (durationLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 12.5,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                durationLabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Description box if available
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],

                // Target Calorie Chip
                if (calories != null) ...[
                  const SizedBox(height: 12),
                  _TargetChip(
                    icon: Icons.local_fire_department_rounded,
                    label: '$calories kcal',
                    bgColor: AppColors.primary.withValues(alpha: 0.08),
                    textColor: AppColors.primary,
                    borderColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ],

                // Action button if actionable
                if (actionLabel != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onAction,
                      icon: Icon(
                        isReceived
                            ? Icons.check_circle_outline_rounded
                            : Icons.auto_awesome_rounded,
                        size: 18,
                      ),
                      label: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],

                // Creation timestamp
                if (createdAt != null && createdAt.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tạo lúc ${_formatDate(createdAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _primaryActionLabel(
    String status,
    String direction, {
    required bool isRouteApproval,
  }) {
    final s = status.toLowerCase();
    if (direction == 'received') {
      // Coach -> Gymer (PersonalProgram)
      if (s == 'pending') return 'Chấp nhận lộ trình';
      return null;
    } else {
      // Gymer -> PT (WeeklyReport / RouteApproval)
      if (s == 'reviewed' && !isRouteApproval) return 'Áp dụng gợi ý';
      return null;
    }
  }

  static String _formatDate(String iso) {
    try {
      final trimmed = iso.trim();
      if (trimmed.isEmpty) return iso;

      DateTime? d;
      if (trimmed.endsWith('Z') ||
          RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed)) {
        d = DateTime.tryParse(trimmed)?.toLocal();
      } else {
        d = DateTime.tryParse('${trimmed}Z')?.toLocal();
      }

      d ??= DateTime.tryParse(trimmed)?.toLocal();
      if (d == null) return iso;

      String pad(int n) => n.toString().padLeft(2, '0');
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
    final (label, bgColor, textColor, borderColor) = switch (s) {
      'pending' => (
        'Chờ phản hồi',
        const Color(0xFFFFFBEB),
        const Color(0xFFD97706),
        const Color(0xFFFDE68A),
      ),
      'reviewed' => (
        direction == 'sent' ? 'Duyệt thành công' : 'Đã duyệt',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'accepted' => (
        'Đã chấp nhận',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'applied' => (
        'Đã áp dụng',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'rejected' => (
        'Đã từ chối',
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        const Color(0xFFFECACA),
      ),
      _ => (
        status.translatedData,
        const Color(0xFFF3F4F6),
        AppColors.textSecondary,
        const Color(0xFFE5E7EB),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: textColor),
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
