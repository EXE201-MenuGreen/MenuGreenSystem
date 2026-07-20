class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig._();

  // Override bằng:
  // flutter run --dart-define=FIREBASE_GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'FIREBASE_GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '709315528907-sd0et9a55hqo9ksitbn3lg3jpvhmiqol.apps.googleusercontent.com',
  );

  static bool get hasGoogleWebClientId =>
      googleWebClientId.trim().isNotEmpty;
}
