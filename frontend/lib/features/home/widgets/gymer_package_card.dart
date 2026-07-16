import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../gymer/views/gymer_hub_screen.dart';

class GymerPackageCard extends StatelessWidget {
  const GymerPackageCard({super.key});

  static const _gold = Color(0xFFB8872D);
  static const _goldDark = Color(0xFF795918);
  static const _goldBorder = Color(0xFFE8D29A);

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7DB), Color(0xFFFFFCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _goldBorder),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'GYMER VIP',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: _goldDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _goldDark,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '0Đ',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _goldDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              for (final action in actions)
                Expanded(
                  child: _VipAction(
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

class _VipAction extends StatelessWidget {
  const _VipAction({
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
            SizedBox(
              width: 48,
              height: 43,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: GymerPackageCard._goldBorder),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: GymerPackageCard._goldDark,
                    ),
                  ),
                  Positioned(
                    top: -3,
                    right: 0,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: GymerPackageCard._gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
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
