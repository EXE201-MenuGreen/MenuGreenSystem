import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.password,
  });

  final String email;
  final String? password;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập OTP gồm 6 ký tự')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepo.verifyOtp(widget.email, otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final password = widget.password?.trim() ?? '';
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực thành công. Vui lòng đăng nhập để tiếp tục.'),
            backgroundColor: Colors.orange,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.popUntil(context, (route) => route.isFirst);
        });
        return;
      }

      final loginResult = await _authRepo.login(widget.email, password);
      if (!mounted) return;

      if (loginResult['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginResult['message'] ?? 'Đăng nhập thất bại sau khi xác thực OTP'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực OTP thành công!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'OTP không hợp lệ'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Xác thực OTP',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: 12),
              Text(
                'Nhập mã OTP đã được gửi về email:\n${widget.email}',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _otpController,
                label: 'OTP (6 chữ số)',
                hintText: 'VD: 123456',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(
                      text: 'Xác thực',
                      onPressed: _handleVerify,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

