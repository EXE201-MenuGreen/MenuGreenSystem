import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, this.onBannerTap});

  /// Called when a banner is tapped. The [index] identifies which banner.
  final void Function(int index)? onBannerTap;

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
    final bannerHeight = context.valueForDevice(
      phone: 140.0,
      tablet: 160.0,
      desktop: 180.0,
    );
    final iconSize = context.valueForDevice(
      phone: 30.0,
      tablet: 36.0,
      desktop: 42.0,
    );
    final titleFontSize = context.valueForDevice(
      phone: 17.0,
      tablet: 19.0,
      desktop: 21.0,
    );
    final subtitleFontSize = context.valueForDevice(
      phone: 12.0,
      tablet: 14.0,
      desktop: 15.0,
    );
    final padding = context.valueForDevice(
      phone: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _banners.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => widget.onBannerTap?.call(index),
              child: _buildBanner(_banners[index], iconSize, titleFontSize, subtitleFontSize, padding),
            ),
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

  Widget _buildBanner(_BannerData data, double iconSize, double titleFontSize, double subtitleFontSize, double padding) {
    final decorativeSize = context.valueForDevice(
      phone: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );
    final decorativeSmallSize = context.valueForDevice(
      phone: 80.0,
      tablet: 100.0,
      desktop: 120.0,
    );
    final iconPadding = context.valueForDevice(
      phone: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    final borderRadius = context.valueForDevice(
      phone: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    final arrowPadding = context.valueForDevice(
      phone: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );
    final arrowSize = context.valueForDevice(
      phone: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    final cardRadius = context.valueForDevice(
      phone: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );

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
          borderRadius: BorderRadius.circular(cardRadius),
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
              right: -(decorativeSize * 0.2),
              top: -(decorativeSize * 0.2),
              child: Container(
                width: decorativeSize,
                height: decorativeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -(decorativeSmallSize * 0.3),
              bottom: -(decorativeSmallSize * 0.3),
              child: Container(
                width: decorativeSmallSize,
                height: decorativeSmallSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    child: Icon(data.icon, color: Colors.white, size: iconSize),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.subtitle,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(arrowPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: arrowSize,
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
