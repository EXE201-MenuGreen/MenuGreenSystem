import 'dart:convert';

/// Dịch message tiếng Anh từ API sang tiếng Việt trước khi hiển thị cho user.
class ApiMessageTranslator {
  ApiMessageTranslator._();

  static const _exact = <String, String>{
    // Auth
    'OTP verified successfully.': 'Xác thực OTP thành công.',
    'Invalid or expired OTP.': 'OTP không hợp lệ hoặc đã hết hạn.',
    'Logged out successfully.': 'Đăng xuất thành công.',
    'Email is required.': 'Vui lòng nhập email.',
    'Invalid email format.': 'Email không đúng định dạng.',
    'Password is required.': 'Vui lòng nhập mật khẩu.',
    'Invalid username or password.': 'Tên đăng nhập hoặc mật khẩu không chính xác.',
    'Email already exists.': 'Email này đã được đăng ký tài khoản.',
    'User not found.': 'Không tìm thấy thông tin tài khoản.',
    'Unauthorized': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'Unauthorized.': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'Bad Request': 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.',
    'Internal Server Error': 'Máy chủ gặp sự cố. Vui lòng thử lại sau.',
    'An error occurred while processing your request.':
        'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại sau.',

    // Not found / forbidden
    'Recipe not found.': 'Không tìm thấy công thức.',
    'Food not found.': 'Không tìm thấy món ăn.',
    'Ingredient not found.': 'Không tìm thấy nguyên liệu.',
    'Notification not found.': 'Không tìm thấy thông báo.',
    'Forbidden.': 'Bạn không có quyền thực hiện thao tác này.',
    'User subscription not found.': 'Không tìm thấy gói đăng ký.',
    'Subscription plan not found or inactive.': 'Gói dịch vụ không tồn tại hoặc đã ngừng.',
    'Current password is incorrect.': 'Mật khẩu hiện tại không đúng.',
    'Confirm password does not match.': 'Mật khẩu xác nhận không khớp.',
    'Meal log not found.': 'Không tìm thấy nhật ký bữa ăn.',
    'Meal plan not found.': 'Không tìm thấy kế hoạch bữa ăn.',
    'Meal plan item not found.': 'Không tìm thấy mục trong kế hoạch.',
    'Meal plan must contain at least one item.': 'Kế hoạch cần ít nhất một bữa.',
    'Each meal plan item must have either FoodId or RecipeId.':
        'Mỗi bữa trong kế hoạch cần chọn món hoặc công thức.',
    'Meal plan item must have FoodId or RecipeId.':
        'Mục kế hoạch cần món ăn hoặc công thức.',
    'FoodId, RecipeId, or CustomName is required.':
        'Vui lòng chọn món ăn, công thức hoặc nhập tên món.',
    'PlannedDate is required.': 'Vui lòng chọn ngày cho kế hoạch.',
    'QuantityG must be greater than 0.': 'Khẩu phần ăn phải lớn hơn 0g.',
    'Meal reminder is disabled.': 'Đã tắt nhắc giờ ăn.',
    'Prep reminder is disabled.': 'Đã tắt nhắc chuẩn bị nấu.',
    'Weight log not found.': 'Không tìm thấy nhật ký cân nặng.',
    'FoodId or RecipeId is required.': 'Cần chọn món ăn hoặc công thức.',
    'Please complete health profile before finishing onboarding.':
        'Vui lòng nhập thông số sức khỏe trước khi hoàn tất thiết lập.',
    'Height and weight are required.': 'Chiều cao và cân nặng là bắt buộc.',
    'Account not found. Please sign out and sign in again.':
        'Tài khoản không tồn tại. Vui lòng đăng xuất và đăng nhập lại.',
    'Invalid preference data. Please try again.': 'Dữ liệu sở thích không hợp lệ. Vui lòng thử lại.',
    'Cannot save AI profile. Please try again later.':
        'Không thể lưu hồ sơ AI. Vui lòng thử lại sau.',
    'Database schema is outdated. Please run migrations.':
        'Cơ sở dữ liệu chưa cập nhật. Vui lòng thử lại sau.',
    'Payment failed or cancelled.': 'Thanh toán không thành công hoặc đã bị hủy.',
    'Cannot update a completed meal plan.': 'Không thể chỉnh sửa kế hoạch đã hoàn thành.',

    // Nutrition warnings (English from API)
    'Calorie intake deviates more than 10% from daily target.':
        'Calo lệch hơn 10% so với mục tiêu ngày.',

    // DailyStarter / VietnamLocal
    'Menu template applied to today\'s plan successfully.':
        'Đã áp dụng mẫu thực đơn cho kế hoạch hôm nay.',
    'Meal added to today\'s plan successfully.':
        'Đã thêm món vào kế hoạch hôm nay.',
    'Feedback saved successfully.':
        'Đã lưu phản hồi của bạn.',
    'Saved as quick add successfully.':
        'Đã lưu làm món ăn nhanh.',
    'Configuration deleted successfully.':
        'Đã xóa cấu hình.',
    'Ingredient substitution in plan applied successfully.':
        'Đã thay thế nguyên liệu trong kế hoạch.',
    'Actual ingredient substitution recorded successfully.':
        'Đã ghi nhận thay thế nguyên liệu thực tế.',
    'FoodId or MealLogId is required.':
        'Cần chọn món ăn hoặc nhật ký bữa ăn.',
    'Consent updated and saved to AI Profile preferences.':
        'Đã cập nhật đồng ý và lưu vào hồ sơ AI.',
    'Recalibration data collected and target calories updated successfully.':
        'Đã thu thập dữ liệu và cập nhật calo mục tiêu.',
    'A future meal cannot be marked as eaten.':
        'Bữa ăn trong tương lai không thể đánh dấu là đã ăn.',
    'A future meal item cannot be marked as eaten.':
        'Không thể đánh dấu đã ăn cho bữa ăn trong tương lai.',
    'Cannot mark a future meal as eaten.':
        'Không thể đánh dấu đã ăn cho bữa ăn trong tương lai.',

    // PT Review / Coach weekly report
    'Review request does not exist.':
        'Không tìm thấy yêu cầu đánh giá.',
    'Review request does not exist or token is invalid.':
        'Không tìm thấy yêu cầu đánh giá hoặc mã token không hợp lệ.',
    'Link has expired.':
        'Liên kết đã hết hạn.',
    'This review request has already been responded to or applied.':
        'Yêu cầu đánh giá đã được phản hồi hoặc đã áp dụng.',
    'Review request has not been responded to by PT or has already been processed.':
        'Yêu cầu chưa được PT phản hồi hoặc đã được xử lý.',
    'Access denied.':
        'Bạn không có quyền truy cập.',

    // Coach Meal Plan
    'Meal plan items cannot be null.':
        'Danh sách món trong lộ trình không được để trống.',
    'Please set up a budget (Budget Request) before automatically generating a plan.':
        'Vui lòng thiết lập ngân sách trước khi tự động tạo lộ trình.',
    'Meal plan not found or access denied.':
        'Không tìm thấy lộ trình hoặc bạn không có quyền truy cập.',
  };

