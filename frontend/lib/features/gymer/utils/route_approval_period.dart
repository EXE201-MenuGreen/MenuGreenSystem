class RouteApprovalPeriod {
  const RouteApprovalPeriod._();

  static String normalizeScope({
    required String requestType,
    String? configurationScope,
  }) {
    if (requestType.trim().toLowerCase() == 'weeklyreport') return 'week';

    return switch (configurationScope?.trim().toLowerCase()) {
      'day' || 'daily' => 'day',
      'week' || 'weekly' => 'week',
      'month' || 'monthly' => 'month',
      _ => requestType.trim().toLowerCase() == 'routeapproval' ? 'day' : 'week',
    };
  }

  static String scopeLabel(String scope) => switch (scope) {
    'day' => 'Ngày',
    'month' => 'Tháng',
    _ => 'Tuần',
  };

  static String periodLabel({
    required String scope,
    required DateTime start,
    DateTime? end,
  }) {
    if (scope == 'month') {
      return 'Tháng ${start.month.toString().padLeft(2, '0')}/${start.year}';
    }

    final startLabel = formatDate(start);
    if (scope == 'week' && end != null && !_sameDate(start, end)) {
      return 'Tuần $startLabel - ${formatDate(end)}';
    }
    return '${scopeLabel(scope)} $startLabel';
  }

  static String durationLabel(String scope) => switch (scope) {
    'day' => '1 ngày',
    'month' => '1 tháng',
    _ => '1 tuần',
  };

  static String titleDateLabel(String scope, DateTime start) {
    if (scope == 'month') {
      return '${start.month.toString().padLeft(2, '0')}/${start.year}';
    }
    return formatDate(start);
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
