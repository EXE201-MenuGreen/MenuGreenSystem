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

