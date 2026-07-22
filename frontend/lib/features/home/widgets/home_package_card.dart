import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class HomePackageAction {
  const HomePackageAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Shared visual language for activated package cards on the home screen.
class HomePackageCard extends StatelessWidget {
  const HomePackageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.headerIcon,
    required this.accentColor,
    required this.actions,
    required this.onTap,
    this.statusIcon,
    this.statusIconColor = Colors.white,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final IconData headerIcon;
  final Color accentColor;
  final List<HomePackageAction> actions;
  final VoidCallback onTap;
  final IconData? statusIcon;
  final Color statusIconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(headerIcon, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.55,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (statusIcon != null) ...[
                        Icon(statusIcon, size: 11, color: statusIconColor),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        statusLabel,
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final action in actions)
                Expanded(
                  child: _PackageAction(
                    icon: action.icon,
                    label: action.label,
                    color: accentColor,
                    onTap: action.onTap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackageAction extends StatelessWidget {
  const _PackageAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 39,
              child: Icon(icon, size: 27, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 9.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
