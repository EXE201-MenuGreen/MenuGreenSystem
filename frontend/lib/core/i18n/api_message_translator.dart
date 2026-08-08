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
    'Invalid username or password.':
        'Tên đăng nhập hoặc mật khẩu không chính xác.',
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
    'Subscription plan not found or inactive.':
        'Gói dịch vụ không tồn tại hoặc đã ngừng.',
    'Current password is incorrect.': 'Mật khẩu hiện tại không đúng.',
    'Confirm password does not match.': 'Mật khẩu xác nhận không khớp.',
    'Meal log not found.': 'Không tìm thấy nhật ký bữa ăn.',
    'Meal plan not found.': 'Không tìm thấy kế hoạch bữa ăn.',
    'Meal plan item not found.': 'Không tìm thấy mục trong kế hoạch.',
    'Meal plan must contain at least one item.':
        'Kế hoạch cần ít nhất một bữa.',
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
    'Invalid preference data. Please try again.':
        'Dữ liệu sở thích không hợp lệ. Vui lòng thử lại.',
    'Cannot save AI profile. Please try again later.':
        'Không thể lưu hồ sơ AI. Vui lòng thử lại sau.',
    'Database schema is outdated. Please run migrations.':
        'Cơ sở dữ liệu chưa cập nhật. Vui lòng thử lại sau.',
    'Payment failed or cancelled.':
        'Thanh toán không thành công hoặc đã bị hủy.',
    'Cannot update a completed meal plan.':
        'Không thể chỉnh sửa kế hoạch đã hoàn thành.',

    // Nutrition warnings (English from API)
    'Calorie intake deviates more than 10% from daily target.':
        'Calo lệch hơn 10% so với mục tiêu ngày.',
    'Current weight is confirmed, but there are not enough consistent weight logs to adjust calories safely. Keeping the current target.':
        'Đã xác nhận cân nặng hiện tại nhưng chưa đủ dữ liệu nhất quán để điều chỉnh calo an toàn. Hệ thống giữ nguyên mục tiêu hiện tại.',

    // DailyStarter / VietnamLocal
    'Menu template applied to today\'s plan successfully.':
        'Đã áp dụng mẫu thực đơn cho kế hoạch hôm nay.',
    'Meal added to today\'s plan successfully.':
        'Đã thêm món vào kế hoạch hôm nay.',
    'Feedback saved successfully.': 'Đã lưu phản hồi của bạn.',
    'Saved as quick add successfully.': 'Đã lưu làm món ăn nhanh.',
    'Configuration deleted successfully.': 'Đã xóa cấu hình.',
    'Ingredient substitution in plan applied successfully.':
        'Đã thay thế nguyên liệu trong kế hoạch.',
    'Actual ingredient substitution recorded successfully.':
        'Đã ghi nhận thay thế nguyên liệu thực tế.',
    'FoodId or MealLogId is required.': 'Cần chọn món ăn hoặc nhật ký bữa ăn.',
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
    'Review request does not exist.': 'Không tìm thấy yêu cầu đánh giá.',
    'Review request does not exist or token is invalid.':
        'Không tìm thấy yêu cầu đánh giá hoặc mã token không hợp lệ.',
    'Link has expired.': 'Liên kết đã hết hạn.',
    'This review request has already been responded to or applied.':
        'Yêu cầu đánh giá đã được phản hồi hoặc đã áp dụng.',
    'Review request has not been responded to by PT or has already been processed.':
        'Yêu cầu chưa được PT phản hồi hoặc đã được xử lý.',
    'Access denied.': 'Bạn không có quyền truy cập.',

    // Coach Meal Plan
    'Meal plan items cannot be null.':
        'Danh sách món trong lộ trình không được để trống.',
    'Please set up a budget (Budget Request) before automatically generating a plan.':
        'Vui lòng thiết lập ngân sách trước khi tự động tạo lộ trình.',
    'Meal plan not found or access denied.':
        'Không tìm thấy lộ trình hoặc bạn không có quyền truy cập.',

    // Phase 8: PersonalProgram (Coach -> Gymer direction)
    'Personal program does not exist.': 'Không tìm thấy lộ trình cá nhân.',
    'This request was not sent by your coach.':
        'Yêu cầu này không được gửi từ PT của bạn.',
    'Personal program has already been processed.':
        'Lộ trình cá nhân đã được xử lý.',
    'You are not connected with this client.':
        'Bạn chưa kết nối với khách hàng này.',
    'Client already has a pending personal program. Please wait for them to respond before sending a new one.':
        'Khách hàng đang có lộ trình cá nhân chờ phản hồi. Vui lòng chờ họ xử lý trước khi gửi lộ trình mới.',

    // Coach connection request notifications (English from CoachService.cs)
    'New student connection request': 'Yêu cầu kết nối từ học viên mới',
    'Connection request accepted': 'Yêu cầu kết nối đã được chấp nhận',
    'Connection request rejected': 'Yêu cầu kết nối đã bị từ chối',
    'New advice from Coach': 'Lời khuyên mới từ PT / Coach',
    'Meal plan has been adjusted': 'Thực đơn đã được điều chỉnh',
    'Nutrition targets have been updated': 'Chỉ số dinh dưỡng đã được cập nhật',

    // Recalibrate gym goals — needs recent weight data
    'No weight data in the last 7 days. Please log your weight before recalibrating.':
        'Vui lòng cập nhật cân nặng ít nhất 1 lần trong 7 ngày qua trước khi hiệu chỉnh mục tiêu.',
  };

  /// Stable backend error codes. Use these instead of relying on the
  /// (translatable) message string when the caller needs to branch on the
  /// specific failure reason.
  static const _errorCodes = <String, String>{
    'RECALIBRATE_NO_WEIGHT_DATA':
        'Vui lòng cập nhật cân nặng ít nhất 1 lần trong 7 ngày qua trước khi hiệu chỉnh mục tiêu.',
    'RECALIBRATE_ANOMALY_WEIGHT_CHANGE':
        'Thay đổi cân nặng tuần qua bất thường. Vui lòng kiểm tra lại các lần ghi cân nặng gần đây trước khi hiệu chỉnh mục tiêu.',
  };

  static final _macroExceeds = RegExp(
    r'^(Protein|Carbs|Fat) exceeds target \(([0-9.]+)g / ([0-9.]+)g\)\.$',
  );
  static final _macroBelow = RegExp(
    r'^(Protein|Carbs|Fat) below target \(([0-9.]+)g / ([0-9.]+)g\)\.$',
  );

  // ---- Recalibration reason patterns ----
  // Backend GymGoalsController emits one of these as `reason`. They contain
  // interpolated numbers, so we translate via regex capture groups.
  static final _reasonCutReduced = RegExp(
    r'^Goal is Cut but your weight increased or stayed the same \((-?[0-9.]+) kg\) over the past week\. Suggesting 10% reduction in calorie intake\.$',
  );
  static final _reasonCutStable = RegExp(
    r'^Good weight loss progress \((-?[0-9.]+) kg\)\. Continue maintaining current calorie level\.$',
  );
  static final _reasonBulkIncreased = RegExp(
    r'^Goal is Bulk but your weight decreased or stayed the same \((-?[0-9.]+) kg\) over the past week\. Suggesting 10% increase in calorie intake\.$',
  );
  static final _reasonBulkStable = RegExp(
    r'^Good weight gain progress \(\+(-?[0-9.]+) kg\)\. Continue maintaining current calorie level\.$',
  );
  static final _reasonMaintainReduce = RegExp(
    r'^Weight increased \((-?[0-9.]+) kg\) versus maintain goal\. Suggesting 5% calorie reduction\.$',
  );
  static final _reasonMaintainIncrease = RegExp(
    r'^Weight decreased \((-?[0-9.]+) kg\) versus maintain goal\. Suggesting 5% calorie increase\.$',
  );
  static final _reasonOptimal = RegExp(
    r'^Your target calorie intake is at an optimal level\.$',
  );
  // Suffix appended after the main reason. Translates the relationship
  // between current weight and the user's target weight.
  static final _suffixWeightDistance = RegExp(
    r' Current weight is (-?[0-9.]+) kg, ([0-9.]+) kg (above|below|at) the target\.',
  );
  static final _suffixBodyFatDistance = RegExp(
    r' Body fat is (-?[0-9.]+)%, ([0-9.]+) percentage points (above|below|at) the target\.',
  );

  static const _macroLabels = {
    'Protein': 'Protein',
    'Carbs': 'Carb',
    'Fat': 'Chất béo',
  };

  /// Translate the recalibration `reason` string from
  /// `GymGoalsController.Recalibrate`. The backend composes a sentence of
  /// the form
  ///   `[head]. Current weight is X kg, Y kg above the target. Body fat is Z%, W percentage points at the target.`
  /// We translate the head, the optional weight-distance suffix, and the
  /// optional body-fat suffix into Vietnamese.
  static String? _translateRecalibrationReason(String text) {
    // Pull off suffixes first (weight distance, then body-fat distance) and
    // translate each independently so the order doesn't matter.
    final parts = <String>[];
    var remaining = text;

    final bodyFatMatch = _suffixBodyFatDistance.firstMatch(remaining);
    String? bodyFatSuffix;
    if (bodyFatMatch != null) {
      final pct = bodyFatMatch.group(1)!;
      final diff = bodyFatMatch.group(2)!;
      final pos = bodyFatMatch.group(3)!;
      final posVi = switch (pos) {
        'above' => 'trên',
        'below' => 'dưới',
        _ => 'đúng',
      };
      bodyFatSuffix =
          'Tỷ lệ mỡ hiện tại $pct%, chênh $diff điểm phần trăm $posVi mục tiêu.';
      remaining =
          remaining.substring(0, bodyFatMatch.start) +
          remaining.substring(bodyFatMatch.end);
    }

    final weightMatch = _suffixWeightDistance.firstMatch(remaining);
    String? weightSuffix;
    if (weightMatch != null) {
      final kg = weightMatch.group(1)!;
      final diff = weightMatch.group(2)!;
      final pos = weightMatch.group(3)!;
      final posVi = switch (pos) {
        'above' => 'trên',
        'below' => 'dưới',
        _ => 'đúng',
      };
      weightSuffix =
          'Cân nặng hiện tại $kg kg, chênh $diff kg $posVi mục tiêu.';
      remaining =
          remaining.substring(0, weightMatch.start) +
          remaining.substring(weightMatch.end);
    }

    remaining = remaining.trim();
    String? head;
    final m = _reasonCutReduced.firstMatch(remaining);
    if (m != null) {
      final kg = m.group(1)!;
      head =
          'Mục tiêu là giảm cân nhưng cân nặng tăng hoặc giữ nguyên ($kg kg) trong tuần qua. Đề xuất giảm 10% calo.';
    } else {
      final m = _reasonCutStable.firstMatch(remaining);
      if (m != null) {
        final kg = m.group(1)!;
        head =
            'Tiến triển giảm cân tốt ($kg kg). Tiếp tục duy trì mức calo hiện tại.';
      } else {
        final m = _reasonBulkIncreased.firstMatch(remaining);
        if (m != null) {
          final kg = m.group(1)!;
          head =
              'Mục tiêu là tăng cân nhưng cân nặng giảm hoặc giữ nguyên ($kg kg) trong tuần qua. Đề xuất tăng 10% calo.';
        } else {
          final m = _reasonBulkStable.firstMatch(remaining);
          if (m != null) {
            final kg = m.group(1)!;
            head =
                'Tiến triển tăng cân tốt (+$kg kg). Tiếp tục duy trì mức calo hiện tại.';
          } else {
            final m = _reasonMaintainReduce.firstMatch(remaining);
            if (m != null) {
              final kg = m.group(1)!;
              head =
                  'Cân nặng tăng ($kg kg) so với mục tiêu duy trì. Đề xuất giảm 5% calo.';
            } else {
              final m = _reasonMaintainIncrease.firstMatch(remaining);
              if (m != null) {
                final kg = m.group(1)!;
                head =
                    'Cân nặng giảm ($kg kg) so với mục tiêu duy trì. Đề xuất tăng 5% calo.';
              } else if (_reasonOptimal.hasMatch(remaining)) {
                head = 'Calo mục tiêu hiện tại đang ở mức tối ưu.';
              }
            }
          }
        }
      }
    }

    if (head == null) return null;
    if (weightSuffix != null) parts.add(weightSuffix);
    if (bodyFatSuffix != null) parts.add(bodyFatSuffix);
    return [head, ...parts].join(' ');
  }

  /// Dịch một message; đảm bảo tuyệt đối KHÔNG bao giờ trả về chuỗi HTML, JSON hay mã lỗi stacktrace cho user.
  ///
  /// Khi [errorCode] được cung cấp (ví dụ `RECALIBRATE_NO_WEIGHT_DATA`),
  /// nó được ưu tiên để map sang câu tiếng Việt ổn định, không phụ thuộc
  /// vào message gốc của server (có thể thay đổi theo thời gian).
  static String translate(String? message, {String? errorCode}) {
    if (errorCode != null && errorCode.isNotEmpty) {
      final fromCode = _errorCodes[errorCode];
      if (fromCode != null) return fromCode;
    }
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

    // 6b. Recalibration reason (English from GymGoalsController) — strip
    // any "current weight / body fat" suffix, translate the head, then
    // append the translated suffix (if present).
    final reason = _translateRecalibrationReason(trimmed);
    if (reason != null) return reason;

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
        final msg =
            decoded['message'] ??
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
