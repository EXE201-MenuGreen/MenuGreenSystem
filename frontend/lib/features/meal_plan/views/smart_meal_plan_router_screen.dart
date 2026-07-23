import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../gymer/views/gymer_hub_screen.dart';
import '../../office/views/office_meal_plan_screen.dart';
import '../../onboarding/repositories/user_ai_profile_repository.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/utils/subscription_access.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../../vietnam_local/views/planned_vs_actual_screen.dart';
import '../../meal_templates/views/meal_templates_screen.dart';
import 'meal_plan_screen.dart';

enum MealPlanWorkspaceMode { standard, office, gymer }

class SmartMealPlanRouterScreen extends StatefulWidget {
  const SmartMealPlanRouterScreen({super.key, this.initialMode});

  final MealPlanWorkspaceMode? initialMode;

  @override
  State<SmartMealPlanRouterScreen> createState() =>
      _SmartMealPlanRouterScreenState();
}

class _SmartMealPlanRouterScreenState
    extends State<SmartMealPlanRouterScreen> {
  final _profileRepository = UserAiProfileRepository();
  final _subscriptionRepository = UserSubscriptionRepository();

  MealPlanWorkspaceMode _currentMode = MealPlanWorkspaceMode.standard;
  bool _isOfficeMode = false;
  bool _hasGymerAccess = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initWorkspaceState();
  }

  Future<void> _initWorkspaceState() async {
    try {
      final results = await Future.wait([
        _profileRepository.isOfficeMode(),
        _subscriptionRepository.getActive(),
      ]);

      final isOffice = results[0] as bool;
      final subscriptions = results[1] as List<dynamic>;
      final hasGymer = hasGymerSubscriptionAccess(
        subscriptions.cast(),
      );

      if (!mounted) return;

      setState(() {
        _isOfficeMode = isOffice;
        _hasGymerAccess = hasGymer;

        if (widget.initialMode != null) {
          _currentMode = widget.initialMode!;
        } else if (isOffice) {
          _currentMode = MealPlanWorkspaceMode.office;
        } else if (hasGymer) {
          _currentMode = MealPlanWorkspaceMode.gymer;
        } else {
          _currentMode = MealPlanWorkspaceMode.standard;
        }

        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _switchMode(MealPlanWorkspaceMode mode) {
    if (mode == MealPlanWorkspaceMode.gymer && !_hasGymerAccess) {
      _showUpgradePrompt('Gymer VIP');
      return;
    }

    setState(() {
      _currentMode = mode;
    });
  }

  void _showUpgradePrompt(String planTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Kích hoạt $planTitle'),
          ],
        ),
        content: Text(
          'Bạn cần nâng cấp gói $planTitle để mở khóa chế độ lên kế hoạch & thực đơn chuyên sâu này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpgradePlanScreen()),
              );
            },
            child: const Text('Nâng cấp ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Mode Switcher Selector Bar
            _buildWorkspaceBar(),

            // Mode Body
            Expanded(
              child: IndexedStack(
                index: _currentMode.index,
                children: const [
                  MealPlanScreen(),
                  OfficeMealPlanScreen(),
                  GymerHubScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(
                    mode: MealPlanWorkspaceMode.standard,
                    label: 'Tiêu chuẩn',
                    icon: Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    isUnlocked: true,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    mode: MealPlanWorkspaceMode.office,
                    label: 'Office 🏢',
                    icon: Icons.business_center_rounded,
                    color: const Color(0xFF166534),
                    isUnlocked: _isOfficeMode,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    mode: MealPlanWorkspaceMode.gymer,
                    label: 'Gymer VIP 🏋️',
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFFDC2626),
                    isUnlocked: _hasGymerAccess,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'So sánh Thực tế',
            icon: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlannedVsActualScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Thực đơn mẫu',
            icon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.primary, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MealTemplatesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required MealPlanWorkspaceMode mode,
    required String label,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
  }) {
    final isSelected = _currentMode == mode;

    return InkWell(
      onTap: () => _switchMode(mode),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : isUnlocked
                  ? color.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : isUnlocked
                    ? color.withValues(alpha: 0.25)
                    : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : isUnlocked
                      ? color
                      : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isUnlocked
                        ? color
                        : Colors.grey.shade600,
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
