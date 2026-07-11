import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/views/favorites_screen.dart';
import '../../discover/views/discover_view.dart';
import '../../meal_plan/views/meal_plan_screen.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import 'weight_log_sheet.dart';
import '../../vietnam_local/views/daily_starter_screen.dart';
import '../../vietnam_local/views/food_capture_screen.dart';
import '../../vietnam_local/views/gym_goals_screen.dart';
import '../../vietnam_local/views/local_preferences_screen.dart';
import '../../vietnam_local/views/planned_vs_actual_screen.dart';
import '../../vietnam_local/views/safety_hub_screen.dart';
import '../../vietnam_local/views/ingredient_substitution_screen.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  static const _actions = <_ActionItem>[
    _ActionItem(
      icon: Icons.bolt,
      label: 'Hôm nay\năn gì?',
      gradientColors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      bgColor: Color(0xFFE8F5E9),
    ),
    _ActionItem(
      icon: Icons.no_food_outlined,
      label: 'Ăn\nngoài?',
      gradientColors: [Color(0xFFEAB308), Color(0xFFFCD34D)],
      bgColor: Color(0xFFFEF9C3),
    ),
    _ActionItem(
      icon: Icons.calendar_today,
      label: 'Kế hoạch\năn',
      gradientColors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
      bgColor: Color(0xFFE3F2FD),
    ),
    _ActionItem(
      icon: Icons.insights,
      label: 'Kế hoạch\nvs Thực tế',
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      bgColor: Color(0xFFEDE9FE),
    ),
    _ActionItem(
      icon: Icons.fitness_center,
      label: 'Chế độ\nGym/PT',
      gradientColors: [Color(0xFFDC2626), Color(0xFFF87171)],
      bgColor: Color(0xFFFEE2E2),
    ),
    _ActionItem(
      icon: Icons.storefront,
      label: 'Sở thích\nViệt Nam',
      gradientColors: [Color(0xFFEA580C), Color(0xFFFB923C)],
      bgColor: Color(0xFFFFEDD5),
    ),
    _ActionItem(
      icon: Icons.search,
      label: 'Tìm\nmón ăn',
      gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      bgColor: Color(0xFFDBEAFE),
    ),
    _ActionItem(
      icon: Icons.favorite,
      label: 'Yêu\nthích',
      gradientColors: [Color(0xFFDB2777), Color(0xFFF472B6)],
      bgColor: Color(0xFFFCE7F3),
    ),
    _ActionItem(
      icon: Icons.calculate_outlined,
      label: 'Tính\ncalo',
      gradientColors: [Color(0xFF0891B2), Color(0xFF22D3EE)],
      bgColor: Color(0xFFCFFAFE),
    ),
    _ActionItem(
      icon: Icons.monitor_weight_outlined,
      label: 'Cân\nnặng',
      gradientColors: [Color(0xFF059669), Color(0xFF34D399)],
      bgColor: Color(0xFFD1FAE5),
    ),
    _ActionItem(
      icon: Icons.security,
      label: 'An toàn &\nTuân thủ',
      gradientColors: [Color(0xFF9333EA), Color(0xFFC084FC)],
      bgColor: Color(0xFFF3E8FF),
    ),
    _ActionItem(
      icon: Icons.swap_horiz,
      label: 'Thay thế\nnguyên liệu',
      gradientColors: [Color(0xFF65A30D), Color(0xFFA3E635)],
      bgColor: Color(0xFFECFCCB),
    ),
  ];

  void _navigateTo(BuildContext context, int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const DailyStarterScreen();
        break;
      case 1:
        screen = const FoodCaptureScreen();
        break;
      case 2:
        screen = const MealPlanScreen();
        break;
      case 3:
        screen = const PlannedVsActualScreen();
        break;
      case 4:
        screen = const GymGoalsScreen();
        break;
      case 5:
        screen = const LocalPreferencesScreen();
        break;
      case 6:
        screen = const DiscoverView();
        break;
      case 7:
        screen = const FavoritesScreen();
        break;
      case 8:
        screen = const IngredientScanScreen();
        break;
      case 9:
        _openWeightLog(context);
        return;
      case 10:
        screen = const SafetyHubScreen();
        break;
      case 11:
        screen = const IngredientSubstitutionScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openWeightLog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WeightLogSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with gradient background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tính năng',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _actions.length,
              itemBuilder: (context, index) {
                final action = _actions[index];
                return _QuickActionItem(
                  action: action,
                  onTap: () => _navigateTo(context, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final _ActionItem action;
  final VoidCallback onTap;

  const _QuickActionItem({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              color: action.gradientColors.first,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color bgColor;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.bgColor,
  });
}
