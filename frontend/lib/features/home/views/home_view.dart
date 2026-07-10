import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/token_storage.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/models/meal_plan_models.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../meal_plan/views/meal_plan_today_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/views/notification_inbox_screen.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../../tracking/utils/nutrition_warning_utils.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../../vietnam_local/repositories/vietnam_local_repositories.dart';
import '../../vietnam_local/views/daily_starter_screen.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_calorie_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/recommended_meal_card.dart';
import '../widgets/tip_card.dart';

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
  final _notificationProvider = NotificationProvider();
  final _dailyStarterRepo = DailyStarterRepository();
  String _userName = 'MinMin';
  String? _avatarUrl;
  MealDaySummary? _todaySummary;
  MealPlanAdherence? _mealPlanAdherence;
  bool _refreshing = false;
  List<RecommendedMealItem> _recommendedMeals = [];
  List<TipItem> _tips = [];

  @override
  void initState() {
    super.initState();
    refreshHeader();
    _loadTodaySummary();
    _loadMealPlanAdherence();
    _loadRecommendations();
    _loadTips();
    _notificationProvider.loadUnreadCount();
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
      setState(() {
        _todaySummary = summary;
      });
      _loadTips();
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

  Future<void> _loadRecommendations() async {
    try {
      final result = await _dailyStarterRepo.getFeaturedMeals();
      if (!mounted) return;
      if (result.success && result.data != null) {
        final data = result.data!;
        final List<dynamic> rawList = data;
        setState(() {
          _recommendedMeals = rawList.map((m) {
            final map = Map<String, dynamic>.from(m as Map);
            final mealType = _normalizeMealType(map['mealType']?.toString() ?? '');
            return RecommendedMealItem(
              title: map['name']?.toString() ?? 'Món ăn',
              subtitle: mealType,
              calories: (map['calories'] ?? map['caloriesKcal'] ?? 0).toInt(),
              color: AppColors.primary,
              bgColor: const Color(0xFFE8F5E9),
              data: map,
            );
          }).toList();
        });
      }
    } catch (_) {
      // silently fail
    }
  }

  String _normalizeMealType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('breakfast')) return 'Bữa sáng';
    if (lower.contains('lunch')) return 'Bữa trưa';
    if (lower.contains('dinner')) return 'Bữa tối';
    if (lower.contains('snack')) return 'Ăn vặt';
    return 'Bữa phụ';
  }

  void _loadTips() {
    final warnings = _todaySummary == null
        ? <String>[]
        : NutritionWarningMessages.fromSummary(_todaySummary!);

    final tips = <TipItem>[
      TipItem(
        title: 'Uống đủ nước',
        description: 'Nên uống ít nhất 2 lít nước mỗi ngày để duy trì sức khỏe tốt.',
        type: TipType.health,
      ),
      TipItem(
        title: 'Mẹo giảm cân',
        description: 'Ăn chậm nhai kỹ giúp no lâu hơn và giảm lượng thức ăn nạp vào.',
        type: TipType.tip,
      ),
      TipItem(
        title: 'Tập thể dục đều đặn',
        description: '30 phút vận động mỗi ngày giúp tăng hiệu quả giảm cân.',
        type: TipType.health,
      ),
    ];

    if (warnings.isNotEmpty) {
      tips.insert(
        0,
        TipItem(
          title: 'Cảnh báo dinh dưỡng',
          description: warnings.first,
          type: TipType.warning,
        ),
      );
    }

    setState(() {
      _tips = tips;
    });
  }

  void _onRecommendedMealTap(RecommendedMealItem item) {
    final data = item.data;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chi tiết cho "${item.title}" đang được phát triển.')),
      );
      return;
    }

    final recipeId = data['recipeId']?.toString();
    final foodId = data['foodId']?.toString();

    if (recipeId != null && recipeId.isNotEmpty && recipeId.toLowerCase() != 'null') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: recipeId),
        ),
      );
      return;
    }

    if (foodId != null && foodId.isNotEmpty && foodId.toLowerCase() != 'null') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: foodId),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết cho "${item.title}" đang được phát triển.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await refreshHeader();
          await _loadTodaySummary(userInitiated: true);
          await _loadMealPlanAdherence();
          await _loadRecommendations();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildHeader(),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: HomeBannerCarousel(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const QuickActionGrid(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildTodaySection(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RecommendedMealSection(
                  items: _recommendedMeals,
                  onItemTap: _onRecommendedMealTap,
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyStarterScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TipsSection(
                  items: _tips,
                  onItemTap: (tip) {
                    if (tip.type == TipType.warning) {
                      widget.onNavigateToTab?.call(1); // Discover tab
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.progressBackground,
          backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
          child: hasAvatar
              ? null
              : const Icon(Icons.person, color: AppColors.textSecondary, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHÀO BUỔI SÁNG!',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _notificationProvider,
          builder: (context, _) {
            final unreadCount = _notificationProvider.unreadCount;
            return _IconButtonWithBadge(
              icon: Icons.notifications_outlined,
              badge: unreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
                ).then((_) => _notificationProvider.loadUnreadCount());
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final summary = _todaySummary;
    final totalCalories = (summary?.totalCalories ?? 0).toInt();
    final targetCalories = (summary?.targetCalories ?? 1850).clamp(1, 10000).toInt();
    final totalProtein = (summary?.totalProteinG ?? 0).toInt();
    final totalCarbs = (summary?.totalCarbsG ?? 0).toInt();
    final totalFat = (summary?.totalFatG ?? 0).toInt();
    final targetProtein = (summary?.targetProteinG ?? 120).clamp(1, 10000).toInt();
    final targetCarbs = (summary?.targetCarbsG ?? 220).clamp(1, 10000).toInt();
    final targetFat = (summary?.targetFatG ?? 60).clamp(1, 10000).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeCalorieCard(
          totalCalories: totalCalories,
          targetCalories: targetCalories,
          protein: totalProtein,
          targetProtein: targetProtein,
          carbs: totalCarbs,
          targetCarbs: targetCarbs,
          fat: totalFat,
          targetFat: targetFat,
        ),
        const SizedBox(height: 12),
        _buildMealPlanCard(),
        const SizedBox(height: 12),
        _buildMealLogsSection(),
      ],
    );
  }

  Widget _buildMealPlanCard() {
    final adherence = _mealPlanAdherence;
    final subtitle = adherence != null && adherence.totalCount > 0
        ? '${adherence.completedCount}/${adherence.totalCount} bữa theo kế hoạch'
        : 'Lập thực đơn chủ động cho hôm nay';

    return InkWell(
      onTap: _openMealPlanToday,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kế hoạch hôm nay',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMealLogsSection() {
    final logs = _todaySummary?.mealLogs ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhật ký hôm nay',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton.icon(
                onPressed: _refreshing ? null : _addMealFromHome,
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text(
                  'Thêm bữa ăn',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (logs.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Chưa có bữa ăn được ghi hôm nay.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ...logs.take(3).map((meal) {
              final mealType = _mealTypeLabel(meal.mealType);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.progressBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        meal.isRecipe ? Icons.menu_book_outlined : Icons.restaurant,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.displayName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Bữa $mealType • ${meal.caloriesKcal.toStringAsFixed(0)} kcal',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (logs.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${logs.length - 3} bữa ăn khác',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
          ],
        ],
      ),
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
}

class _IconButtonWithBadge extends StatelessWidget {
  const _IconButtonWithBadge({
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.textDark, size: 20),
            if (badge > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
      ),
    );
  }
}
