import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../ai_assistant/providers/ai_assistant_provider.dart';
import '../../ai_assistant/views/ai_conversation_list_screen.dart';
import '../../discover/views/discover_view.dart';
import '../../history/views/history_view.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../meal_plan/views/meal_plan_screen.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import '../../discover/views/recommendation_screen.dart';
import '../../../core/services/push_notification_provider.dart';

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
  DateTime? _lastHomeRefreshAt;
  DateTime? _lastHistoryRefreshAt;

  @override
  void initState() {
    super.initState();
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

  List<Widget> _buildPages() => [
    DiscoverView(key: _discoverKey),
    const MealPlanScreen(),
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
      _refreshHomeIfStale();
    } else if (index == _discoverTab) {
      _discoverKey.currentState?.refreshAllergyStatus();
    } else if (index == _historyTab) {
      _refreshHistoryIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _buildPages()),
      floatingActionButton: _currentIndex == _homeTab
          ? FloatingActionButton(
              onPressed: () => _showAiMenu(context),
              backgroundColor: AppColors.primary.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
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
        items: [
          const BottomNavigationBarItem(
            icon: SizedBox(
              height: 44,
              child: Icon(Icons.explore_outlined, size: 24),
            ),
            activeIcon: SizedBox(
              height: 44,
              child: Icon(Icons.explore, size: 24),
            ),
            label: 'Khám phá',
          ),
          const BottomNavigationBarItem(
            icon: SizedBox(
              height: 44,
              child: Icon(Icons.restaurant_menu_outlined, size: 24),
            ),
            activeIcon: SizedBox(
              height: 44,
              child: Icon(Icons.restaurant_menu, size: 24),
            ),
            label: 'Kế hoạch',
          ),
          BottomNavigationBarItem(
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
          ),
          const BottomNavigationBarItem(
            icon: SizedBox(
              height: 44,
              child: Icon(Icons.history_outlined, size: 24),
            ),
            activeIcon: SizedBox(
              height: 44,
              child: Icon(Icons.history, size: 24),
            ),
            label: 'Lịch sử',
          ),
          const BottomNavigationBarItem(
            icon: SizedBox(
              height: 44,
              child: Icon(Icons.person_outline, size: 24),
            ),
            activeIcon: SizedBox(
              height: 44,
              child: Icon(Icons.person, size: 24),
            ),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  void _showAiMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
              // Pull handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
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

              // 1. Quét nguyên liệu
              _buildAiMenuItem(
                context: context,
                icon: Icons.qr_code_scanner_rounded,
                title: 'Quét nguyên liệu',
                subtitle:
                    'Nhận diện thực phẩm qua camera & phân tích dinh dưỡng',
                iconGradient: const [Color(0xFF2D5A45), Color(0xFF1B4332)],
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IngredientScanScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 2. Gợi ý cá nhân hóa
              _buildAiMenuItem(
                context: context,
                icon: Icons.auto_awesome_rounded,
                title: 'Gợi ý cá nhân hóa',
                subtitle: 'Thực đơn thông minh phù hợp với thể trạng của bạn',
                iconGradient: const [Color(0xFF40916C), Color(0xFF2D5A45)],
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecommendationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 3. Trò chuyện AI
              _buildAiMenuItem(
                context: context,
                icon: Icons.chat_bubble_rounded,
                title: 'Trợ lý trò chuyện',
                subtitle: 'Hỏi đáp dinh dưỡng & giải đáp thắc mắc sức khỏe',
                iconGradient: const [Color(0xFF74C69D), Color(0xFF40916C)],
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) =>
                            AiAssistantProvider()..loadConversations(),
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
