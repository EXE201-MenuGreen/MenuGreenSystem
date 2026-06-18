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
      return _isProfileOnboardingComplete(profile);
    } catch (e) {
      debugPrint('[OnboardingGate] profile API failed: $e');
      return false;
    }
  }

  static bool _isProfileOnboardingComplete(Map<String, dynamic>? profile) {
    if (profile == null) {
      debugPrint('[OnboardingGate] Profile payload is null');
      return false;
    }

    final fullName = (profile['fullName'] ?? profile['FullName'])?.toString().trim() ?? '';
    final gender = (profile['gender'] ?? profile['Gender'])?.toString().trim() ?? '';
    if (fullName.isEmpty || gender.isEmpty) {
      debugPrint('[OnboardingGate] Missing basic profile: fullName=$fullName, gender=$gender');
      return false;
    }

    final hasHealthBaseline = HealthProfileValues.isHealthBaselineComplete(profile);
    if (!hasHealthBaseline) {
      debugPrint('[OnboardingGate] Health baseline incomplete: height=${profile['heightCm'] ?? profile['HeightCm']}, weight=${profile['weightKg'] ?? profile['WeightKg']}');
      return false;
    }

    final target = profile['targetCalories'] ?? profile['TargetCalories'];
    final targetCalories = target is num
        ? target.toInt()
        : int.tryParse(target?.toString() ?? '');
    if (targetCalories == null || targetCalories < 800) {
      debugPrint('[OnboardingGate] Invalid targetCalories: $targetCalories');
      return false;
    }

    return true;
  }
}