  static final _macroExceeds = RegExp(
    r'^(Protein|Carbs|Fat) exceeds target \(([0-9.]+)g / ([0-9.]+)g\)\.$',
  );
  static final _macroBelow = RegExp(
    r'^(Protein|Carbs|Fat) below target \(([0-9.]+)g / ([0-9.]+)g\)\.$',
  );

  static const _macroLabels = {
    'Protein': 'Protein',
    'Carbs': 'Carb',
    'Fat': 'Chất béo',
  };

  /// Dịch một message; đảm bảo tuyệt đối KHÔNG bao giờ trả về chuỗi HTML, JSON hay mã lỗi stacktrace cho user.
  static String translate(String? message) {
    if (message == null) return '';
    var trimmed = message.trim();
    if (trimmed.isEmpty) return '';

    // 1. Kiểm tra & lọc bỏ hoàn toàn nếu là HTML
    if (_isHtml(trimmed)) {
      return 'Máy chủ đang gặp sự cố tạm thời. Vui lòng thử lại sau.';
    }

    // 2. Loại bỏ các tiền tố Exception kỹ thuật
    for (final prefix in [
      'Exception: ',
      'System.Exception: ',
      'System.InvalidOperationException: ',
      'InvalidOperationException: ',
      'Bad Request: ',
      'DioException: ',
      'FormatException: ',
    ]) {
      if (trimmed.startsWith(prefix)) {
        trimmed = trimmed.substring(prefix.length).trim();
      }
    }

    // 3. Trích xuất nếu message có dạng JSON / ProblemDetails từ ASP.NET Core
    final parsedJsonMessage = _tryParseJsonError(trimmed);
    if (parsedJsonMessage != null && parsedJsonMessage.isNotEmpty) {
      return parsedJsonMessage;
    }

    // 4. Tra từ điển chính xác
    final exact = _exact[trimmed] ?? _exact['$trimmed.'];
    if (exact != null) return exact;

    // 5. Tra từ điển không phân biệt hoa thường
    for (final entry in _exact.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }

    // 6. Khớp Regex cho dinh dưỡng macro
    final exceeds = _macroExceeds.firstMatch(trimmed);
    if (exceeds != null) {
      final label = _macroLabels[exceeds.group(1)] ?? exceeds.group(1)!;
      return '$label vượt mục tiêu (${exceeds.group(2)}g / ${exceeds.group(3)}g).';
    }

    final below = _macroBelow.firstMatch(trimmed);
    if (below != null) {
      final label = _macroLabels[below.group(1)] ?? below.group(1)!;
      return '$label thấp hơn mục tiêu (${below.group(2)}g / ${below.group(3)}g).';
    }

    // 7. Giữ nguyên nếu đã là câu tiếng Việt hoàn chỉnh
    if (_looksVietnamese(trimmed)) return trimmed;

    // 8. Lọc bỏ nếu chứa thuật ngữ kỹ thuật / StackTrace
    if (_hasTechnicalTerms(trimmed)) {
      return 'Hệ thống phản hồi không hợp lệ. Vui lòng thử lại sau.';
    }

    // 9. Fallback an toàn cho tiếng Anh chưa dịch: Trả về câu thông báo thân thiện
    return 'Thao tác chưa hoàn thành. Vui lòng thử lại sau.';
  }

