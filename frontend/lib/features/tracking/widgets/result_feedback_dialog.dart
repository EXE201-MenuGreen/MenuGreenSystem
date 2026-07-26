import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Dialog hiển thị kết quả thao tác (thành công / thất bại).
///
/// - Hiện ở root Navigator nên không bị Sheet/Dialog che.
/// - Success: icon ✓, màu xanh, nút "Đóng" hoặc "Mở kế hoạch".
/// - Error: icon ✗, màu đỏ, nút "Thử lại" hoặc "Đóng".
///
/// [title]        — Tiêu đề ngắn gọn
/// [message]     — Nội dung chi tiết
/// [isSuccess]   — true = thành công, false = lỗi
/// [actionLabel] — Nhãn nút chính (null = dùng mặc định)
/// [onAction]    — Callback khi tap nút chính (nullable)
Future<void> showResultFeedbackDialog(
  BuildContext context, {
  required String title,
  required String message,
  required bool isSuccess,
  String? actionLabel,
  VoidCallback? onAction,
  String? cancelLabel,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => _ResultFeedbackDialog(
      title: title,
      message: message,
      isSuccess: isSuccess,
      actionLabel: actionLabel,
      onAction: onAction,
      cancelLabel: cancelLabel,
    ),
  );
}

class _ResultFeedbackDialog extends StatelessWidget {
  const _ResultFeedbackDialog({
    required this.title,
    required this.message,
    required this.isSuccess,
    this.actionLabel,
    this.onAction,
    this.cancelLabel,
  });

  final String title;
  final String message;
  final bool isSuccess;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.primary : Colors.redAccent;
    final bgColor = color.withValues(alpha: 0.08);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.close_rounded,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                if (cancelLabel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(cancelLabel!),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      onAction?.call();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      actionLabel ?? (isSuccess ? 'Đóng' : 'Đóng'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
