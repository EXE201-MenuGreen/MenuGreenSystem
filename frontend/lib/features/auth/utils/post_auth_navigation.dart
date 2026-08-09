import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/main_screen.dart';
import '../../coach/views/coach_main_screen.dart';
import '../../coach/views/coach_application_screen.dart';
import '../../coach/views/coach_application_status_screen.dart';
import '../../coach/repositories/coach_application_repository.dart';
import '../../onboarding/utils/onboarding_gate.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../../core/services/push_notification_provider.dart';

/// After login / Google sign-in / app resume with token: go to onboarding or home.
Future<void> navigateAfterAuthenticated(BuildContext context) async {
  final gate = OnboardingGate();
  bool complete = false;
  try {
    complete = await gate.isOnboardingComplete().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {
    complete = true; // Fallback to main screen on slow network
  }
  if (!context.mounted) return;

  // Register FCM token asynchronously in background — DO NOT block login UI transition
  unawaited(_registerPushToken(context));

  if (!context.mounted) return;

  // Determine destination based on role
  Widget destination;
  if (!complete) {
    destination = const OnboardingScreen();
  } else {
    // Check role — Coach gets PT workspace
    try {
      final profile = await ProfileRepository().getMyProfile().timeout(
        const Duration(seconds: 4),
      );
      final role = (profile?['role'] ?? '').toString().toLowerCase();
      if (role == 'coach') {
        try {
          final application = await CoachApplicationRepository()
              .getMine()
              .timeout(const Duration(seconds: 5));
          final status = (application['applicationStatus'] ?? 'Draft')
              .toString()
              .toLowerCase();
          if (status == 'approved') {
            destination = const CoachMainScreen();
          } else if (status == 'draft') {
            destination = CoachApplicationScreen(initialData: application);
          } else {
            destination = CoachApplicationStatusScreen(
              initialData: application,
            );
          }
        } catch (_) {
          destination = const CoachApplicationScreen();
        }
      } else {
        destination = const MainScreen();
      }
    } catch (_) {
      destination = const MainScreen();
    }
  }

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
