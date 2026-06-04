import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../discover/views/discover_view.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../history/views/history_view.dart';
import '../../home/views/home_view.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../profile/views/profile_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeViewState>();
  final _discoverKey = GlobalKey<DiscoverViewState>();
  DateTime? _lastHomeRefreshAt;

  /// Chỉ khởi tạo tab khi user mở lần đầu — tránh gọi API nền làm chậm/đơ.
  final List<Widget?> _pageCache = List<Widget?>.filled(5, null);

  Widget _pageAt(int index) {
    return _pageCache[index] ??= switch (index) {
      0 => HomeView(key: _homeKey),
      1 => DiscoverView(key: _discoverKey),
      2 => const Center(child: Text('Trợ lý AI')),
      3 => const HistoryView(),
      4 => ProfileView(onProfileUpdated: () => _homeKey.currentState?.refreshHeader()),
      _ => const SizedBox.shrink(),
    };
  }

  /// Chỉ build tab đã từng mở — tránh List.generate gọi _pageAt cho cả 5 tab ngay lúc vào app.
  Widget _stackChild(int index) {
    if (_pageCache[index] == null && index != _currentIndex) {
      return const SizedBox.shrink();
    }
    return _pageAt(index);
  }

  @override
  void initState() {
    super.initState();
    // Trì hoãn — tránh tranh API với tab Khám phá/Cá nhân ngay sau khi vào app.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) unawaited(_redirectIfOnboardingNeeded());
    });
  }

  Future<void> _redirectIfOnboardingNeeded() async {
    try {
      final complete = await OnboardingGate()
          .isOnboardingComplete()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (!complete) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (_) {
      // Giữ user ở MainScreen nếu API chậm/lỗi — HomeView vẫn dùng được.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _stackChild),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            final last = _lastHomeRefreshAt;
            final now = DateTime.now();
            if (last == null || now.difference(last) > const Duration(seconds: 60)) {
              _lastHomeRefreshAt = now;
              _homeKey.currentState?.refreshHeader();
            }
          } else if (index == 1) {
            _discoverKey.currentState?.refreshAllergyStatus();
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
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'Trợ lý AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
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
