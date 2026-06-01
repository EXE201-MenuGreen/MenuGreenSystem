import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/token_storage.dart';
import '../../auth/utils/post_auth_navigation.dart';
import '../../auth/views/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Simulate initialization time (e.g., 2.5 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
  }

  Future<void> _navigateFromSplash() async {
    final token = await TokenStorage().getAccessToken();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      await navigateAfterAuthenticated(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
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
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
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
                // Title
                const Text(
                  'MenuGreen',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Trợ lý dinh dưỡng thông\nminh',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          
          // Bottom Progress
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    int percentage = (_animation.value * 100).toInt();
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
