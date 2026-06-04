import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AllergyRiskBadge extends StatelessWidget {
  const AllergyRiskBadge({super.key, required this.riskLevel});

  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _style(riskLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  (String, Color) _style(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return ('Không phù hợp', Colors.red.shade700);
      case 'caution':
        return ('Cần lưu ý', Colors.orange.shade800);
      default:
        return ('An toàn', AppColors.primary);
    }
  }
}
