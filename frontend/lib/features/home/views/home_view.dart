import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/token_storage.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/food_map_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/models/meal_plan_models.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../meal_plan/views/meal_plan_today_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/views/notification_inbox_screen.dart';
import '../../coach_chat/providers/coach_chat_provider.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../../tracking/utils/nutrition_warning_utils.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../../vietnam_local/repositories/vietnam_local_repositories.dart';
import '../../vietnam_local/views/daily_starter_screen.dart';
import '../../office/widgets/office_home_panel.dart';
import '../../vietnam_local/views/planned_vs_actual_screen.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/casual_package_card.dart';
import '../widgets/home_calorie_section.dart';
import '../widgets/gymer_package_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/recommended_meal_card.dart';
import '../widgets/tip_card.dart';
import '../widgets/weight_log_sheet.dart';
import '../widgets/home_search_sheet.dart';
import '../widgets/home_header.dart';
import '../widgets/home_today_meal_plan_card.dart';
import '../widgets/home_meal_logs_section.dart';

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
  final _subscriptionRepository = UserSubscriptionRepository();
  String _userName = 'MinMin';
  String? _avatarUrl;
  MealDaySummary? _todaySummary;
  MealPlanAdherence? _mealPlanAdherence;
  bool _refreshing = false;
  FeatureAccess _featureAccess = FeatureAccess.free;
  List<RecommendedMealItem> _recommendedMeals = [];
  List<TipItem> _tips = [];

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
    refreshAll();
    _loadTips();
    _notificationProvider.loadUnreadCount();
    _notificationProvider.loadNotifications(refresh: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CoachChatProvider>().loadPartners();
    });
  }

  @override
  void dispose() {
    _notificationProvider.dispose();
    super.dispose();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshHeader(),
      refreshSubscriptionAccess(),
      _loadTodaySummary(),
      _loadMealPlanAdherence(),
    ]);
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
  }

  Future<void> refreshSubscriptionAccess() async {
    final access = await _subscriptionRepository.getFeatureAccess();
    if (!mounted) return;
    setState(() {
      _featureAccess = access;
      if (!access.hasCasual) _recommendedMeals = [];
    });
    if (access.hasCasual) await _loadRecommendations();
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

  void _handleBannerTap(int index) {
    switch (index) {
      case 0: // Hôm nay ăn gì?
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyStarterScreen()),
        );
        break;
      case 1: // Theo dõi cân nặng
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const WeightLogSheet(),
        );
        break;
      case 2: // Kế hoạch vs Thực tế
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlannedVsActualScreen()),
        );
        break;
    }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HomeBannerCarousel(onBannerTap: _handleBannerTap),
              ),
              const SizedBox(height: 20),
              if (_featureAccess.hasOffice) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OfficeHomePanel(),
                ),
                const SizedBox(height: 20),
              ],
              if (_featureAccess.hasCasual) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CasualPackageCard(),
                ),
              ],
              if (_featureAccess.hasGym) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ListenableBuilder(
                    listenable: _notificationProvider,
                    builder: (context, _) => Consumer<CoachChatProvider>(
                      builder: (context, chat, _) => GymerPackageCard(
                        routeBadgeCount: _notificationProvider.unreadRouteCount,
                        chatBadgeCount: chat.unreadCount,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const QuickActionGrid(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTodaySection(),
              ),
              const SizedBox(height: 20),
              if (_featureAccess.hasCasual) ...[
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
              ],
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPackageDiscovery(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageDiscovery() {
    final packages = <({String title, String description, bool enabled})>[
      (
        title: 'Casual',
        description: 'Chọn món nhanh, Daily Starter và ghi nhận một chạm.',
        enabled: _featureAccess.hasCasual,
      ),
      (
        title: 'Office',
        description: 'Kế hoạch 7 ngày, ngân sách và danh sách đi chợ.',
        enabled: _featureAccess.hasOffice,
      ),
      (
        title: 'Gym/PT',
        description: 'Mục tiêu ngày tập, PT Review, Coach và lộ trình dài hạn.',
        enabled: _featureAccess.hasGym,
      ),
    ].where((item) => !item.enabled).toList();

    if (packages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khám phá gói chuyên biệt',
            style: GoogleFonts.beVietnamPro(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Các công cụ Free của bạn vẫn luôn được giữ nguyên.'),
          const SizedBox(height: 14),
          ...packages.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpgradePlanScreen(),
                        ),
                      ).then((_) => refreshSubscriptionAccess());
                    },
                    child: const Text('Tìm hiểu'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return HomeHeader(
      userName: _userName,
      greeting: _getGreeting(),
      avatarUrl: _avatarUrl,
      notificationProvider: _notificationProvider,
      onSearchTap: () => HomeSearchSheet.show(context),
      onMapTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FoodMapScreen()),
        );
      },
      onNotificationTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
        ).then((_) {
          _notificationProvider.loadUnreadCount();
          _notificationProvider.loadNotifications(refresh: true);
        });
      },
    );
  }

  Widget _buildTodaySection() {
    final summary = _todaySummary;
    final totalCalories = (summary?.totalCalories ?? 0).toInt();
    final targetCalories = (summary?.targetCalories ?? 1850)
        .clamp(0, 10000)
        .toInt();
    final totalProtein = (summary?.totalProteinG ?? 0).toInt();
    final totalCarbs = (summary?.totalCarbsG ?? 0).toInt();
    final totalFat = (summary?.totalFatG ?? 0).toInt();
    final targetProtein = (summary?.targetProteinG ?? 120)
        .clamp(0, 10000)
        .toInt();
    final targetCarbs = (summary?.targetCarbsG ?? 220).clamp(0, 10000).toInt();
    final targetFat = (summary?.targetFatG ?? 60).clamp(0, 10000).toInt();

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlannedVsActualScreen()),
            );
          },
        ),
        const SizedBox(height: 14),
        HomeTodayMealPlanCard(
          adherence: _mealPlanAdherence,
          onTap: _openMealPlanToday,
        ),
        const SizedBox(height: 14),
        HomeMealLogsSection(
          logs: summary?.mealLogs ?? [],
          onAddMeal: _addMealFromHome,
          refreshing: _refreshing,
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
      const SnackBar(
        content: Text('Đã lưu bữa ăn vào Kế hoạch ăn uống và Lịch sử.'),
      ),
    );
  }
}
