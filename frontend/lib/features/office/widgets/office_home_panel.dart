import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../adaptive_reminders/views/adaptive_reminders_screen.dart';
import '../../meal_templates/views/meal_templates_screen.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import '../views/office_meal_plan_screen.dart';

class OfficeHomePanel extends StatelessWidget {
  const OfficeHomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, Widget screen})>[
      (
        icon: Icons.document_scanner_outlined,
        label: 'Quét nguyên liệu',
        screen: const IngredientScanScreen(officeMode: true),
      ),
      (
        icon: Icons.notifications_active_outlined,
        label: 'Nhắc nhở',
        screen: const AdaptiveRemindersScreen(),
      ),
      (
        icon: Icons.lunch_dining_outlined,
        label: 'Cơm hộp',
        screen: const OfficeMealPlanScreen(),
      ),
      (
        icon: Icons.bookmark_outline,
        label: 'Mẫu bữa ăn',
        screen: const MealTemplatesScreen(),
      ),
    ];

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1FAF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB8DCCB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Không gian Office',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tổ chức bữa trưa và thói quen khỏe mạnh trong ngày làm việc.',
              style: GoogleFonts.beVietnamPro(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 76,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / 4;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return SizedBox(
                        width: itemWidth,
                        child: _OfficeAction(
                          icon: action.icon,
                          label: action.label,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => action.screen),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
  }
}

class _OfficeAction extends StatelessWidget {
  const _OfficeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 27),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
