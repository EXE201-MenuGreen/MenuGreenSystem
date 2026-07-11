import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/main_screen.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../../core/services/push_notification_provider.dart';

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

  // Register FCM token with backend after successful login
  await _registerPushToken(context);

  if (!context.mounted) return;

  final Widget destination = complete ? const MainScreen() : const OnboardingScreen();

  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => destination),
    (_) => false,
  );
}

Future<void> _registerPushToken(BuildContext context) async {
  try {
    final provider = context.read<PushNotificationProvider>();
    await provider.initialize(context);
    await provider.registerToken();
  } catch (e) {
    debugPrint('[PostAuthNavigation] Failed to register push token: $e');
  }
}
