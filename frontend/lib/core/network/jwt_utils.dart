import 'dart:convert';

class JwtUtils {
  static int? tryGetExpiryEpochSeconds(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;

      final payload = _decodeBase64Url(parts[1]);
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      final exp = decoded['exp'];
      if (exp is int) return exp;
      if (exp is num) return exp.toInt();
      if (exp is String) return int.tryParse(exp);
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? tryGetUserId(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;

      final payload = jsonDecode(_decodeBase64Url(parts[1]));
      if (payload is! Map<String, dynamic>) return null;

      const nameIdClaim =
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';

      final raw = payload[nameIdClaim] ?? payload['sub'] ?? payload['nameid'];
      if (raw == null) return null;
      final id = raw.toString().trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  static String? tryGetEmail(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;

      final payload = jsonDecode(_decodeBase64Url(parts[1]));
      if (payload is! Map<String, dynamic>) return null;

      const emailClaim =
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';

      final raw = payload[emailClaim] ??
          payload['email'] ??
          payload['Email'];
      if (raw == null) return null;
      final email = raw.toString().trim();
      return email.isEmpty ? null : email;
    } catch (_) {
      return null;
    }
  }

  static String _decodeBase64Url(String input) {
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 0:
        break;
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
      default:
        // Invalid length
        return '';
    }
    return utf8.decode(base64Decode(normalized));
  }
}

