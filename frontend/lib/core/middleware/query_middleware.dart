class QueryMiddleware {
  QueryMiddleware._();

  static String? normalizeKeyword(String? value) {
    final normalized = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static int? normalizeInt(int? value, {int? min, int? max}) {
    if (value == null) return null;
    if (min != null && value < min) return min;
    if (max != null && value > max) return max;
    return value;
  }

  static String? normalizeOption(
    String? value, {
    Set<String>? allowed,
    String? fallback,
  }) {
    final normalized = normalizeKeyword(value)?.toLowerCase();
    if (normalized == null) return fallback;
    if (allowed == null || allowed.contains(normalized)) return normalized;
    return fallback;
  }

  static String buildUrl(String baseUrl, Map<String, Object?> params) {
    final uri = Uri.parse(baseUrl);
    final normalized = normalizeParams(params);

    if (normalized.isEmpty) return baseUrl;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...normalized,
    }).toString();
  }

  static String buildQuery(Map<String, Object?> params) {
    final normalized = normalizeParams(params);
    if (normalized.isEmpty) return '';
    return normalized.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  static Map<String, String> normalizeParams(Map<String, Object?> params) {
    final normalized = <String, String>{};

    for (final entry in params.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String) {
        final text = normalizeKeyword(value);
        if (text != null) normalized[entry.key] = text;
      } else if (value is bool || value is num) {
        normalized[entry.key] = value.toString();
      } else if (value is DateTime) {
        normalized[entry.key] = value.toUtc().toIso8601String();
      }
    }

    return normalized;
  }
}
