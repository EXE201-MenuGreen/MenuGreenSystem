import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/views/favorites_screen.dart';
import '../../discover/views/discover_view.dart';
import '../../gymer/views/gymer_hub_screen.dart';
import '../../meal_plan/views/meal_plan_screen.dart';
import '../../meal_templates/views/meal_templates_screen.dart';
import '../../micro_learning/views/micro_learning_screen.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import 'weight_log_sheet.dart';
import '../../vietnam_local/views/daily_starter_screen.dart';
import '../../vietnam_local/views/food_capture_screen.dart';
import '../../vietnam_local/views/local_preferences_screen.dart';
import '../../vietnam_local/views/planned_vs_actual_screen.dart';
import '../../vietnam_local/views/safety_hub_screen.dart';
import '../../vietnam_local/views/ingredient_substitution_screen.dart';
import '../../adaptive_reminders/views/adaptive_reminders_screen.dart';

enum QuickActionType {
  todayEat,
  eatOut,
  mealPlan,
  planVsActual,
  gymMode,
  vietPreferences,
  searchFood,
  favorites,
  calcCalo,
  weightLog,
  safetyHub,
  ingredientSubstitution,
  savedTemplates,
  nutritionLearning,
  officeReminders,
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  static const _actions = <_ActionItem>[
    _ActionItem(
      type: QuickActionType.todayEat,
      icon: Icons.bolt,
      label: 'Hôm nay\năn gì?',
      gradientColors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      bgColor: Color(0xFFE8F5E9),
    ),
    _ActionItem(
      type: QuickActionType.mealPlan,
      icon: Icons.calendar_today,
      label: 'Kế hoạch\năn',
      gradientColors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
      bgColor: Color(0xFFE3F2FD),
    ),
    _ActionItem(
      type: QuickActionType.calcCalo,
      icon: Icons.calculate_outlined,
      label: 'Tính\ncalo',
      gradientColors: [Color(0xFF0891B2), Color(0xFF22D3EE)],
      bgColor: Color(0xFFCFFAFE),
    ),
    _ActionItem(
      type: QuickActionType.weightLog,
      icon: Icons.monitor_weight_outlined,
      label: 'Cân\nnặng',
      gradientColors: [Color(0xFF059669), Color(0xFF34D399)],
      bgColor: Color(0xFFD1FAE5),
    ),
    _ActionItem(
      type: QuickActionType.searchFood,
      icon: Icons.search,
      label: 'Tìm\nmón ăn',
      gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      bgColor: Color(0xFFDBEAFE),
    ),
    _ActionItem(
      type: QuickActionType.ingredientSubstitution,
      icon: Icons.swap_horiz,
      label: 'Thay thế\nnguyên liệu',
      gradientColors: [Color(0xFF65A30D), Color(0xFFA3E635)],
      bgColor: Color(0xFFECFCCB),
    ),
    _ActionItem(
      type: QuickActionType.planVsActual,
      icon: Icons.insights,
      label: 'Kế hoạch\nvs Thực tế',
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      bgColor: Color(0xFFEDE9FE),
    ),
    _ActionItem(
      type: QuickActionType.savedTemplates,
      icon: Icons.bookmark_outline,
      label: 'Thực đơn\nđã lưu',
      gradientColors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
      bgColor: Color(0xFFCCFBF1),
    ),
    _ActionItem(
      type: QuickActionType.eatOut,
      icon: Icons.no_food_outlined,
      label: 'Ăn\nngoài?',
      gradientColors: [Color(0xFFEAB308), Color(0xFFFCD34D)],
      bgColor: Color(0xFFFEF9C3),
    ),
    _ActionItem(
      type: QuickActionType.gymMode,
      icon: Icons.fitness_center,
      label: 'Gói\nGym/PT',
      gradientColors: [Color(0xFFDC2626), Color(0xFFF87171)],
      bgColor: Color(0xFFFEE2E2),
    ),
    _ActionItem(
      type: QuickActionType.vietPreferences,
      icon: Icons.storefront,
      label: 'Sở thích\nViệt Nam',
      gradientColors: [Color(0xFFEA580C), Color(0xFFFB923C)],
      bgColor: Color(0xFFFFEDD5),
    ),
    _ActionItem(
      type: QuickActionType.favorites,
      icon: Icons.favorite,
      label: 'Yêu\nthích',
      gradientColors: [Color(0xFFDB2777), Color(0xFFF472B6)],
      bgColor: Color(0xFFFCE7F3),
    ),
    _ActionItem(
      type: QuickActionType.safetyHub,
      icon: Icons.security,
      label: 'An toàn &\nTuân thủ',
      gradientColors: [Color(0xFF9333EA), Color(0xFFC084FC)],
      bgColor: Color(0xFFF3E8FF),
    ),
    _ActionItem(
      type: QuickActionType.nutritionLearning,
      icon: Icons.menu_book_outlined,
      label: 'Góc\ndinh dưỡng',
      gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      bgColor: Color(0xFFDBEAFE),
    ),
    _ActionItem(
      type: QuickActionType.officeReminders,
      icon: Icons.schedule_outlined,
      label: 'Nhắc nhở\nvăn phòng',
      gradientColors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
      bgColor: Color(0xFFCCFBF1),
    ),
  ];

