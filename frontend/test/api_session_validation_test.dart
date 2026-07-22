import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('expired session is cleared when refresh fails', () async {
    final storage = TokenStorage();
    await storage.saveTokens(
      accessToken: _jwt(DateTime.now().subtract(const Duration(hours: 1))),
      refreshToken: 'expired-refresh-token',
    );
    final client = ApiClient(
      tokenStorage: storage,
      httpClient: MockClient((_) async => http.Response('', 401)),
    );

    expect(await client.ensureValidSession(), isFalse);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  test('expired access token is replaced by a valid refreshed session', () async {
    final storage = TokenStorage();
    await storage.saveTokens(
      accessToken: _jwt(DateTime.now().subtract(const Duration(hours: 1))),
      refreshToken: 'valid-refresh-token',
    );
    final refreshedAccess = _jwt(DateTime.now().add(const Duration(hours: 1)));
    final client = ApiClient(
      tokenStorage: storage,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'accessToken': refreshedAccess,
            'refreshToken': 'rotated-refresh-token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    expect(await client.ensureValidSession(), isTrue);
    expect(await storage.getAccessToken(), refreshedAccess);
    expect(await storage.getRefreshToken(), 'rotated-refresh-token');
  });
}

String _jwt(DateTime expiresAt) {
  String encode(Object value) => base64Url
      .encode(utf8.encode(jsonEncode(value)))
      .replaceAll('=', '');

  return '${encode({'alg': 'none', 'typ': 'JWT'})}.'
      '${encode({'exp': expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000})}.'
      'signature';
}
