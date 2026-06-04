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
        final done = completion['isCompleted'] == true ||
            completion['IsCompleted'] == true;
        if (done) _sessionComplete = true;
        return done;
      }
    } catch (_) {
      // Fall through to profile heuristic below.
    }

    try {
      final profile = await _profileRepository
          .getMyProfile()
          .timeout(const Duration(seconds: 12));
      return HealthProfileValues.isHealthBaselineComplete(profile);
    } catch (_) {
      // API unreachable — allow Main so user is not stuck; Home still works offline-ish.
      return true;
    }
  }
}
