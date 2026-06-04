import '../../profile/repositories/profile_repository.dart';

/// Central gate: user must finish onboarding baseline before main app.
class OnboardingGate {
  OnboardingGate({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  final ProfileRepository _profileRepository;

  Future<bool> isOnboardingComplete() async {
    final completion = await _profileRepository.getMyCompletion();
    if (completion == null) return false;
    return completion['isCompleted'] == true || completion['IsCompleted'] == true;
  }
}
