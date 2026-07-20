import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';
import 'firebase_runtime_config.dart';
import 'firebase_storage_service.dart';

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: FirebaseRuntimeConfig.hasGoogleWebClientId
                  ? FirebaseRuntimeConfig.googleWebClientId
                  : null,
            );

  final FirebaseAuth? _authOverride;
  final GoogleSignIn _googleSignIn;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static bool get isSupported => FirebaseStorageService.isSupported;

  Future<String> signInAndGetIdToken() async {
    await FirebaseBootstrap.initialize();
    if (!FirebaseBootstrap.isInitialized) {
      throw Exception(
        'Firebase chua khoi tao. Kiem tra mang hoac cau hinh google-services.json.',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Dang nhap Google da bi huy.');
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      throw Exception(
        'Khong lay duoc Google ID token. Cau hinh '
        'FIREBASE_GOOGLE_WEB_CLIENT_ID cho dung Firebase project.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Khong lay duoc Firebase ID token.');
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (!isSupported || !FirebaseBootstrap.isInitialized) return;
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Firebase Google signOut: $e');
    }
  }
}
