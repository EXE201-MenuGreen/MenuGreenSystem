import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../ai_assistant/providers/ai_assistant_provider.dart';
import '../../ai_assistant/views/ai_conversation_list_screen.dart';
import '../../discover/views/discover_view.dart';
import '../../history/views/history_view.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../meal_plan/views/smart_meal_plan_router_screen.dart';
import '../../main/widgets/floating_ai_assistant_button.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import '../../discover/views/recommendation_screen.dart';
import '../../../core/services/push_notification_provider.dart';
import '../../subscription/repositories/user_subscription_repository.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _discoverTab = 0;
  static const _homeTab = 2;
  static const _historyTab = 3;
  static const _profileTab = 4;

  int _currentIndex = _homeTab;
  final _homeKey = GlobalKey<HomeViewState>();
  final _discoverKey = GlobalKey<DiscoverViewState>();
  final _historyKey = GlobalKey<HistoryViewState>();
  final _subscriptionRepository = UserSubscriptionRepository();
  DateTime? _lastHomeRefreshAt;
  DateTime? _lastHistoryRefreshAt;
  Offset? _aiButtonOffset;
  bool _hasAiVipAccess = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DiscoverView(key: _discoverKey),
      const SmartMealPlanRouterScreen(),
      HomeView(
        key: _homeKey,
        onNavigateToTab: _selectTab,
        onTrackingUpdated: () {
          _homeKey.currentState?.reloadSummary();
          _historyKey.currentState?.reloadData();
        },
      ),
      HistoryView(
        key: _historyKey,
        onTrackingUpdated: () => _homeKey.currentState?.reloadSummary(),
      ),
      ProfileView(onProfileUpdated: () => _homeKey.currentState?.refreshHeader()),
    ];
    unawaited(_initPushNotifications());
    unawaited(_loadSubscriptionVisualState());
  }

  Future<void> _initPushNotifications() async {
    try {
      final provider = PushNotificationProvider();
      await provider.initialize(context);
      await provider.registerToken();
    } catch (e) {
      debugPrint('[MainScreen] Failed to init push notifications: $e');
    }
  }

  Future<void> _loadSubscriptionVisualState() async {
    try {
      final access = await _subscriptionRepository.getFeatureAccess();
      if (!mounted) return;
      setState(() {
        _hasAiVipAccess = access.hasAi;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasAiVipAccess = false;
      });
    }
  }

  void _refreshHomeIfStale() {
    final last = _lastHomeRefreshAt;
    final now = DateTime.now();
    if (last == null || now.difference(last) > const Duration(seconds: 30)) {
      _lastHomeRefreshAt = now;
      _homeKey.currentState?.refreshHeader();
      _homeKey.currentState?.reloadSummary();
    }
  }

  void _refreshHistoryIfStale() {
    final last = _lastHistoryRefreshAt;
    final now = DateTime.now();
    if (last == null || now.difference(last) > const Duration(seconds: 30)) {
      _lastHistoryRefreshAt = now;
      _historyKey.currentState?.reloadData();
    }
  }

  void _selectTab(int index) {
    if (index < _discoverTab || index > _profileTab) return;

    setState(() => _currentIndex = index);
    if (index == _homeTab) {
      _homeKey.currentState?.refreshSubscriptionAccess();
      unawaited(_loadSubscriptionVisualState());
      _refreshHomeIfStale();
    } else if (index == _discoverTab) {
      _discoverKey.currentState?.refreshAllergyStatus();
    } else if (index == _historyTab) {
      _refreshHistoryIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    const regularButtonSize = 64.0;
    const vipButtonSize = 72.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final buttonSize = _hasAiVipAccess
              ? vipButtonSize
              : regularButtonSize;
          final defaultOffset = Offset(
            constraints.maxWidth - buttonSize - 18,
            constraints.maxHeight - buttonSize - 26,
          );
          final effectiveOffset = _aiButtonOffset ?? defaultOffset;

          return Stack(
            children: [
              Positioned.fill(
                child: context.isDesktop
                    ? Row(
                        children: [
                          _buildNavigationRail(),
                          Expanded(
                            child: IndexedStack(
                              index: _currentIndex,
                              children: _pages,
                            ),
                          ),
                        ],
                      )
                    : IndexedStack(
                        index: _currentIndex,
                        children: _pages,
                      ),
              ),
              if (_currentIndex == _homeTab && _hasAiVipAccess)
                Positioned(
                  left: effectiveOffset.dx
                      .clamp(12.0, constraints.maxWidth - buttonSize - 12)
                      .toDouble(),
                  top: effectiveOffset.dy
                      .clamp(12.0, constraints.maxHeight - buttonSize - 12)
                      .toDouble(),
                  child: FloatingAiAssistantButton(
                    isVip: _hasAiVipAccess,
                    onTap: () => _showAiMenu(context),
                    onPanUpdate: (details) {
                      setState(() {
                        final current = _aiButtonOffset ?? defaultOffset;
                        final next = current + details.delta;
                        _aiButtonOffset = Offset(
                          next.dx
                              .clamp(
                                12.0,
                                constraints.maxWidth - buttonSize - 12,
                              )
                              .toDouble(),
                          next.dy
                              .clamp(
                                12.0,
                                constraints.maxHeight - buttonSize - 12,
                              )
                              .toDouble(),
                        );
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: context.isPhone ? _buildBottomNavBar() : null,
      drawer: context.isTablet ? _buildNavigationDrawer(context) : null,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _selectTab,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 10,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: _buildNavItems(),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MenuGreen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ..._buildNavDrawerItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _selectTab,
      backgroundColor: Colors.white,
      elevation: 4,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.eco, color: Colors.white, size: 26),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: Text('Khám phá'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: Text('Kế hoạch'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Trang chủ'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Lịch sử'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Cá nhân'),
        ),
      ],
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    return [
      _buildNavItem(Icons.explore_outlined, Icons.explore, 'Khám phá', 0),
      _buildNavItem(Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Kế hoạch', 1),
      _buildNavHomeItem(),
      _buildNavItem(Icons.history_outlined, Icons.history, 'Lịch sử', 3),
      _buildNavItem(Icons.person_outline, Icons.person, 'Cá nhân', 4),
    ];
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 44,
        child: Icon(icon, size: 24),
      ),
      activeIcon: SizedBox(
        height: 44,
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildNavHomeItem() {
    return BottomNavigationBarItem(
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
            center: const Alignment(-0.3, -0.3),
            radius: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.home_outlined,
          size: 26,
          color: AppColors.textSecondary,
        ),
      ),
      activeIcon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.primary,
            ],
            center: const Alignment(-0.3, -0.3),
            radius: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.home, size: 26, color: Colors.white),
      ),
      label: 'Trang chủ',
    );
  }

  List<Widget> _buildNavDrawerItems() {
    final items = [
      const _NavDrawerItem(Icons.explore_outlined, Icons.explore, 'Khám phá', 0),
      const _NavDrawerItem(Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Kế hoạch', 1),
      const _NavDrawerItem(Icons.home_outlined, Icons.home, 'Trang chủ', 2),
      const _NavDrawerItem(Icons.history_outlined, Icons.history, 'Lịch sử', 3),
      const _NavDrawerItem(Icons.person_outline, Icons.person, 'Cá nhân', 4),
    ];

    return items.map((item) {
      final isSelected = _currentIndex == item.index;
      return ListTile(
        leading: Icon(
          isSelected ? item.activeIcon : item.icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textDark,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          _selectTab(item.index);
        },
      );
    }).toList();
  }

  void _showAiMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                spreadRadius: 1,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'MenuGreen AI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn tính năng thông minh của trợ lý dinh dưỡng',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildAiMenuItem(
                context: sheetContext,
                icon: Icons.qr_code_scanner_rounded,
                title: 'Quét nguyên liệu',
                subtitle: 'Nhận diện thực phẩm qua camera & phân tích dinh dưỡng',
                iconGradient: const [Color(0xFF2D5A45), Color(0xFF1B4332)],
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    sheetContext,
                    MaterialPageRoute(
                      builder: (_) => const IngredientScanScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildAiMenuItem(
                context: sheetContext,
                icon: Icons.auto_awesome_rounded,
                title: 'Gợi ý cá nhân hóa',
                subtitle: 'Thực đơn thông minh phù hợp với thể trạng của bạn',
                iconGradient: const [Color(0xFF40916C), Color(0xFF2D5A45)],
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    sheetContext,
                    MaterialPageRoute(
                      builder: (_) => const RecommendationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildAiMenuItem(
                context: sheetContext,
                icon: Icons.chat_bubble_rounded,
                title: 'Trợ lý trò chuyện',
                subtitle: 'Hỏi đáp dinh dưỡng & giải đáp thắc mắc sức khỏe',
                iconGradient: const [Color(0xFF74C69D), Color(0xFF40916C)],
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    sheetContext,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => AiAssistantProvider()..loadConversations(),
                        child: const AiConversationListScreen(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> iconGradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDrawerItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const _NavDrawerItem(this.icon, this.activeIcon, this.label, this.index);
}
