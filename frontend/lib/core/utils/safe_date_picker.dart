import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mở date picker sau khi ẩn bàn phím — tránh đơ UI trên Android emulator
/// (xung đột IME inset animation với dialog chọn ngày).
Future<DateTime?> showSafeDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  Locale locale = const Locale('vi', 'VN'),
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await WidgetsBinding.instance.endOfFrame;
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  if (!context.mounted) return null;

  return showDatePicker(
    context: context,
    initialDate: initialDate.clamp(firstDate, lastDate),
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    locale: locale,
    useRootNavigator: true,
    barrierDismissible: true,
  );
}

extension _DateTimeClamp on DateTime {
  DateTime clamp(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}
