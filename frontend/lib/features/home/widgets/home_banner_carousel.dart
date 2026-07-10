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
      color: Color(0xFF1B4332),
      bgColor: Color(0xFFE8F5E9),
    ),
    _BannerData(
      title: 'Theo dõi cân nặng',
      subtitle: 'Cập nhật cân nặng mỗi ngày để đạt mục tiêu',
      icon: Icons.monitor_weight_outlined,
      color: Color(0xFF2D5A45),
      bgColor: Color(0xFFE3F2FD),
    ),
    _BannerData(
      title: 'Kế hoạch vs Thực tế',
      subtitle: 'Xem điểm bám sát kế hoạch dinh dưỡng của bạn',
      icon: Icons.insights,
      color: Color(0xFF1B4332),
      bgColor: Color(0xFFFFF8E1),
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
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _banners.length,
            itemBuilder: (context, index) => _buildBanner(_banners[index], index),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppColors.primary
                    : AppColors.progressBackground,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(_BannerData data, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 0;
        if (_pageController.position.haveDimensions) {
          value = index - (_pageController.page ?? 0);
          value = (1 - value.abs() * 0.3).clamp(0.0, 1.0);
        }
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: 0.6 + (value * 0.4),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: data.color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
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
              Icons.arrow_forward_ios,
              size: 14,
              color: data.color.withValues(alpha: 0.5),
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
  final Color color;
  final Color bgColor;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
