import 'package:flutter/foundation.dart';

import '../../../core/constants/health_profile_values.dart';
import '../../profile/repositories/profile_repository.dart';

/// Central gate: user must finish onboarding baseline before main app.
class OnboardingGate {
  OnboardingGate({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  final ProfileRepository _profileRepository;

  /// Set after successful [Onboarding/complete] in this app session — avoids redirect loop.
  static void markSessionComplete() {
    _sessionComplete = true;
  }

  static void clearSessionComplete() {
    _sessionComplete = null;
  }

  static bool? _sessionComplete;

  Future<bool> isOnboardingComplete() async {
    if (_sessionComplete == true) return true;

    try {
      final completion = await _profileRepository
          .getMyCompletion()
          .timeout(const Duration(seconds: 12));
      if (completion != null) {
        final isCompleted = completion['isCompleted'] ?? completion['IsCompleted'];
        final missingSteps = completion['missingSteps'] ?? completion['MissingSteps'];
        final nextStep = completion['nextStep'] ?? completion['NextStep'];
        debugPrint('[OnboardingGate] completion=$completion');
        final done = isCompleted == true;
        if (done) _sessionComplete = true;
        if (!done) {
          debugPrint(
            '[OnboardingGate] Missing steps: $missingSteps | NextStep: $nextStep',
          );
        }
        return done;
      }
    } catch (e) {
      debugPrint('[OnboardingGate] completion API failed: $e');
    }

    try {
      final profile = await _profileRepository
          .getMyProfile()
          .timeout(const Duration(seconds: 12));
      if (profile == null) {
        debugPrint('[OnboardingGate] Profile API returned null — allowing MainScreen');
        return true;
      }
      return _isProfileOnboardingComplete(profile);
    } catch (e) {
      debugPrint('[OnboardingGate] profile API failed: $e — allowing MainScreen');
      return true;
    }
  }

  static bool _isProfileOnboardingComplete(Map<String, dynamic>? profile) {
    if (profile == null) {
      debugPrint('[OnboardingGate] Profile payload is null');
      return false;
    }

    // Check basic profile info
    final fullName = (profile['fullName'] ?? profile['FullName'])?.toString().trim() ?? '';
    final gender = (profile['gender'] ?? profile['Gender'])?.toString().trim() ?? '';
    if (fullName.isEmpty) {
      debugPrint('[OnboardingGate] Missing: fullName is empty');
      return false;
    }
    if (gender.isEmpty) {
      debugPrint('[OnboardingGate] Missing: gender is empty');
      return false;
    }

    // Check health baseline
    final hasHealthBaseline = HealthProfileValues.isHealthBaselineComplete(profile);
    if (!hasHealthBaseline) {
      final height = profile['heightCm'] ?? profile['HeightCm'];
      final weight = profile['weightKg'] ?? profile['WeightKg'];
      debugPrint('[OnboardingGate] Health baseline incomplete: height=$height, weight=$weight');
      return false;
    }

    // Check targetCalories - allow null if height/weight available (can be calculated)
    final target = profile['targetCalories'] ?? profile['TargetCalories'];
    final targetCalories = target is num
        ? target.toInt()
        : int.tryParse(target?.toString() ?? '');
    
    // If targetCalories is missing or invalid, calculate from height/weight if available
    if (targetCalories == null || targetCalories < 800) {
      final height = _parsePositiveNum(profile['heightCm'] ?? profile['HeightCm']);
      final weight = _parsePositiveNum(profile['weightKg'] ?? profile['WeightKg']);
      
      if (height != null && weight != null && weight > 0) {
        // Use minimum reasonable calories (BMR for small female ~1200, add activity)
        debugPrint('[OnboardingGate] targetCalories missing/invalid ($targetCalories), '
            'but height/weight available - using fallback 1500');
        return true;
      }
      
      debugPrint('[OnboardingGate] Missing: targetCalories ($targetCalories) and cannot fallback');
      return false;
    }

    return true;
  }

  static double? _parsePositiveNum(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toDouble() : double.tryParse(value.toString());
  }
}
