import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';
import 'firebase_storage_service.dart';

/// Web client ID from google-services.json (client_type 3) — used for idToken on Android.
const _kGoogleWebClientId =
    '709315528907-sd0et9a55hqo9ksitbn3lg3jpvhmiqol.apps.googleusercontent.com';

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: _kGoogleWebClientId,
            );

  final FirebaseAuth? _authOverride;
  final GoogleSignIn _googleSignIn;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static bool get isSupported => FirebaseStorageService.isSupported;

  Future<String> signInAndGetIdToken() async {
    await FirebaseBootstrap.initialize();
    if (!FirebaseBootstrap.isInitialized) {
      throw Exception(
        'Firebase chưa khởi tạo. Kiểm tra mạng hoặc cấu hình google-services.json.',
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
