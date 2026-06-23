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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeViewState>();
  final _discoverKey = GlobalKey<DiscoverViewState>();
  final _historyKey = GlobalKey<HistoryViewState>();
  DateTime? _lastHomeRefreshAt;
  DateTime? _lastHistoryRefreshAt;

  final List<Widget?> _pageCache = List<Widget?>.filled(6, null);

  Widget _pageAt(int index) {
    return _pageCache[index] ??= switch (index) {
      0 => HomeView(
          key: _homeKey,
          onNavigateToTab: (index) => setState(() => _currentIndex = index),
          onTrackingUpdated: () {
            _homeKey.currentState?.reloadSummary();
            _historyKey.currentState?.reloadData();
          },
        ),
      1 => DiscoverView(key: _discoverKey),
      2 => const MealPlanScreen(),
      3 => HistoryView(
          key: _historyKey,
          onTrackingUpdated: () => _homeKey.currentState?.reloadSummary(),
        ),
      4 => ChangeNotifierProvider(
          create: (_) => AiAssistantProvider()..loadConversations(),
          child: const AiConversationListScreen(),
        ),
      5 => ProfileView(onProfileUpdated: () => _homeKey.currentState?.refreshHeader()),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _stackChild(int index) {
    if (_pageCache[index] == null && index != _currentIndex) {
      return const SizedBox.shrink();
    }
    return _pageAt(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(6, _stackChild),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _refreshHomeIfStale();
          } else if (index == 1) {
            _discoverKey.currentState?.refreshAllergyStatus();
          } else if (index == 3) {
            _refreshHistoryIfStale();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Kế hoạch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Trợ lý AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
