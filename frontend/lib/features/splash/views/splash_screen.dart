import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/notification_handler.dart';
import '../../../main.dart';
import '../../auth/views/welcome_screen.dart';
import '../../main/views/main_screen.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../onboarding/views/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _navigated = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    unawaited(_readTokenEarly());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateFromSplash();
      }
    });

    // Dự phòng: không để splash treo nếu animation/listener lỗi.
    Future.delayed(const Duration(seconds: 4), _navigateFromSplash);
  }

  Future<void> _readTokenEarly() async {
    try {
      _token = await TokenStorage()
          .getAccessToken()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Splash token preload: $e');
    }
  }

  Future<void> _navigateFromSplash() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    if (_token == null) {
      try {
        _token = await TokenStorage()
            .getAccessToken()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Splash token read: $e');
      }
    }

    if (!mounted) return;

    var hasValidSession = _token != null && _token!.isNotEmpty;
    if (hasValidSession) {
      try {
        hasValidSession = await ApiClient()
            .ensureValidSession()
            .timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('[Splash] Session validation failed: $error');
        hasValidSession = false;
        await TokenStorage().clear();
      }
    }

    Widget destination = const WelcomeScreen();
    if (hasValidSession) {
      try {
        final complete = await OnboardingGate().isOnboardingComplete();
        destination = complete ? const MainScreen() : const OnboardingScreen();
      } catch (e) {
        debugPrint('[Splash] OnboardingGate error: $e - going to MainScreen');
        destination = const MainScreen();
      }
    }

    if (!mounted) return;

    final pendingNotification = getPendingInitialNotification();
    if (pendingNotification != null && hasValidSession) {
      final handler = NotificationHandler();
      final action = handler.parseNotificationData(pendingNotification.data);
      final notificationDestination = handler.buildDestinationScreen(action, pendingNotification);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => notificationDestination),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.energy_savings_leaf,
                        color: AppColors.primary,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'MenuGreen',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trợ lý dinh dưỡng thông\nminh',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final percentage = (_animation.value * 100).toInt();
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Đang khởi tạo...', style: AppTextStyles.body),
                            Text('$percentage%', style: AppTextStyles.progressText),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.progressBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _animation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'PREMIUM NUTRITION GUIDE',
                  style: AppTextStyles.overline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
