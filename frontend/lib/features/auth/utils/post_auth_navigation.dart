import 'package:flutter/material.dart';

import '../../../core/constants/health_profile_values.dart';
import '../../main/views/main_screen.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../profile/repositories/profile_repository.dart';

/// After login / Google sign-in / app resume with token: go to onboarding or home.
Future<void> navigateAfterAuthenticated(BuildContext context) async {
  final profile = await ProfileRepository().getMyProfile();
  if (!context.mounted) return;

  final destination = HealthProfileValues.isHealthBaselineComplete(profile)
      ? const MainScreen()
      : const OnboardingScreen();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => destination),
    (_) => false,
  );
}
