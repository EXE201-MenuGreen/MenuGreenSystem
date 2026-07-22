import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/utils/subscription_access.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../../tracking/utils/nutrition_warning_utils.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../../vietnam_local/repositories/vietnam_local_repositories.dart';
import '../../vietnam_local/views/daily_starter_screen.dart';
import '../../onboarding/repositories/user_ai_profile_repository.dart';
import '../../office/widgets/office_home_panel.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/casual_package_card.dart';
import '../widgets/home_calorie_section.dart';
import '../widgets/gymer_package_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/recommended_meal_card.dart';
import '../widgets/tip_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.onNavigateToTab, this.onTrackingUpdated});

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
  final _aiProfileRepository = UserAiProfileRepository();
  final _subscriptionRepository = UserSubscriptionRepository();
  String _userName = 'MinMin';
  String? _avatarUrl;
  MealDaySummary? _todaySummary;
  MealPlanAdherence? _mealPlanAdherence;
  bool _refreshing = false;
  bool _hasGymerAccess = false;
  bool _hasCasualAccess = false;
  List<RecommendedMealItem> _recommendedMeals = [];
  List<TipItem> _tips = [];
  bool _isOfficeMode = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Chào buổi chiều 🌤️';
    } else if (hour >= 17 && hour < 22) {
      return 'Chào buổi tối 🌙';
    } else {
      return 'Ngủ ngon nhé 😴';
    }
  }

  @override
  void initState() {
    super.initState();
    refreshHeader();
    refreshSubscriptionAccess();
    _loadTodaySummary();
    _loadMealPlanAdherence();
    _loadRecommendations();
    _loadTips();
    _loadOfficeMode();
    _notificationProvider.loadUnreadCount();
  }

  Future<void> _loadOfficeMode() async {
    final isOffice = await _aiProfileRepository.isOfficeMode();
    if (mounted) setState(() => _isOfficeMode = isOffice);
  }

  Future<void> refreshHeader() async {
    final name = await _tokenStorage.getFullName();
    Map<String, dynamic>? profile;
    try {
      profile = await _profileRepository.getMyProfile().timeout(
        const Duration(seconds: 20),
      );
    } catch (_) {
      profile = null;
    }
    if (!mounted) return;

    final rawAvatar = profile?['avatarUrl']?.toString();
    setState(() {
      if (name != null && name.isNotEmpty) _userName = name;
      final fullName = profile?['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) _userName = fullName;
      _avatarUrl = (rawAvatar != null && rawAvatar.isNotEmpty)
          ? rawAvatar
          : null;
    });
    unawaited(_loadOfficeMode());
  }

  Future<void> refreshSubscriptionAccess() async {
    final subscriptions = await _subscriptionRepository.getActive();
    if (!mounted) return;
    setState(() {
      _hasGymerAccess = hasGymerSubscriptionAccess(subscriptions);
      _hasCasualAccess = hasCasualSubscriptionAccess(subscriptions);
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
        setState(() {
          _recommendedMeals = data.map((meal) {
            final map = <String, dynamic>{
              'foodId': meal.id,
              'name': meal.name,
              'caloriesKcal': meal.caloriesKcal,
            };
            return RecommendedMealItem(
              title: meal.name.isEmpty ? 'Món ăn' : meal.name,
              subtitle: 'Gợi ý theo calo còn lại',
              calories: meal.caloriesKcal.toInt(),
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

  void _loadTips() {
    final warnings = _todaySummary == null
        ? <String>[]
        : NutritionWarningMessages.fromSummary(_todaySummary!);

    final tips = <TipItem>[
      TipItem(
        title: 'Uống đủ nước',
        description:
            'Nên uống ít nhất 2 lít nước mỗi ngày để duy trì sức khỏe tốt.',
        type: TipType.health,
      ),
      TipItem(
        title: 'Mẹo giảm cân',
        description:
            'Ăn chậm nhai kỹ giúp no lâu hơn và giảm lượng thức ăn nạp vào.',
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
        SnackBar(
          content: Text('Chi tiết cho "${item.title}" đang được phát triển.'),
        ),
      );
      return;
    }

    final recipeId = data['recipeId']?.toString();
    final foodId = data['foodId']?.toString();

    if (recipeId != null &&
        recipeId.isNotEmpty &&
        recipeId.toLowerCase() != 'null') {
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
        MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: foodId)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chi tiết cho "${item.title}" đang được phát triển.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await refreshHeader();
          await refreshSubscriptionAccess();
          await _loadTodaySummary(userInitiated: true);
          await _loadMealPlanAdherence();
          await _loadRecommendations();
          await _loadOfficeMode();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildHeader(),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: HomeBannerCarousel(),
              ),
              const SizedBox(height: 20),
              if (_isOfficeMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OfficeHomePanel(),
                ),
                const SizedBox(height: 20),
              ],
              if (_hasCasualAccess) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CasualPackageCard(),
                ),
              ],
              if (_hasGymerAccess) ...[
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: GymerPackageCard(),
                ),
                const SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuickActionGrid(isOfficeMode: _isOfficeMode),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTodaySection(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TipsSection(
                  items: _tips,
                  onItemTap: (tip) {
                    if (tip.type == TipType.warning) {
                      widget.onNavigateToTab?.call(0);
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
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
                Color(0xFF52B788),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 20.5,
              backgroundColor: AppColors.progressBackground,
              backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
              child: hasAvatar
                  ? null
                  : const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting().toUpperCase(),
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName,
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
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
                  MaterialPageRoute(
                    builder: (_) => const NotificationInboxScreen(),
                  ),
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
    final targetCalories = (summary?.targetCalories ?? 1850)
        .clamp(1, 10000)
        .toInt();
    final totalProtein = (summary?.totalProteinG ?? 0).toInt();
    final totalCarbs = (summary?.totalCarbsG ?? 0).toInt();
    final totalFat = (summary?.totalFatG ?? 0).toInt();
    final targetProtein = (summary?.targetProteinG ?? 120)
        .clamp(1, 10000)
        .toInt();
    final targetCarbs = (summary?.targetCarbsG ?? 220).clamp(1, 10000).toInt();
    final targetFat = (summary?.targetFatG ?? 60).clamp(1, 10000).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeCalorieSection(
          totalCalories: totalCalories,
          targetCalories: targetCalories,
          protein: totalProtein,
          targetProtein: targetProtein,
          carbs: totalCarbs,
          targetCarbs: targetCarbs,
          fat: totalFat,
          targetFat: targetFat,
          onTap: () => widget.onNavigateToTab?.call(0),
        ),
        const SizedBox(height: 14),
        _buildMealPlanCard(),
        const SizedBox(height: 14),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primary.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kế hoạch hôm nay',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealLogsSection() {
    final logs = _todaySummary?.mealLogs ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                  const Color(0xFF10B981).withValues(alpha: 0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.list_alt_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nhật ký ăn uống',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _refreshing ? null : _addMealFromHome,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Thêm',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: logs.isEmpty
                ? _buildEmptyMealLogs()
                : _buildMealLogsList(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMealLogs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa ghi nhận bữa ăn',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy thêm bữa ăn hôm nay để tính calo.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealLogsList(List<MealLogItem> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...logs.take(4).map((meal) {
          final mealType = _mealTypeLabel(meal.mealType);
          Color tagBgColor;
          Color tagTextColor;
          if (mealType == 'sáng') {
            tagBgColor = const Color(0xFFEFF6FF);
            tagTextColor = const Color(0xFF2563EB);
          } else if (mealType == 'trưa') {
            tagBgColor = const Color(0xFFFEF3C7);
            tagTextColor = const Color(0xFFD97706);
          } else if (mealType == 'tối') {
            tagBgColor = const Color(0xFFFEE2E2);
            tagTextColor = const Color(0xFFDC2626);
          } else {
            tagBgColor = const Color(0xFFF3E8FF);
            tagTextColor = const Color(0xFF7C3AED);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tagBgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meal.isRecipe
                        ? Icons.menu_book_rounded
                        : Icons.restaurant_rounded,
                    color: tagTextColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.displayName,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bữa $mealType',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tagTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${meal.caloriesKcal.toStringAsFixed(0)} kcal',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        }),
        if (logs.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '+${logs.length - 4} bữa ăn khác',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã ghi nhật ký bữa ăn.')));
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.textDark, size: 22),
            if (badge > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        onPressed: onTap,
      ),
    );
  }
}
