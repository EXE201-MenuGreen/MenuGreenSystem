/// Dịch thông báo auth từ API (tiếng Anh) sang tiếng Việt cho UI.
String localizeAuthMessage(String? raw, {String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.'}) {
  if (raw == null || raw.trim().isEmpty) return fallback;

  final normalized = raw.trim();
  final lower = normalized.toLowerCase();

  const exact = <String, String>{
    // Login / session
    'Invalid email or password.': 'Email hoặc mật khẩu không chính xác.',
    'Invalid email or password': 'Email hoặc mật khẩu không chính xác.',
    'Please verify your OTP before logging in.': 'Vui lòng xác thực OTP trước khi đăng nhập.',
    'Your account has been locked.': 'Tài khoản của bạn đã bị khóa.',
    'Your account has been locked or does not exist.':
        'Tài khoản không tồn tại hoặc đã bị khóa.',
    'Invalid or expired refresh token.': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
    // Register
    'Email is already registered.': 'Email đã được đăng ký.',
    'Registration successful. Please check your email for the verification OTP.':
        'Đăng ký thành công. Vui lòng kiểm tra email để lấy OTP xác thực.',
    // OTP
    'OTP verified successfully.': 'Xác thực OTP thành công.',
    'Invalid or expired OTP.': 'OTP không hợp lệ hoặc đã hết hạn.',
    // Forgot / reset password
    'If the email exists, an OTP has been sent.':
        'Nếu email tồn tại, OTP đã được gửi.',
    'Password recovery OTP has been sent to your email.':
        'OTP khôi phục mật khẩu đã được gửi đến email.',
    'Email does not exist.': 'Email không tồn tại.',
    'Password reset successful.': 'Đặt lại mật khẩu thành công.',
    'Logged out successfully.': 'Đăng xuất thành công.',
    // Frontend fallbacks (English keys)
    'Login failed': 'Đăng nhập thất bại.',
    'Registration failed': 'Đăng ký thất bại.',
    'OTP verification failed': 'Xác thực OTP thất bại.',
    'Forgot password failed': 'Gửi yêu cầu quên mật khẩu thất bại.',
    'Reset password failed': 'Đặt lại mật khẩu thất bại.',
    'Refresh token failed': 'Làm mới phiên đăng nhập thất bại.',
    'No refresh token': 'Không tìm thấy phiên đăng nhập.',
    'Logout request failed': 'Đăng xuất thất bại.',
    'Connection error. Is backend running?': 'Lỗi kết nối. Bạn đã bật backend chưa?',
  };

  if (exact.containsKey(normalized)) return exact[normalized]!;

  if (lower.contains('invalid email or password')) {
    return 'Email hoặc mật khẩu không chính xác.';
  }
  if (lower.contains('verify') && lower.contains('otp')) {
    return 'Vui lòng xác thực OTP trước khi đăng nhập.';
  }
  if (lower.contains('invalid or expired otp')) {
    return 'OTP không hợp lệ hoặc đã hết hạn.';
  }
  if (lower.contains('locked')) {
    return 'Tài khoản của bạn đã bị khóa.';
  }
  if (lower.contains('connection error')) {
    return 'Lỗi kết nối. Bạn đã bật backend chưa?';
  }
  if (lower.contains('password reset successful')) {
    return 'Đặt lại mật khẩu thành công.';
  }
  if (lower.contains('registration successful')) {
    return 'Đăng ký thành công. Vui lòng kiểm tra email để lấy OTP xác thực.';
  }

  return normalized;
}

String? extractApiMessage(dynamic decoded) {
  if (decoded is! Map) return null;
  return (decoded['message'] ?? decoded['Message'])?.toString();
}

/// Lấy message từ response (kể cả nested trong `data`).
String? extractAuthResponseMessage(dynamic decoded) {
  final direct = extractApiMessage(decoded);
  if (direct != null && direct.isNotEmpty) return direct;
  if (decoded is Map) {
    final data = decoded['data'];
    if (data is Map) return extractApiMessage(data);
  }
  return null;
}

bool isOtpVerificationRequiredMessage(String message) {
  final lower = message.toLowerCase();
  return lower.contains('otp') &&
      (lower.contains('xác thực') ||
          lower.contains('verify') ||
          lower.contains('chưa'));
}
