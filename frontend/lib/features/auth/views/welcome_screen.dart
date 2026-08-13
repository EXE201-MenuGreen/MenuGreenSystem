import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/primary_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'MenuGreen',
          style: beVietnamPro(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.textDark),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Image Section (Flexibly scaled, non-scrollable)
            Expanded(
              flex: 4,
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  'assets/images/salad_bowl.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 2. Main Content Section (Fixed 100% inside viewport, zero scrolling)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Two-line Title: Line 1 = Ăn ngon hơn,, Line 2 = Sống khỏe mỗi ngày
                    Text(
                      'Ăn ngon hơn,\nSống khỏe mỗi ngày',
                      textAlign: TextAlign.center,
                      style: beVietnamPro(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.25,
                      ),
                    ),

                    Text(
                      'Hàng ngàn công thức nấu ăn lành mạnh\nphù hợp với riêng bạn',
                      textAlign: TextAlign.center,
                      style: beVietnamPro(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    Column(
                      children: [
                        PrimaryButton(
                          text: 'Đăng ký',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomOutlineButton(
                          text: 'Đăng nhập',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.energy_savings_leaf_outlined,
                          color: AppColors.textLight,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Khám phá lối sống lành mạnh',
                          style: beVietnamPro(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
