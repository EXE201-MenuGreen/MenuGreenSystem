import 'package:flutter/material.dart';

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
      color: Color(0xFF1B4332),
      bgColor: Color(0xFFE8F5E9),
    ),
    _ActionItem(
      icon: Icons.no_food_outlined,
      label: 'Ăn\nngoài?',
      color: Color(0xFFEAB308),
      bgColor: Color(0xFFFEF9C3),
    ),
    _ActionItem(
      icon: Icons.calendar_today,
      label: 'Kế hoạch\năn',
      color: Color(0xFF2D5A45),
      bgColor: Color(0xFFE3F2FD),
    ),
    _ActionItem(
      icon: Icons.insights,
      label: 'Kế hoạch\nvs Thực tế',
      color: Color(0xFF7C3AED),
      bgColor: Color(0xFFEDE9FE),
    ),
    _ActionItem(
      icon: Icons.fitness_center,
      label: 'Chế độ\nGym/PT',
      color: Color(0xFFDC2626),
      bgColor: Color(0xFFFEE2E2),
    ),
    _ActionItem(
      icon: Icons.storefront,
      label: 'Sở thích\nViệt Nam',
      color: Color(0xFFEA580C),
      bgColor: Color(0xFFFFEDD5),
    ),
    _ActionItem(
      icon: Icons.search,
      label: 'Tìm\nmón ăn',
      color: Color(0xFF2563EB),
      bgColor: Color(0xFFDBEAFE),
    ),
    _ActionItem(
      icon: Icons.favorite,
      label: 'Yêu\nthích',
      color: Color(0xFFDB2777),
      bgColor: Color(0xFFFCE7F3),
    ),
    _ActionItem(
      icon: Icons.calculate_outlined,
      label: 'Tính\ncalo',
      color: Color(0xFF0891B2),
      bgColor: Color(0xFFCFFAFE),
    ),
    _ActionItem(
      icon: Icons.monitor_weight_outlined,
      label: 'Cân\nnặng',
      color: Color(0xFF059669),
      bgColor: Color(0xFFD1FAE5),
    ),
    _ActionItem(
      icon: Icons.security,
      label: 'An toàn &\nTuân thủ',
      color: Color(0xFF9333EA),
      bgColor: Color(0xFFF3E8FF),
    ),
    _ActionItem(
      icon: Icons.swap_horiz,
      label: 'Thay thế\nnguyên liệu',
      color: Color(0xFF65A30D),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Tính năng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
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
      ],
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
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.2,
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
  final Color color;
  final Color bgColor;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });
}
