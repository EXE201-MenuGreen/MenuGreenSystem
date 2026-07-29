import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_colors.dart';
import 'core/widgets/connection_status_banner.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/network_status_provider.dart';
import 'core/services/push_notification_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/splash/views/splash_screen.dart';
import 'features/meal_plan/providers/meal_plan_provider.dart';
import 'features/coach/providers/coach_badge_provider.dart';
import 'features/coach_pt/providers/coach_report_provider.dart';
import 'features/vietnam_local/providers/daily_starter_provider.dart';
import 'features/vietnam_local/providers/gym_goals_provider.dart';
import 'features/vietnam_local/providers/safety_provider.dart';
import 'features/vietnam_local/providers/local_preferences_provider.dart';
import 'features/vietnam_local/providers/planned_vs_actual_provider.dart';
import 'features/vietnam_local/providers/food_capture_provider.dart';
import 'features/vietnam_local/providers/ingredient_substitution_provider.dart';
import 'features/discover/providers/favorite_food_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Global pending notification to route after splash screen (terminated state).
RemoteMessage? _pendingInitialNotification;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load .env.local first (for local development overrides)
    // Then load .env as fallback/defaults
    await dotenv.load(fileName: '.env.local', isOptional: true);
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Cảnh báo: Không thể nạp tệp .env: $e');
  }

  // Register background handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Check if app was launched from a notification (terminated state).
  await FirebaseBootstrap.initialize();
  _pendingInitialNotification = await FirebaseMessaging.instance
      .getInitialMessage();

  runApp(const MyApp());

  // Sau frame dau - giam "Skipped N frames" luc startup.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(FirebaseBootstrap.initialize());
  });
}

RemoteMessage? getPendingInitialNotification() => _pendingInitialNotification;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkStatusProvider()..start()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => CoachBadgeProvider()),
        ChangeNotifierProvider(create: (_) => CoachReportProvider()),
        ChangeNotifierProvider(create: (_) => PushNotificationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DailyStarterProvider()),
        ChangeNotifierProvider(create: (_) => GymGoalsProvider()),
        ChangeNotifierProvider(create: (_) => SafetyProvider()),
        ChangeNotifierProvider(create: (_) => LocalPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => PlannedVsActualProvider()),
        ChangeNotifierProvider(create: (_) => FoodCaptureProvider()),
        ChangeNotifierProvider(create: (_) => IngredientSubstitutionProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteFoodProvider()),
      ],
      child: MaterialApp(
        title: 'MenuGreen',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return ConnectionStatusBanner(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
