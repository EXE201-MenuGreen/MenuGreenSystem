import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../gymer/views/gymer_hub_screen.dart';

class GymerPackageCard extends StatelessWidget {
  const GymerPackageCard({super.key});

  void _open(BuildContext context, [GymerFeature? feature]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymerHubScreen(openFeature: feature)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const actions = <({IconData icon, String label, GymerFeature feature})>[
      (
        icon: Icons.track_changes_rounded,
        label: 'Mục tiêu',
        feature: GymerFeature.goals,
      ),
      (
        icon: Icons.rate_review_outlined,
        label: 'PT Review',
        feature: GymerFeature.ptReview,
      ),
      (
        icon: Icons.sports_gymnastics_rounded,
        label: 'Coach',
        feature: GymerFeature.coaches,
      ),
      (
        icon: Icons.emoji_events_outlined,
        label: 'Lộ trình',
        feature: GymerFeature.programs,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gói Gymer',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Mục tiêu thể hình và PT trong một nơi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '0Đ',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final action in actions)
                Expanded(
                  child: _PackageAction(
                    icon: action.icon,
                    label: action.label,
                    onTap: () => _open(context, action.feature),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
