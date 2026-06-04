import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'firebase_storage_service.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static bool get isInitialized =>
      _initialized || Firebase.apps.isNotEmpty;

  static Future<void> initialize() {
    if (isInitialized) {
      _initialized = true;
      return Future.value();
    }
    if (!FirebaseStorageService.isSupported) return Future.value();
    return _initFuture ??= _doInitialize();
  }

  static Future<void> _doInitialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw TimeoutException('Firebase.initializeApp');
          },
        );
      }
      _initialized = true;
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
      _initFuture = null;
    }
  }
}
