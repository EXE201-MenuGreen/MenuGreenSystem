import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../gymer/views/gymer_hub_screen.dart';

class GymerPackageCard extends StatelessWidget {
  const GymerPackageCard({super.key});

  static const _premiumGold = Color(0xFFD4A62A);
  static const _targetColor = Color(0xFF1B4332);
  static const _reviewColor = Color(0xFF0077B6);
  static const _coachColor = Color(0xFF0F766E);
  static const _programColor = Color(0xFF059669);

  void _open(BuildContext context, [GymerFeature? feature]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymerHubScreen(openFeature: feature)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const actions =
        <({IconData icon, String label, Color color, GymerFeature feature})>[
          (
            icon: Icons.track_changes_rounded,
            label: 'Mục tiêu',
            color: _targetColor,
            feature: GymerFeature.goals,
          ),
          (
            icon: Icons.rate_review_outlined,
            label: 'PT Review',
            color: _reviewColor,
            feature: GymerFeature.ptReview,
          ),
          (
            icon: Icons.sports_gymnastics_rounded,
            label: 'Coach',
            color: _coachColor,
            feature: GymerFeature.coaches,
          ),
          (
            icon: Icons.emoji_events_outlined,
            label: 'Lộ trình',
            color: _programColor,
            feature: GymerFeature.programs,
          ),
        ];

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
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
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      Positioned(
                        right: 2,
                        top: 1,
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 11,
                          color: _premiumGold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GYMER VIP',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.55,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Bộ công cụ tập luyện đã kích hoạt',
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
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 12,
                        color: _premiumGold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'TRẢ PHÍ',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.25,
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
                  child: _VipAction(
                    icon: action.icon,
                    label: action.label,
                    color: action.color,
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

class _VipAction extends StatelessWidget {
  const _VipAction({
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
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 29, color: color),
                  Positioned(
                    top: -1,
                    right: 2,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 10,
                        color: GymerPackageCard._premiumGold,
                      ),
                    ),
                  ),
                ],
              ),
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
