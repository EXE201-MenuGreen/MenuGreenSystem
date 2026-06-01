import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'steps/basic_info_step.dart';
import 'steps/user_type_step.dart';
import 'steps/preferences_step.dart';
import 'steps/allergies_step.dart';
import 'steps/calorie_goal_step.dart';
import '../../main/views/main_screen.dart';
import '../repositories/health_profile_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final HealthProfileRepository _healthProfileRepository = HealthProfileRepository();
  int _currentIndex = 0;
  bool _finishing = false;
  double? _heightCm;
  double? _weightKg;
  double? _bodyFatPercent;
  String _activityLevel = 'sedentary';
  String _goal = 'maintain weight';

  final List<String> _titles = [
    'Thiết lập sức khỏe',
    'Chọn loại người dùng',
    'Sở thích ăn uống',
    '', // Dị ứng ko có title appbar
    'Mục tiêu Calo'
  ];

  void _nextPage() {
    if (_currentIndex < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Done onboarding
      // Navigator.pushReplacement(...) -> Go to Home
    }
  }

  Future<void> _handleBasicInfoNext({
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
    required String activityLevel,
    required String goal,
  }) async {
    _heightCm = heightCm;
    _weightKg = weightKg;
    _bodyFatPercent = bodyFatPercent;
    _activityLevel = activityLevel;
    _goal = goal;
    _nextPage();
  }

  Future<void> _handleFinish(int targetCalories) async {
    if (_heightCm == null || _weightKg == null) {
      _showMessage('Thiếu dữ liệu cơ bản. Vui lòng nhập lại.', isError: true);
      _pageController.jumpToPage(0);
      return;
    }

    setState(() => _finishing = true);
    final result = await _healthProfileRepository.updateMyHealthProfile(
      heightCm: _heightCm!,
      weightKg: _weightKg!,
      bodyFatPercent: _bodyFatPercent,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    if (!mounted) return;
    setState(() => _finishing = false);

    if (!result.success) {
      _showMessage(result.message, isError: true);
      return;
    }

    // targetCalories currently calculated by backend and returned from profile update;
    // we keep this value to support future custom-calorie endpoint.
    if (targetCalories > 0) {
      _showMessage('Thiết lập hoàn tất!');
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
      ),
    );
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: _previousPage,
        ),
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentIndex != 0 && _currentIndex != 4)
            TextButton(
              onPressed: _nextPage,
              child: const Text('Bỏ qua', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            if (_currentIndex > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BƯỚC ${_currentIndex + 1}/5',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / 5,
                      backgroundColor: AppColors.progressBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  BasicInfoStep(
                    onNext: _handleBasicInfoNext,
                    initialHeightCm: _heightCm,
                    initialWeightKg: _weightKg,
                    initialBodyFatPercent: _bodyFatPercent,
                    initialActivityLevel: _activityLevel,
                    initialGoal: _goal,
                  ),
                  UserTypeStep(onNext: _nextPage),
                  PreferencesStep(onNext: _nextPage),
                  AllergiesStep(onNext: _nextPage),
                  CalorieGoalStep(
                    onFinish: _finishing ? (_) async {} : _handleFinish,
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
