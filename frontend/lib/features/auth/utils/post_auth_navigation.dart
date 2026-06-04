import 'dart:async';

import 'package:flutter/material.dart';

import '../../main/views/main_screen.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../onboarding/views/onboarding_screen.dart';

/// After login / Google sign-in / app resume with token: go to onboarding or home.
Future<void> navigateAfterAuthenticated(BuildContext context) async {
  final gate = OnboardingGate();
  bool complete = false;
  try {
    complete = await gate.isOnboardingComplete().timeout(const Duration(seconds: 18));
  } catch (_) {
    complete = false;
  }
  if (!context.mounted) return;

  final Widget destination = complete ? const MainScreen() : const OnboardingScreen();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => destination),
    (_) => false,
  );
}
