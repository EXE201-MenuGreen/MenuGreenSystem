import '../i18n/api_message_translator.dart';

class ErrorTranslator {
  ErrorTranslator._();

  static String fromStatusCode(int statusCode, {String? serverMessage}) {
    final message = ApiMessageTranslator.translate(serverMessage);
    if (message.isNotEmpty) return message;

    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại dữ liệu.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu phù hợp.';
      case 408:
        return 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
      case 429:
        return 'Hệ thống đang bị giới hạn số lần gọi API. Vui lòng thử lại sau.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Dữ liệu từ máy chủ đang tạm thời không khả dụng.';
      default:
        return statusCode >= 500
            ? 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.'
            : 'Đã xảy ra lỗi khi kết nối đến máy chủ.';
    }
  }

  static String networkUnavailable() => 'Không có kết nối Internet.';

  static String timeout() =>
      'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';

  static String invalidData() =>
      'Dữ liệu từ máy chủ đang tạm thời không khả dụng.';
}
