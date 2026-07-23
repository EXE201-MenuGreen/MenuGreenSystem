const reminderTitleMaxLength = 255;
const reminderBodyMaxLength = 1000;
const reminderMinimumLeadTime = Duration(minutes: 1);

class ReminderValidationResult {
  const ReminderValidationResult({
    this.titleError,
    this.bodyError,
    this.scheduleError,
  });

  final String? titleError;
  final String? bodyError;
  final String? scheduleError;

  bool get isValid =>
      titleError == null && bodyError == null && scheduleError == null;

  String? get firstError => titleError ?? bodyError ?? scheduleError;
}

ReminderValidationResult validateReminderInput({
  required String title,
  required String body,
  required DateTime scheduledAt,
  required DateTime now,
}) {
  final cleanTitle = title.trim();
  final cleanBody = body.trim();

  String? titleError;
  if (cleanTitle.isEmpty) {
    titleError = 'Vui lòng nhập tiêu đề để bạn nhận biết nhắc nhở này.';
  } else if (cleanTitle.length > reminderTitleMaxLength) {
    titleError = 'Tiêu đề không được vượt quá $reminderTitleMaxLength ký tự.';
  }

  String? bodyError;
  if (cleanBody.isEmpty) {
    bodyError = 'Vui lòng nhập nội dung cần được nhắc.';
  } else if (cleanBody.length > reminderBodyMaxLength) {
    bodyError = 'Nội dung không được vượt quá $reminderBodyMaxLength ký tự.';
  }

  String? scheduleError;
  final today = DateTime(now.year, now.month, now.day);
  final selectedDay = DateTime(
    scheduledAt.year,
    scheduledAt.month,
    scheduledAt.day,
  );
  if (selectedDay.isBefore(today)) {
    scheduleError =
        'Ngày nhắc đã qua. Vui lòng chọn hôm nay hoặc một ngày trong tương lai.';
  } else if (!scheduledAt.isAfter(now)) {
    scheduleError =
        'Giờ nhắc đã qua. Vui lòng chọn một giờ sau thời điểm hiện tại.';
  } else if (scheduledAt.isBefore(now.add(reminderMinimumLeadTime))) {
    scheduleError =
        'Thời gian nhắc quá gần. Vui lòng chọn sau thời điểm hiện tại ít nhất 1 phút.';
  }

  return ReminderValidationResult(
    titleError: titleError,
    bodyError: bodyError,
    scheduleError: scheduleError,
  );
}
