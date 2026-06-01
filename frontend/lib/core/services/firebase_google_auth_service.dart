import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

/// Web client ID from google-services.json (client_type 3) — used for idToken on Android.
const _kGoogleWebClientId =
    '709315528907-sd0et9a55hqo9ksitbn3lg3jpvhmiqol.apps.googleusercontent.com';

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: _kGoogleWebClientId,
            );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  static bool get isSupported => FirebaseBootstrap.isInitialized;

  Future<String> signInAndGetIdToken() async {
    if (!isSupported) {
      throw Exception(
        'Firebase chưa khởi tạo. Chạy app trên Android/iOS emulator hoặc thiết bị.',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Đăng nhập Google đã bị hủy.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Không lấy được Firebase ID token.');
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (!isSupported) return;
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
