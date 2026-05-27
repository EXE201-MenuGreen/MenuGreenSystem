import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get baseUrl {
    // Backend is configured to run on http://localhost:5000 (see backend/MenuGreen.API/Properties/launchSettings.json)
    if (kIsWeb) return 'http://localhost:5000/api';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator -> host machine loopback
        return 'http://10.0.2.2:5000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000/api';
    }
  }

  static String get login => '$baseUrl/Auth/login';
  static String get register => '$baseUrl/Auth/register';
  static String get verifyOtp => '$baseUrl/Auth/verify-otp';
  static String get refreshToken => '$baseUrl/Auth/refresh-token';
  static String get logout => '$baseUrl/Auth/logout';
  static String get getProfile => '$baseUrl/Profile/me';
  static String get updateAvatar => '$baseUrl/Profile/me/avatar';
  static String get removeAvatar => '$baseUrl/Profile/me/avatar';
  static String get changePassword => '$baseUrl/User/change-password';
}
