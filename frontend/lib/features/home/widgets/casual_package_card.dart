import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../casual/views/casual_hub_screen.dart';

class CasualPackageCard extends StatelessWidget {
  const CasualPackageCard({super.key});

  static const _accent = Color(0xFFFFB020);

  void _open(BuildContext context, [CasualFeature? feature]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CasualHubScreen(openFeature: feature)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const actions = <({IconData icon, String label, CasualFeature feature})>[
      (
        icon: Icons.casino_rounded,
        label: 'Vòng quay',
        feature: CasualFeature.luckyWheel,
      ),
      (
        icon: Icons.bolt_rounded,
        label: '1 chạm',
        feature: CasualFeature.dailyStarter,
      ),
      (
        icon: Icons.auto_stories_rounded,
        label: 'Kiến thức',
        feature: CasualFeature.microLearning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5DE), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0CC7F)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'CASUAL PLUS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF9A6200),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'ĐÃ KÍCH HOẠT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Bộ công cụ ăn uống đơn giản đã sẵn sàng',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9A6200),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(
                  child: _CasualAction(
                    icon: actions[i].icon,
                    label: actions[i].label,
                    onTap: () => _open(context, actions[i].feature),
                  ),
                ),
                if (i < actions.length - 1) const SizedBox(width: 9),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CasualAction extends StatelessWidget {
  const _CasualAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: [
              const SizedBox(height: 1),
              Icon(icon, color: CasualPackageCard._accent, size: 21),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
