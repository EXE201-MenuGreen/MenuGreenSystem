import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Reusable card with title, leading icon and an optional trailing widget.
///
/// Used to summarize KPIs across the Vietnam Local screens (calorie budget,
/// adherence score, BMI risk etc).
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.value,
    this.footnote,
    this.color,
    this.onTap,
    this.trailing,
    this.child,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final String? value;
  final String? footnote;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.progressBackground, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: themeColor, size: 18),
                    ),
                  if (icon != null) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (value != null) ...[
                const SizedBox(height: 10),
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 22,
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (footnote != null) ...[
                const SizedBox(height: 4),
                Text(
                  footnote!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (child != null) ...[const SizedBox(height: 12), child!],
            ],
          ),
        ),
      ),
    );
  }
}
