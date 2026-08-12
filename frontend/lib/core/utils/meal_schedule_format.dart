String defaultMealScheduledTime(String mealType) {
  return switch (mealType.trim().toLowerCase()) {
    'breakfast' => '07:30',
    'lunch' => '12:00',
    'dinner' => '18:30',
    _ => '15:00',
  };
}

String mealScheduledTimeLabel(String? raw, {required String mealType}) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return defaultMealScheduledTime(mealType);

  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) return value;
  return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
}

String mealPlannedDateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
