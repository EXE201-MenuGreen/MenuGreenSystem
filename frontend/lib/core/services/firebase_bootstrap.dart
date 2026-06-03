import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'firebase_storage_service.dart';

class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!FirebaseStorageService.isSupported) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Firebase.initializeApp');
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }
}
