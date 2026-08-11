import 'package:firebase_storage/firebase_storage.dart';

String localizeFirebaseStorageError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'object-not-found':
        return 'Không tìm thấy file trên Firebase Storage. '
            'Hãy vào Firebase Console → Storage → Get started, '
            'bật Storage và kiểm tra cấu hình Rules.';
      case 'unauthorized':
      case 'permission-denied':
        return 'Không có quyền upload. Kiểm tra Firebase Storage Rules '
            'cho đúng thư mục đang tải ảnh lên.';
      case 'unauthenticated':
        return 'Chưa xác thực Firebase. Với demo, dùng Rules cho phép write tạm thời.';
      case 'canceled':
        return 'Upload đã bị hủy.';
      case 'unknown':
        return 'Lỗi Firebase Storage: ${error.message ?? error.code}';
      default:
        return 'Lỗi Firebase Storage (${error.code}): ${error.message ?? "Vui lòng thử lại."}';
    }
  }

  final text = error.toString();
  if (text.contains('object-not-found')) {
    return 'Upload thất bại: Storage chưa sẵn sàng hoặc file chưa được tạo. '
        'Bật Storage trên Firebase Console và thử lại.';
  }
  return 'Upload thất bại: $error';
}
