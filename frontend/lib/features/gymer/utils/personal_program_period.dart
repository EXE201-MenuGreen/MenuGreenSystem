class PersonalProgramPeriod {
  const PersonalProgramPeriod._();

  static String value(Map<String, dynamic> program, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    return (program[key] ?? program[pascal] ?? '').toString();
  }

  static bool isDaily(Map<String, dynamic> program) {
    final planType = value(program, 'planType').trim().toLowerCase();
    if (planType == 'daily') return true;
    if (planType.isNotEmpty) return false;

    final start = value(program, 'startDate');
    final end = value(program, 'endDate');
    return start.isNotEmpty && start == end;
  }

  static String periodLabel(Map<String, dynamic> program) {
    final planType = value(program, 'planType').trim().toLowerCase();
    final startRaw = value(program, 'startDate').isNotEmpty
        ? value(program, 'startDate')
        : value(program, 'weekStartDate');
    final endRaw = value(program, 'endDate');
    final start = formatDate(startRaw);
    final end = formatDate(endRaw);

    if (isDaily(program)) {
      return start.isEmpty ? 'Theo ngày' : 'Ngày $start';
    }
    if (planType == 'weekly') {
      if (start.isEmpty) return 'Theo tuần';
      return end.isEmpty || end == start ? 'Tuần $start' : 'Tuần $start - $end';
    }
    if (planType == 'monthly') {
      if (start.isEmpty) return 'Theo tháng';
      return end.isEmpty || end == start
          ? 'Tháng $start'
          : 'Từ $start đến $end';
    }
    if (start.isNotEmpty && end.isNotEmpty && start != end) {
      return 'Từ $start đến $end';
    }
    return start.isEmpty ? '' : 'Ngày $start';
  }

  static String durationLabel(Map<String, dynamic> program) {
    if (isDaily(program)) return '1 ngày';

    final planType = value(program, 'planType').trim().toLowerCase();
    final start = DateTime.tryParse(value(program, 'startDate'));
    final end = DateTime.tryParse(value(program, 'endDate'));
    if (planType == 'monthly' && start != null && end != null) {
      final days = end.difference(start).inDays + 1;
      if (days > 0) return '$days ngày';
    }

    final weeks = int.tryParse(value(program, 'durationWeeks'));
    return weeks != null && weeks > 0 ? '$weeks tuần' : '';
  }

  static String formatDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }
}
