import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/constants/app_colors.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/push_notification_provider.dart';
import 'features/splash/views/splash_screen.dart';
import 'features/meal_plan/providers/meal_plan_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  // Sau frame đầu — giảm "Skipped N frames" lúc startup.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(FirebaseBootstrap.initialize());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => PushNotificationProvider()),
      ],
      child: MaterialApp(
        title: 'MenuGreen',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
