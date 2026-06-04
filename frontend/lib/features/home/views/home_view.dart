import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../../tracking/utils/nutrition_warning_utils.dart';

import '../../meal_plan/models/meal_plan_models.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../meal_plan/views/meal_plan_today_screen.dart';
import '../../tracking/widgets/meal_log_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.onNavigateToTab,
    this.onTrackingUpdated,
  });

  final void Function(int tabIndex)? onNavigateToTab;
  final VoidCallback? onTrackingUpdated;

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  final _tokenStorage = TokenStorage();
  final _profileRepository = ProfileRepository();
  final _trackingRepository = NutritionTrackingRepository();
  final _mealPlanRepository = MealPlanRepository();
  String _userName = 'MinMin';
  String? _avatarUrl;
  MealDaySummary? _todaySummary;
  MealPlanAdherence? _mealPlanAdherence;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    refreshHeader();
    _loadTodaySummary();
    _loadMealPlanAdherence();
  }

  Future<void> refreshHeader() async {
    final name = await _tokenStorage.getFullName();
    Map<String, dynamic>? profile;
    try {
      profile = await _profileRepository
          .getMyProfile()
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      profile = null;
    }
    if (!mounted) return;

    final rawAvatar = profile?['avatarUrl']?.toString();
    setState(() {
      if (name != null && name.isNotEmpty) _userName = name;
      final fullName = profile?['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) _userName = fullName;
      _avatarUrl = (rawAvatar != null && rawAvatar.isNotEmpty) ? rawAvatar : null;
    });
  }

  Future<void> reloadSummary() async {
    await _loadTodaySummary(userInitiated: false);
    await _loadMealPlanAdherence();
  }

  Future<void> _loadMealPlanAdherence() async {
    try {
      final adherence = await _mealPlanRepository.getAdherence(DateTime.now());
      if (!mounted) return;
      setState(() => _mealPlanAdherence = adherence);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mealPlanAdherence = null);
    }
  }

  void _openMealPlanToday() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealPlanTodayScreen(
          onMealLogged: () {
            reloadSummary();
            widget.onTrackingUpdated?.call();
          },
        ),
      ),
    ).then((_) => reloadSummary());
  }

  Future<void> _loadTodaySummary({bool userInitiated = false}) async {
    if (_refreshing) return;
    if (userInitiated) setState(() => _refreshing = true);
    try {
      final summary = await _trackingRepository
          .getDailySummary(DateTime.now())
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() => _todaySummary = summary);
    } catch (_) {
      if (!mounted) return;
      if (userInitiated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được dữ liệu. Kiểm tra mạng và thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted && userInitiated) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCalorieCard(),
            const SizedBox(height: 16),
            _buildMealPlanCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Nhật ký hôm nay', showAddButton: true),
            const SizedBox(height: 16),
            _buildTodayMealLogs(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.progressBackground,
          backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
          child: hasAvatar
              ? null
              : const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHÀO BUỔI SÁNG!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_userName, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.progressBackground.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _refreshing
                ? null
                : () => _loadTodaySummary(userInitiated: true),
          ),
        )
      ],
    );
  }

  Widget _buildCalorieCard() {
    final summary = _todaySummary;
    final totalCalories = summary?.totalCalories ?? 0;
    final targetCalories = (summary?.targetCalories ?? 1850).clamp(1, 10000);
    final remainingCalories = (targetCalories - totalCalories).clamp(-99999, 99999);
    final progress = (totalCalories / targetCalories).clamp(0, 1).toDouble();
    final goalPercent = summary?.goalCompletionPercent ??
        (targetCalories > 0 ? totalCalories / targetCalories * 100 : null);
    final totalProtein = summary?.totalProteinG ?? 0;
    final totalCarbs = summary?.totalCarbsG ?? 0;
    final totalFat = summary?.totalFatG ?? 0;
    final targetProtein = (summary?.targetProteinG ?? 120).clamp(1, 10000);
    final targetCarbs = (summary?.targetCarbsG ?? 220).clamp(1, 10000);
    final targetFat = (summary?.targetFatG ?? 60).clamp(1, 10000);
    final warnings = summary == null
        ? <String>[]
        : NutritionWarningMessages.fromSummary(summary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TIẾN ĐỘ CALO HÔM NAY', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.ideographic,
                    children: [
                      Text('${totalCalories.toStringAsFixed(0)} ', style: const TextStyle(color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('/ ${targetCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (goalPercent != null)
                    Text(
                      '${goalPercent.toStringAsFixed(0)}% mục tiêu',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  const Text('Còn lại', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${remainingCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...warnings.take(2).map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.progressBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroInfo('PROTEIN', '${totalProtein.toStringAsFixed(0)}g', '${targetProtein.toStringAsFixed(0)}g'),
              _buildMacroInfo('CARBS', '${totalCarbs.toStringAsFixed(0)}g', '${targetCarbs.toStringAsFixed(0)}g'),
              _buildMacroInfo('CHẤT BÉO', '${totalFat.toStringAsFixed(0)}g', '${targetFat.toStringAsFixed(0)}g'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMealPlanCard() {
    final adherence = _mealPlanAdherence;
    final subtitle = adherence != null && adherence.totalCount > 0
        ? '${adherence.completedCount}/${adherence.totalCount} bữa theo kế hoạch'
        : 'Lập thực đơn chủ động cho hôm nay';

    return InkWell(
      onTap: _openMealPlanToday,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kế hoạch hôm nay',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String label, String current, String total) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('$current ', style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('/ $total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool showAddButton = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        if (showAddButton)
          TextButton.icon(
            onPressed: _refreshing ? null : _addMealFromHome,
            icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
            label: const Text(
              'Thêm bữa ăn',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Future<void> _addMealFromHome() async {
    final ok = await showMealLogSheet(context, loggedAt: DateTime.now());
    if (!mounted || !ok) return;
    await _loadTodaySummary(userInitiated: false);
    widget.onTrackingUpdated?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã ghi nhật ký bữa ăn.')),
    );
  }

  Widget _buildTodayMealLogs() {
    final logs = _todaySummary?.mealLogs ?? [];
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.progressBackground),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chưa có bữa ăn được ghi hôm nay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ghi bữa ăn ngay hoặc khám phá món để thêm vào nhật ký.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Thêm bữa ăn',
                onPressed: _refreshing ? null : _addMealFromHome,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onNavigateToTab == null
                    ? null
                    : () => widget.onNavigateToTab!(1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Khám phá món'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _refreshing ? null : () => _loadTodaySummary(userInitiated: true),
                child: Text(_refreshing ? 'Đang tải...' : 'Làm mới'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...logs.map((meal) {
          final mealType = _mealTypeLabel(meal.mealType);
          final portion = meal.isRecipe
              ? '${meal.quantityG.toStringAsFixed(0)}% phần'
              : '${meal.quantityG.toStringAsFixed(0)} g';
          final canOpenDetail = _canOpenMealDetail(meal);
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: canOpenDetail ? () => _openMealDetail(meal) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.progressBackground),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.progressBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        meal.isRecipe ? Icons.menu_book_outlined : Icons.restaurant,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bữa $mealType • $portion • ${meal.caloriesKcal.toStringAsFixed(0)} kcal',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (canOpenDetail)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Chạm để xem chi tiết',
                                style: TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canOpenDetail)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _refreshing ? null : () => _loadTodaySummary(userInitiated: true),
            child: Text(_refreshing ? 'Đang tải...' : 'Làm mới'),
          ),
        ),
      ],
    );
  }

  String _mealTypeLabel(String? mealType) {
    final value = mealType?.trim().toLowerCase() ?? '';
    switch (value) {
      case 'breakfast':
      case 'bữa sáng':
        return 'sáng';
      case 'lunch':
      case 'bữa trưa':
        return 'trưa';
      case 'dinner':
      case 'bữa tối':
        return 'tối';
      default:
        return 'phụ';
    }
  }

  bool _isValidId(String? id) {
    if (id == null) return false;
    final trimmed = id.trim();
    return trimmed.isNotEmpty && trimmed.toLowerCase() != 'null';
  }

  bool _canOpenMealDetail(MealLogItem meal) {
    return _isValidId(meal.recipeId) || _isValidId(meal.foodId);
  }

  Future<void> _openMealDetail(MealLogItem meal) async {
    if (_isValidId(meal.recipeId)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: meal.recipeId!.trim()),
        ),
      );
      return;
    }
    if (_isValidId(meal.foodId)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: meal.foodId!.trim()),
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có liên kết chi tiết cho món này.')),
    );
  }
}
