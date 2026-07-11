import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScroll;

  static const _banners = [
    _BannerData(
      title: 'Hôm nay ăn gì?',
      subtitle: 'Gợi ý thực đơn cân bằng dinh dưỡng cho bạn',
      icon: Icons.restaurant_menu,
      gradientColors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      accentColor: Color(0xFF52B788),
    ),
    _BannerData(
      title: 'Theo dõi cân nặng',
      subtitle: 'Cập nhật cân nặng mỗi ngày để đạt mục tiêu',
      icon: Icons.monitor_weight_outlined,
      gradientColors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
      accentColor: Color(0xFF90E0EF),
    ),
    _BannerData(
      title: 'Kế hoạch vs Thực tế',
      subtitle: 'Xem điểm bám sát kế hoạch dinh dưỡng của bạn',
      icon: Icons.insights,
      gradientColors: [Color(0xFFF77F00), Color(0xFFFCBF49)],
      accentColor: Color(0xFFFEE440),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScroll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _banners.length,
            itemBuilder: (context, index) => _buildBanner(_banners[index]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? _banners[i].gradientColors.first
                    : AppColors.progressBackground,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(_BannerData data) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 0;
        if (_pageController.position.haveDimensions) {
          value = _currentPage - (_pageController.page ?? 0);
          value = (1 - value.abs() * 0.3).clamp(0.0, 1.0);
        }
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: 0.7 + (value * 0.3),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradientColors.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(data.icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
  });
}