  void _navigateTo(BuildContext context, QuickActionType type) {
    Widget screen;
    switch (type) {
      case QuickActionType.todayEat:
        screen = const DailyStarterScreen();
        break;
      case QuickActionType.eatOut:
        screen = const FoodCaptureScreen();
        break;
      case QuickActionType.mealPlan:
        screen = const MealPlanScreen();
        break;
      case QuickActionType.planVsActual:
        screen = const PlannedVsActualScreen();
        break;
      case QuickActionType.gymMode:
        screen = const GymerHubScreen();
        break;
      case QuickActionType.vietPreferences:
        screen = const LocalPreferencesScreen();
        break;
      case QuickActionType.searchFood:
        screen = const DiscoverView();
        break;
      case QuickActionType.favorites:
        screen = const FavoritesScreen();
        break;
      case QuickActionType.calcCalo:
        screen = const IngredientScanScreen();
        break;
      case QuickActionType.weightLog:
        _openWeightLog(context);
        return;
      case QuickActionType.safetyHub:
        screen = const SafetyHubScreen();
        break;
      case QuickActionType.ingredientSubstitution:
        screen = const IngredientSubstitutionScreen();
        break;
      case QuickActionType.savedTemplates:
        screen = const MealTemplatesScreen();
        break;
      case QuickActionType.nutritionLearning:
        screen = const MicroLearningScreen();
        break;
      case QuickActionType.officeReminders:
        screen = const AdaptiveRemindersScreen();
        break;
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

  void _showAllFeaturesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (scrollContext, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tất cả tính năng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _actions.length,
                      itemBuilder: (gridContext, index) {
                        final action = _actions[index];
                        return _QuickActionItem(
                          action: action,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _navigateTo(context, action.type);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
          // Grid (With Labels, Card Header removed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                if (index == 7) {
                  return _QuickActionItem(
                    action: const _ActionItem(
                      type: QuickActionType.calcCalo,
                      icon: Icons.apps_rounded,
                      label: 'Khác',
                      gradientColors: [AppColors.primary, AppColors.primaryLight],
                      bgColor: Colors.white,
                    ),
                    onTap: () => _showAllFeaturesSheet(context),
                  );
                }

                final action = _actions[index];
                return _QuickActionItem(
                  action: action,
                  onTap: () => _navigateTo(context, action.type),
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
                fontSize: 11,
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
  final QuickActionType type;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color bgColor;

  const _ActionItem({
    required this.type,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.bgColor,
  });
}
