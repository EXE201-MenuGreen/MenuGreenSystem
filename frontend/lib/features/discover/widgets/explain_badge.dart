import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ExplainBadge extends StatelessWidget {
  const ExplainBadge({
    super.key,
    required this.reason,
    this.onTap,
    this.isCompact = false,
  });

  final String reason;
  final VoidCallback? onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '💡 $reason',
          style: TextStyle(
            fontSize: isCompact ? 11 : 12,
            color: AppColors.primary,
            fontWeight: isCompact ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: isCompact ? 12 : 14,
            color: AppColors.primary,
          ),
        ],
      ],
    );

    if (onTap == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: content,
      ),
    );
  }
}
