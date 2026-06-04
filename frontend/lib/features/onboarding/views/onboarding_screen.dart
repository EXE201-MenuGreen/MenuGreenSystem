import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../main/views/main_screen.dart';
import '../../profile/repositories/profile_repository.dart';
import '../repositories/health_profile_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/user_ai_profile_repository.dart';
import 'steps/basic_info_step.dart';
import 'steps/user_type_step.dart';
import 'steps/preferences_step.dart';
import 'steps/allergies_step.dart';
import 'steps/calorie_goal_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _profileRepository = ProfileRepository();
  final _healthProfileRepository = HealthProfileRepository();
  final _userAiProfileRepository = UserAiProfileRepository();
  final _onboardingRepository = OnboardingRepository();

  int _currentIndex = 0;
  bool _finishing = false;

  String? _fullName;
  String? _gender;
  DateTime? _dateOfBirth;
  double? _heightCm;
  double? _weightKg;
  double? _bodyFatPercent;
  String _activityLevel = 'sedentary';
  String _goal = 'maintain weight';
  int? _targetCalories;

  static const _stepCount = 5;

  final List<String> _titles = [
    'Thiết lập hồ sơ',
    'Chọn loại người dùng',
    'Sở thích ăn uống',
    '',
    'Mục tiêu Calo',
  ];

  void _nextPage() {
    if (_currentIndex < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleBasicInfoNext({
    required String fullName,
    required String gender,
    DateTime? dateOfBirth,
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
    required String activityLevel,
    required String goal,
  }) async {
    final profilePayload = <String, dynamic>{
      'fullName': fullName,
      'gender': gender,
      if (dateOfBirth != null)
        'dateOfBirth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
    };

    final profileResult = await _profileRepository.updateMyProfile(profilePayload);
    if (profileResult == null) {
      _showMessage('Không lưu được hồ sơ cá nhân. Vui lòng thử lại.', isError: true);
      return;
    }

    final healthResult = await _healthProfileRepository.updateMyHealthProfile(
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      activityLevel: activityLevel,
      goal: goal,
    );
    if (!healthResult.success) {
      _showMessage(healthResult.message, isError: true);
      return;
    }

    final target = healthResult.data?['targetCalories'] ?? healthResult.data?['TargetCalories'];
    final parsedTarget = target is num ? target.toInt() : int.tryParse('$target');

    setState(() {
      _fullName = fullName;
      _gender = gender;
      _dateOfBirth = dateOfBirth;
      _heightCm = heightCm;
      _weightKg = weightKg;
      _bodyFatPercent = bodyFatPercent;
      _activityLevel = activityLevel;
      _goal = goal;
      _targetCalories = parsedTarget ?? 2500;
    });

    _nextPage();
  }

  Future<void> _handleUserTypeNext(String eatingPattern) async {
    final result = await _userAiProfileRepository.upsert(eatingPattern: eatingPattern);
    if (!result.success) {
      _showMessage(result.message, isError: true);
      return;
    }
    _nextPage();
  }

  Future<void> _handlePreferencesNext(List<String> selectedPrefs) async {
    final result = await _userAiProfileRepository.upsert(
      preferencesJson: UserAiProfileRepository.buildPreferencesJson(selectedPrefs),
    );
    if (!result.success) {
      _showMessage(result.message, isError: true);
      return;
    }
    _nextPage();
  }

  Future<void> _handleFinish(int targetCalories) async {
    if (_heightCm == null || _weightKg == null) {
      _showMessage('Thiếu dữ liệu cơ bản. Vui lòng nhập lại.', isError: true);
      _pageController.jumpToPage(0);
      return;
    }

    setState(() => _finishing = true);

    final healthResult = await _healthProfileRepository.updateMyHealthProfile(
      heightCm: _heightCm!,
      weightKg: _weightKg!,
      bodyFatPercent: _bodyFatPercent,
      activityLevel: _activityLevel,
      goal: _goal,
      targetCalories: targetCalories,
    );
    if (!healthResult.success) {
      if (mounted) setState(() => _finishing = false);
      _showMessage(healthResult.message, isError: true);
      return;
    }

    final completeResult = await _onboardingRepository.complete(
      targetCalories: targetCalories,
    );
    if (!mounted) return;
    setState(() => _finishing = false);

    if (!completeResult.success) {
      _showMessage(completeResult.message, isError: true);
      return;
    }

    final completion = completeResult.data?['completion'] ?? completeResult.data?['Completion'];
    final isCompleted = completion is Map &&
        (completion['isCompleted'] == true || completion['IsCompleted'] == true);

    if (!isCompleted) {
      _showMessage('Vui lòng hoàn tất các bước còn thiếu trước khi vào ứng dụng.', isError: true);
      return;
    }

    _showMessage('Thiết lập hoàn tất!');
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BƯỚC ${_currentIndex + 1}/$_stepCount',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _stepCount,
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  BasicInfoStep(
                    onNext: _handleBasicInfoNext,
                    initialFullName: _fullName,
                    initialGender: _gender,
                    initialDateOfBirth: _dateOfBirth,
                    initialHeightCm: _heightCm,
                    initialWeightKg: _weightKg,
                    initialBodyFatPercent: _bodyFatPercent,
                    initialActivityLevel: _activityLevel,
                    initialGoal: _goal,
                  ),
                  UserTypeStep(onNext: _handleUserTypeNext),
                  PreferencesStep(onNext: _handlePreferencesNext),
                  AllergiesStep(
                    onNext: _nextPage,
                    userAiProfileRepository: _userAiProfileRepository,
                  ),
                  CalorieGoalStep(
                    onFinish: _finishing ? (_) async {} : _handleFinish,
                    initialCalories: _targetCalories ?? 2500,
                    heightCm: _heightCm,
                    weightKg: _weightKg,
                    activityLevel: _activityLevel,
                    goal: _goal,
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
