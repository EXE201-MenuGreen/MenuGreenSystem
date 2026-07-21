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
        'Cơ sở dữ liệu chưa cập nhật. Vui lòng chạy migration.',

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

  /// Dịch một message; giữ nguyên nếu đã là tiếng Việt hoặc rỗng.
  static String translate(String? message) {
    if (message == null) return '';
    var trimmed = message.trim();
    if (trimmed.isEmpty) return trimmed;

    // Strip exception prefixes
    if (trimmed.startsWith('Exception: ')) {
      trimmed = trimmed.substring('Exception: '.length).trim();
    }
    if (trimmed.startsWith('System.Exception: ')) {
      trimmed = trimmed.substring('System.Exception: '.length).trim();
    }
    if (trimmed.startsWith('System.InvalidOperationException: ')) {
      trimmed = trimmed.substring('System.InvalidOperationException: '.length).trim();
    }
    if (trimmed.startsWith('InvalidOperationException: ')) {
      trimmed = trimmed.substring('InvalidOperationException: '.length).trim();
    }
    if (trimmed.startsWith('Bad Request: ')) {
      trimmed = trimmed.substring('Bad Request: '.length).trim();
    }

    if (_looksVietnamese(trimmed)) return trimmed;

    final exact = _exact[trimmed] ?? _exact['$trimmed.'];
    if (exact != null) return exact;

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

    return trimmed;
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

    // Already translated exact messages
    final exact = _exact[trimmed];
    if (exact != null) return exact;

    return trimmed;
  }

  static bool _looksVietnamese(String text) {
    return RegExp(r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]', caseSensitive: false)
        .hasMatch(text);
  }
}