  static List<String> translateList(List<String> messages) {
    return messages.map(translate).where((m) => m.isNotEmpty).toList();
  }

  /// Dịch title/body từ FCM push notification.
  static String translateNotification(String? text) {
    if (text == null) return '';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (_looksVietnamese(trimmed)) return trimmed;

    final exact = _exact[trimmed];
    if (exact != null) return exact;

    return translate(trimmed);
  }

  static bool _isHtml(String text) {
    final lower = text.toLowerCase();
    return lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('<body') ||
        lower.contains('<div') ||
        lower.contains('<h1') ||
        lower.contains('<head');
  }

  static String? _tryParseJsonError(String text) {
    if (!text.startsWith('{') || !text.endsWith('}')) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('errors') && decoded['errors'] is Map) {
          final errorsMap = decoded['errors'] as Map;
          if (errorsMap.isNotEmpty) {
            final firstValue = errorsMap.values.first;
            if (firstValue is List && firstValue.isNotEmpty) {
              return translate(firstValue.first.toString());
            }
            return translate(firstValue.toString());
          }
        }
        final msg = decoded['message'] ??
            decoded['Message'] ??
            decoded['title'] ??
            decoded['Title'] ??
            decoded['detail'] ??
            decoded['Detail'];
        if (msg != null && msg.toString().isNotEmpty) {
          return translate(msg.toString());
        }
      }
    } catch (_) {}
    return null;
  }

  static bool _hasTechnicalTerms(String text) {
    final lower = text.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('socketexception') ||
        lower.contains('formatexception') ||
        lower.contains('dioexception') ||
        lower.contains('nullreference') ||
        lower.contains('invalidoperation') ||
        lower.contains('stacktrace') ||
        lower.contains('at system.') ||
        lower.contains('http.response') ||
        lower.contains('typeerror') ||
        lower.contains('nosuchmethod') ||
        lower.contains('bad request') ||
        lower.contains('internal server error') ||
        lower.contains('application/problem+json');
  }

  static bool _looksVietnamese(String text) {
    return RegExp(
      r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]',
      caseSensitive: false,
    ).hasMatch(text);
  }
}

