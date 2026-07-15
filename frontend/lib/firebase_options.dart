// Generated from android/app/google-services.json (project: menugreen-9fb5b).
// Run `flutterfire configure` to regenerate for more platforms.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase chưa cấu hình cho Web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Thêm app iOS trên Firebase Console rồi chạy flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'Firebase Storage chỉ hỗ trợ upload trên Android/iOS. Chạy app trên emulator/thiết bị Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAuRO9XaVnsEfdsadYxOoTUIp4G21-8qWs',
    appId: '1:709315528907:android:1a896858d0654a9454b34e',
    messagingSenderId: '709315528907',
    projectId: 'menugreen-9fb5b',
    storageBucket: 'menugreen-9fb5b.firebasestorage.app',
  );
}
