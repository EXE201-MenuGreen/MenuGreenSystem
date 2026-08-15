import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../discover/views/discover_view.dart';
import '../../history/views/history_view.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../meal_plan/views/smart_meal_plan_router_screen.dart';
import '../../../core/services/push_notification_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 2});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _discoverTab = 0;
  static const _homeTab = 2;
  static const _historyTab = 3;
  static const _profileTab = 4;

  late int _currentIndex;
  final _homeKey = GlobalKey<HomeViewState>();
  final _discoverKey = GlobalKey<DiscoverViewState>();
  final _historyKey = GlobalKey<HistoryViewState>();
  DateTime? _lastHomeRefreshAt;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
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
      ProfileView(
        onProfileUpdated: () => _homeKey.currentState?.refreshHeader(),
      ),
    ];
    unawaited(_initPushNotifications());
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

  void _refreshHomeIfStale() {
    // Nutrition targets can change immediately when a PT approves a route or
    // the Gymer accepts a coach program, so always reload the daily summary
    // when Home is selected. Keep the heavier header refresh throttled.
    _homeKey.currentState?.reloadSummary();
    final last = _lastHomeRefreshAt;
    final now = DateTime.now();
    if (last == null || now.difference(last) > const Duration(seconds: 30)) {
      _lastHomeRefreshAt = now;
      _homeKey.currentState?.refreshHeader();
    }
  }

  void _refreshHistory() => _historyKey.currentState?.reloadData();

  void _selectTab(int index) {
    if (index < _discoverTab || index > _profileTab) return;

    setState(() => _currentIndex = index);
    if (index == _homeTab) {
      _homeKey.currentState?.refreshSubscriptionAccess();
      _refreshHomeIfStale();
    } else if (index == _discoverTab) {
      _discoverKey.currentState?.refreshAllergyStatus();
    } else if (index == _historyTab) {
      _refreshHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: context.isDesktop
          ? Row(
              children: [
                _buildNavigationRail(),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
              ],
            )
          : IndexedStack(index: _currentIndex, children: _pages),
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
      _buildNavItem(
        Icons.restaurant_menu_outlined,
        Icons.restaurant_menu,
        'Kế hoạch',
        1,
      ),
      _buildNavHomeItem(),
      _buildNavItem(Icons.history_outlined, Icons.history, 'Lịch sử', 3),
      _buildNavItem(Icons.person_outline, Icons.person, 'Cá nhân', 4),
    ];
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: SizedBox(height: 44, child: Icon(icon, size: 24)),
      activeIcon: SizedBox(height: 44, child: Icon(activeIcon, size: 24)),
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
      const _NavDrawerItem(
        Icons.explore_outlined,
        Icons.explore,
        'Khám phá',
        0,
      ),
      const _NavDrawerItem(
        Icons.restaurant_menu_outlined,
        Icons.restaurant_menu,
        'Kế hoạch',
        1,
      ),
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
}

class _NavDrawerItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const _NavDrawerItem(this.icon, this.activeIcon, this.label, this.index);
}
