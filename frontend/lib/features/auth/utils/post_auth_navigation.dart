import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/health_profile_values.dart';
import '../../main/views/main_screen.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../profile/repositories/profile_repository.dart';

/// After login / Google sign-in / app resume with token: go to onboarding or home.
Future<void> navigateAfterAuthenticated(BuildContext context) async {
  Map<String, dynamic>? profile;
  try {
    profile = await ProfileRepository()
        .getMyProfile()
        .timeout(const Duration(seconds: 18));
  } catch (_) {
    profile = null;
  }
  if (!context.mounted) return;

  final Widget destination;
  if (profile != null && !HealthProfileValues.isHealthBaselineComplete(profile)) {
    destination = const OnboardingScreen();
  } else {
    destination = const MainScreen();
  }

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => destination),
    (_) => false,
  );
}
