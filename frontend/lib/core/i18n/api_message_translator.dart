import 'dart:convert';

/// Dịch message tiếng Anh từ API sang tiếng Việt trước khi hiển thị cho user.
class ApiMessageTranslator {
  ApiMessageTranslator._();

  static const _dataDictionary = <String, String>{
    // Meal Types
    'breakfast': 'Bữa sáng',
    'lunch': 'Bữa trưa',
    'dinner': 'Bữa tối',
    'snack': 'Ăn vặt',
    
    // Statuses
    'pending': 'Chờ duyệt',
    'accepted': 'Đã duyệt',
    'approved': 'Đã duyệt',
    'rejected': 'Từ chối',
    'completed': 'Hoàn thành',
    'active': 'Đang hoạt động',
    'inactive': 'Ngừng hoạt động',
    
    // Categories & Common Terms
    'meat': 'Thịt',
    'vegetable': 'Rau củ',
    'vegetables': 'Rau củ',
    'fruit': 'Trái cây',
    'fruits': 'Trái cây',
    'dairy': 'Sữa',
    'seafood': 'Hải sản',
    'carb': 'Tinh bột',
    'carbs': 'Tinh bột',
    'protein': 'Đạm',
    'fat': 'Chất béo',
    'weight loss': 'Giảm cân',
    'muscle gain': 'Tăng cơ',
    'maintenance': 'Giữ dáng',
    'sedentary': 'Ít vận động',
    
    // Others
    'casual': 'Thông thường',
    'office': 'Văn phòng',
    'coach': 'Huấn luyện viên',
    'gymer': 'Người tập gym',
    'trainer': 'Huấn luyện viên',
  };

  /// Dịch dữ liệu động (Data payload) từ backend như mealType, status, category...
  static String translateData(String? data) {
    if (data == null || data.trim().isEmpty) return '';
    final key = data.trim().toLowerCase();
    return _dataDictionary[key] ?? data;
  }

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

    // Rate Limiting (429 Too Many Requests)
    'Too Many Requests': 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
    'Rate limit exceeded': 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.',
    'Rate limit exceeded. Please try again later.':
        'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.',
    'AI service is rate-limited. Please try again in a few minutes.':
        'Dịch vụ AI đang bận. Vui lòng thử lại sau vài phút.',

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

    
    // --- Backend API Auto-Translations ---
    'If the email exists, an OTP has been sent.': 'Nếu email tồn tại, mã OTP đã được gửi đến bạn.',
    'You do not have permission to edit this custom unit.': 'Bạn không có quyền chỉnh sửa đơn vị tùy chỉnh này.',
    'Coach application not found.': 'Không tìm thấy đơn đăng ký Huấn luyện viên.',
    'Client does not exist.': 'Khách hàng không tồn tại.',
    'Default serving weight must be greater than 0 grams.': 'Khối lượng phục vụ mặc định phải lớn hơn 0 gam.',
    'Feedback updated successfully.': 'Cập nhật phản hồi thành công.',
    'The Basic plan is always available and does not require renewal.': 'Gói Basic luôn có sẵn và không yêu cầu gia hạn.',
    'Conversation not found.': 'Không tìm thấy cuộc trò chuyện.',
    'Budget configuration deleted successfully.': 'Đã xóa cấu hình ngân sách thành công.',
    'Meal template must contain at least one item.': 'Mẫu bữa ăn phải chứa ít nhất một mục.',
    'Original ingredient quantity must be greater than 0.': 'Số lượng nguyên liệu gốc phải lớn hơn 0.',
    'Student has not set up their health profile.': 'Học viên chưa thiết lập hồ sơ sức khỏe.',
    'This meal plan was sent to another coach.': 'Kế hoạch bữa ăn này đã được gửi cho một huấn luyện viên khác.',
    'Food log not found.': 'Không tìm thấy nhật ký món ăn.',
    'Each meal plan item must have either FoodId, RecipeId, or CustomName.': 'Mỗi mục kế hoạch bữa ăn phải có FoodId, RecipeId hoặc Tên tùy chỉnh.',
    'Account type must be User or PT.': 'Loại tài khoản phải là Người dùng hoặc PT.',
    'Internal server error.': 'Lỗi máy chủ nội bộ.',
    'Payment order cancelled successfully.': 'Đã hủy đơn hàng thanh toán thành công.',
    'You already have a pending SePay payment. Complete or wait for it to expire before creating a new order.': 'Bạn đang có một khoản thanh toán SePay chờ xử lý. Hoàn thành hoặc đợi hết hạn trước khi tạo đơn hàng mới.',
    'Conversation deleted successfully.': 'Đã xóa cuộc trò chuyện thành công.',
    'User premium program registration not found.': 'Không tìm thấy đăng ký chương trình Premium của người dùng.',
    'Account not found.': 'Không tìm thấy tài khoản.',
    'Unsupported review decision.': 'Quyết định đánh giá không được hỗ trợ.',
    'JwtSettings:SecretKey is not configured.': 'JwtSettings:SecretKey chưa được cấu hình.',
    'PriceVnd must be greater than or equal to 0.': 'Giá VNĐ phải lớn hơn hoặc bằng 0.',
    'The start date must be before or equal to the end date.': 'Ngày bắt đầu phải trước hoặc bằng ngày kết thúc.',
    'Meal template deleted successfully.': 'Đã xóa mẫu bữa ăn thành công.',
    'Quantity is required.': 'Số lượng là bắt buộc.',
    'At least one professional certificate is required.': 'Cần ít nhất một chứng chỉ chuyên môn.',
    'Meal plan deleted successfully.': 'Đã xóa kế hoạch bữa ăn thành công.',
    'Deleted successfully.': 'Đã xóa thành công.',
    'Snooze duration must be between 1 and 1440 minutes.': 'Thời gian báo lại phải từ 1 đến 1440 phút.',
    'Empty webhook body.': 'Nội dung webhook trống.',
    'Your nutrition data is stable, no goal drift detected.': 'Dữ liệu dinh dưỡng của bạn ổn định, không phát hiện sai lệch mục tiêu.',
    'Subscription plan not found.': 'Không tìm thấy gói đăng ký.',
    'Full name must not exceed 255 characters.': 'Họ và tên không được vượt quá 255 ký tự.',
    'This plan is free and cannot be renewed via SePay.': 'Gói này miễn phí và không thể gia hạn qua SePay.',
    'Name is required.': 'Tên là bắt buộc.',
    'Coach profile not found.': 'Không tìm thấy hồ sơ huấn luyện viên.',
    'Biography must contain at least 80 characters.': 'Tiểu sử phải chứa ít nhất 80 ký tự.',
    'FoodId or RecipeId or custom nutritional values are required.': 'Yêu cầu có FoodId, RecipeId hoặc giá trị dinh dưỡng tùy chỉnh.',
    'Food is inactive and cannot be added to favorites.': 'Món ăn không hoạt động và không thể thêm vào mục yêu thích.',
    'Report not found.': 'Không tìm thấy báo cáo.',
    'No current goal drift alert.': 'Không có cảnh báo sai lệch mục tiêu hiện tại.',
    'Password changed successfully.': 'Đổi mật khẩu thành công.',
    'SePay webhook request expired.': 'Yêu cầu webhook SePay đã hết hạn.',
    'Hip measurement must be between 30cm and 250cm.': 'Số đo vòng hông phải từ 30cm đến 250cm.',
    'ConnectionStrings__DefaultConnection environment variable is not configured.': 'Biến môi trường ConnectionStrings__DefaultConnection chưa được cấu hình.',
    'NotificationIds list cannot be empty': 'Danh sách NotificationIds không được để trống.',
    'Please enter your date of birth in your profile first to calculate targets.': 'Vui lòng nhập ngày sinh trong hồ sơ của bạn trước để tính toán mục tiêu.',
    'You do not have a valid coaching connection with this student.': 'Bạn không có kết nối huấn luyện hợp lệ với học viên này.',
    "You do not have access to this student's feedback.": 'Bạn không có quyền truy cập vào phản hồi của học viên này.',
    'Program enrollment not found.': 'Không tìm thấy đăng ký chương trình.',
    'This meal plan does not belong to the specified student.': 'Kế hoạch bữa ăn này không thuộc về học viên được chỉ định.',
    'You do not have any active Premium programs.': 'Bạn không có chương trình Premium nào đang hoạt động.',
    'Requested food/dish not found.': 'Không tìm thấy món ăn/thực phẩm yêu cầu.',
    'AI service did not return a job ID.': 'Dịch vụ AI không trả về ID công việc.',
    'This program has not been paid for or is already activated.': 'Chương trình này chưa được thanh toán hoặc đã được kích hoạt.',
    'Recommendation not found.': 'Không tìm thấy gợi ý.',
    'Invalid or expired Google sign-in token.': 'Mã đăng nhập Google không hợp lệ hoặc đã hết hạn.',
    'Equivalent weight is required.': 'Trọng lượng tương đương là bắt buộc.',
    'Equivalent weight must be between 0.1g and 10000g.': 'Trọng lượng tương đương phải từ 0.1g đến 10000g.',
    'Target calories is required.': 'Lượng calo mục tiêu là bắt buộc.',
    'Years of experience is required.': 'Số năm kinh nghiệm là bắt buộc.',
    'Start date is required.': 'Ngày bắt đầu là bắt buộc.',
    'A reason is required for this decision.': 'Cần có lý do cho quyết định này.',
    'Outgoing transfer ignored.': 'Giao dịch chuyển đi bị bỏ qua.',
    'Added to favorites successfully.': 'Đã thêm vào mục yêu thích thành công.',
    'Bio is required.': 'Tiểu sử là bắt buộc.',
    'Data access granted to Coach.': 'Đã cấp quyền truy cập dữ liệu cho Huấn luyện viên.',
    'Payment already marked as paid.': 'Thanh toán đã được đánh dấu là đã trả.',
    'Goal drift alert not found.': 'Không tìm thấy cảnh báo sai lệch mục tiêu.',
    'Password must be at least 6 characters long.': 'Mật khẩu phải dài ít nhất 6 ký tự.',
    'Conversion unit is required.': 'Đơn vị chuyển đổi là bắt buộc.',
    'Invalid email or password.': 'Email hoặc mật khẩu không hợp lệ.',
    'Reminder time must be in the future.': 'Thời gian nhắc nhở phải ở trong tương lai.',
    'Your account has been locked or does not exist.': 'Tài khoản của bạn đã bị khóa hoặc không tồn tại.',
    'Image stream is missing or empty.': 'Luồng hình ảnh bị thiếu hoặc trống.',
    'DurationDays must be greater than or equal to 0.': 'DurationDays phải lớn hơn hoặc bằng 0.',
    'Google sign-in is not configured on the server.': 'Đăng nhập Google chưa được cấu hình trên máy chủ.',
    'FoodId is required when converting a local portion unit.': 'FoodId là bắt buộc khi chuyển đổi đơn vị khẩu phần cục bộ.',
    'Avatar URL must be a valid URL.': 'URL hình đại diện phải là một URL hợp lệ.',
    'Notification deleted successfully.': 'Đã xóa thông báo thành công.',
    'Only active subscriptions can be renewed via SePay.': 'Chỉ các gói đăng ký đang hoạt động mới có thể được gia hạn qua SePay.',
    'Weight must be between 30kg and 300kg.': 'Cân nặng phải từ 30kg đến 300kg.',
    'The Basic plan is enabled by default and does not require a subscription.': 'Gói Basic được kích hoạt mặc định và không yêu cầu đăng ký.',
    'Substitute ingredient not found.': 'Không tìm thấy nguyên liệu thay thế.',
    'Cooking time limit must be between 5 minutes and 1,440 minutes.': 'Giới hạn thời gian nấu phải từ 5 phút đến 1.440 phút.',
    'City is required.': 'Thành phố là bắt buộc.',
    'The application is already being reviewed.': 'Đơn đăng ký đang được xem xét.',
    'The image analysis task timed out on the AI service.': 'Nhiệm vụ phân tích hình ảnh đã quá thời gian trên dịch vụ AI.',
    'At least one language is required.': 'Cần ít nhất một ngôn ngữ.',
    'SePay payment not found.': 'Không tìm thấy khoản thanh toán SePay.',
    'CV service is not properly configured.': 'Dịch vụ CV chưa được cấu hình đúng.',
    'You do not have permission to delete this custom unit.': 'Bạn không có quyền xóa đơn vị tùy chỉnh này.',
    'Registration successful. Please check your email for the verification OTP.': 'Đăng ký thành công. Vui lòng kiểm tra email của bạn để lấy mã xác minh OTP.',
    'Image file is required.': 'Tệp hình ảnh là bắt buộc.',
    'Default serving weight is required.': 'Khối lượng phục vụ mặc định là bắt buộc.',
    'Substitute ingredient quantity must be greater than 0.': 'Số lượng nguyên liệu thay thế phải lớn hơn 0.',
    'Connection with this coach not found.': 'Không tìm thấy kết nối với huấn luyện viên này.',
    'This report has already been reviewed or closed.': 'Báo cáo này đã được đánh giá hoặc đóng lại.',
    'Missing X-SePay-Signature header.': 'Thiếu tiêu đề X-SePay-Signature.',
    'OTP code must be at least 6 characters long.': 'Mã OTP phải dài ít nhất 6 ký tự.',
    'At least one specialty is required.': 'Cần ít nhất một chuyên môn.',
    'Invalid payment status. Please refresh and try again.': 'Trạng thái thanh toán không hợp lệ. Vui lòng làm mới và thử lại.',
    'SePay bank account is not configured. Set SePay:BankAccount:AccountNumber and SePay:BankAccount:BankName in appsettings (values from your SePay dashboard).': 'Tài khoản ngân hàng SePay chưa được cấu hình.',
    'Phone number is required.': 'Số điện thoại là bắt buộc.',
    'Substitution configuration not found.': 'Không tìm thấy cấu hình thay thế.',
    'Token removed successfully.': 'Đã xóa token thành công.',
    'Active connection with this coach not found.': 'Không tìm thấy kết nối hoạt động với huấn luyện viên này.',
    'Feedback content is required.': 'Nội dung phản hồi là bắt buộc.',
    'Calories must be positive.': 'Calo phải là số dương.',
    'Reminder not found.': 'Không tìm thấy lời nhắc.',
    'Reminder notification sent successfully.': 'Đã gửi thông báo nhắc nhở thành công.',
    'You do not have an active Premium program to get report from.': 'Bạn không có chương trình Premium nào đang hoạt động để lấy báo cáo.',
    'This micro-learning card does not have an attached quiz question.': 'Thẻ học tập vi mô này không có câu hỏi trắc nghiệm đính kèm.',
    'Invalid SePay webhook API key.': 'Khóa API webhook SePay không hợp lệ.',
    'AI service rejected the API key. Please contact support.': 'Dịch vụ AI đã từ chối khóa API. Vui lòng liên hệ hỗ trợ.',
    'The application is being reviewed and cannot be edited.': 'Đơn đăng ký đang được xem xét và không thể chỉnh sửa.',
    'This token is already registered by another user.': 'Token này đã được đăng ký bởi một người dùng khác.',
    'Campaign not found.': 'Không tìm thấy chiến dịch.',
    'Unit name is required.': 'Tên đơn vị là bắt buộc.',
    'Your issue report has been successfully recorded.': 'Báo cáo sự cố của bạn đã được ghi nhận thành công.',
    'Micro-learning card not found.': 'Không tìm thấy thẻ học tập vi mô.',
    'Receiver bank account in webhook does not match configured SePay bank account.': 'Tài khoản ngân hàng người nhận trong webhook không khớp với tài khoản SePay đã cấu hình.',
    'Meal in meal plan not found.': 'Không tìm thấy bữa ăn trong kế hoạch.',
    'SePay:WebhookSecret is not configured.': 'SePay:WebhookSecret chưa được cấu hình.',
    'The original program has been deleted.': 'Chương trình gốc đã bị xóa.',
    'Duplicate transaction ignored.': 'Giao dịch trùng lặp bị bỏ qua.',
    'Subscription program registration details not found.': 'Không tìm thấy chi tiết đăng ký chương trình.',
    "Invalid action. Only 'read', 'save', 'unsave', 'dismiss' are accepted.": "Hành động không hợp lệ. Chỉ chấp nhận 'read', 'save', 'unsave', 'dismiss'.",
    'Weight must be between 20kg and 500kg.': 'Cân nặng phải từ 20kg đến 500kg.',
    'Unsupported AI action type.': 'Loại hành động AI không được hỗ trợ.',
    'New password is required.': 'Mật khẩu mới là bắt buộc.',
    'SePay:WebhookApiKey is not configured.': 'SePay:WebhookApiKey chưa được cấu hình.',
    'You need to graduate before exporting the certificate.': 'Bạn cần hoàn thành chương trình trước khi xuất chứng chỉ.',
    'Reminder deleted successfully.': 'Đã xóa lời nhắc thành công.',
    'Title is required.': 'Tiêu đề là bắt buộc.',
    'Feedback recorded successfully.': 'Phản hồi đã được ghi nhận thành công.',
    'Conversion quantity must be between 0.01 and 1000.': 'Số lượng chuyển đổi phải từ 0.01 đến 1000.',
    'Budget request not found.': 'Không tìm thấy yêu cầu ngân sách.',
    'Food ID is required.': 'Food ID là bắt buộc.',
    'budget_vnd is required for budget optimization.': 'budget_vnd là bắt buộc để tối ưu hóa ngân sách.',
    'weekStart must be yyyy-MM-dd.': 'weekStart phải có định dạng yyyy-MM-dd.',
    'Duplicate transaction ignored (database constraint).': 'Giao dịch trùng lặp bị bỏ qua (ràng buộc cơ sở dữ liệu).',
    'Unit name cannot exceed 150 characters.': 'Tên đơn vị không được vượt quá 150 ký tự.',
    'New password must be at least 6 characters long.': 'Mật khẩu mới phải dài ít nhất 6 ký tự.',
    'Carbs must be positive.': 'Carbs phải là số dương.',
    'Target body fat percentage must be between 1% and 80%.': 'Tỷ lệ mỡ cơ thể mục tiêu phải từ 1% đến 80%.',
    'Student or Coach does not exist.': 'Học viên hoặc Huấn luyện viên không tồn tại.',
    'Budget must be between 1,000 VND and 100,000,000 VND.': 'Ngân sách phải từ 1.000 VNĐ đến 100.000.000 VNĐ.',
    'Transfer content does not contain a valid payment code.': 'Nội dung chuyển khoản không chứa mã thanh toán hợp lệ.',
    'Meal template not found.': 'Không tìm thấy mẫu bữa ăn.',
    'Missing or invalid Authorization Apikey header.': 'Thiếu tiêu đề Authorization Apikey hoặc không hợp lệ.',
    'Invalid year.': 'Năm không hợp lệ.',
    'You need to check in for all weeks to graduate from the program.': 'Bạn cần check-in cho tất cả các tuần để hoàn thành chương trình.',
    'DefaultConnection is not configured.': 'DefaultConnection chưa được cấu hình.',
    'Cannot cancel a payment that has already been paid.': 'Không thể hủy khoản thanh toán đã được trả.',
    'Token is required.': 'Token là bắt buộc.',
    'Token not found.': 'Không tìm thấy token.',
    'Program does not exist.': 'Chương trình không tồn tại.',
    'Password reset successful.': 'Đặt lại mật khẩu thành công.',
    'OTP code is required.': 'Mã OTP là bắt buộc.',
    'Dinner time must be in HH:mm format.': 'Thời gian bữa tối phải ở định dạng HH:mm.',
    'Avatar URL is required.': 'URL hình đại diện là bắt buộc.',
    'Protein must be positive.': 'Protein phải là số dương.',
    'Payment order has expired.': 'Đơn hàng thanh toán đã hết hạn.',
    'food_id or recipe_id is required to schedule a meal.': 'Cần có food_id hoặc recipe_id để lên lịch bữa ăn.',
    'Missing or invalid X-SePay-Timestamp header.': 'Thiếu tiêu đề X-SePay-Timestamp hoặc không hợp lệ.',
    'Alerts are derived from meal plan compare and tracking data.': 'Cảnh báo được tạo từ so sánh kế hoạch bữa ăn và dữ liệu theo dõi.',
    'quantity_g or quantity is required to log a meal.': 'Bắt buộc có quantity_g hoặc quantity để ghi lại bữa ăn.',
    'Recommendation history deleted successfully.': 'Đã xóa lịch sử gợi ý thành công.',
    'Unsupported AI recommendation mode.': 'Chế độ gợi ý AI không được hỗ trợ.',
    'OTP code must be 6 characters long.': 'Mã OTP phải dài đúng 6 ký tự.',
    'Invalid SePay webhook signature.': 'Chữ ký webhook SePay không hợp lệ.',
    'Assistant message not found.': 'Không tìm thấy tin nhắn của trợ lý.',
    'The coach account is suspended.': 'Tài khoản huấn luyện viên đã bị đình chỉ.',
    'Only SePay payments can be cancelled via this endpoint.': 'Chỉ các khoản thanh toán SePay mới có thể bị hủy qua endpoint này.',
    'Your account has been locked.': 'Tài khoản của bạn đã bị khóa.',
    'Webhook processed successfully.': 'Đã xử lý webhook thành công.',
    'Date of birth is required to calculate your profile and target metrics.': 'Cần ngày sinh để tính toán hồ sơ và số đo mục tiêu của bạn.',
    'This plan is free. Use POST /api/UserSubscription/subscribe instead.': 'Gói này miễn phí. Vui lòng sử dụng đăng ký gói miễn phí.',
    'Waist measurement must be between 30cm and 250cm.': 'Số đo vòng eo phải từ 30cm đến 250cm.',
    'Could not generate a unique SePay payment code. Please try again.': 'Không thể tạo mã thanh toán SePay duy nhất. Vui lòng thử lại.',
    'No active device tokens found.': 'Không tìm thấy token thiết bị nào đang hoạt động.',
    'Specialty field is required.': 'Trường chuyên môn là bắt buộc.',
    'No active device tokens found for user.': 'Không tìm thấy token thiết bị hoạt động cho người dùng.',
    'Password recovery OTP has been sent to your email.': 'Mã OTP khôi phục mật khẩu đã được gửi đến email của bạn.',
    'Chest measurement must be between 30cm and 250cm.': 'Số đo vòng ngực phải từ 30cm đến 250cm.',
    'Full name is required.': 'Họ và tên là bắt buộc.',
    'Premium program not found.': 'Không tìm thấy chương trình Premium.',
    'A profile photo is required.': 'Cần có ảnh hồ sơ.',
    'AI Coach session deleted successfully.': 'Đã xóa phiên AI Coach thành công.',
    'You do not have any active Premium program.': 'Bạn không có chương trình Premium nào đang hoạt động.',
    'QuantityG or Quantity must be greater than 0.': 'Số lượng phải lớn hơn 0.',
    'You have already completed this quiz question.': 'Bạn đã hoàn thành câu hỏi trắc nghiệm này.',
    "You do not have access to this student's reports.": 'Bạn không có quyền truy cập vào các báo cáo của học viên này.',
    'Height must be between 50cm and 300cm.': 'Chiều cao phải từ 50cm đến 300cm.',
    'Coach data access revoked.': 'Quyền truy cập dữ liệu của huấn luyện viên đã bị thu hồi.',
    'Worker response is empty.': 'Phản hồi từ Worker trống.',
    'AI service returned an empty status response.': 'Dịch vụ AI trả về trạng thái trống.',
    'Your account has been successfully deactivated per Google Play privacy and data deletion policy.': 'Tài khoản của bạn đã bị vô hiệu hóa thành công theo chính sách bảo mật của Google Play.',
    'Invalid SePay transaction id.': 'ID giao dịch SePay không hợp lệ.',
    'Allergy not found.': 'Không tìm thấy dữ liệu dị ứng.',
    'Requested custom unit not found.': 'Không tìm thấy đơn vị tùy chỉnh yêu cầu.',
    'Activity log not found.': 'Không tìm thấy nhật ký hoạt động.',
    'Body fat percentage must be between 1% and 80%.': 'Tỷ lệ mỡ cơ thể phải từ 1% đến 80%.',
    'Successfully disconnected from Coach.': 'Đã ngắt kết nối thành công với Huấn luyện viên.',
    'Start date (from) cannot be greater than end date (to).': 'Ngày bắt đầu không thể lớn hơn ngày kết thúc.',
    'Alert dismissed successfully.': 'Đã loại bỏ cảnh báo thành công.',
    'Certificate name, issuer and image are required.': 'Tên chứng chỉ, tổ chức cấp và hình ảnh là bắt buộc.',
    'Removed from favorites successfully.': 'Đã xóa khỏi mục yêu thích thành công.',
    'Provider order code is required.': 'Mã đơn hàng của nhà cung cấp là bắt buộc.',
    'Student has not granted you access to their health data.': 'Học viên chưa cấp cho bạn quyền truy cập vào dữ liệu sức khỏe của họ.',
    'You do not have permission to access this report.': 'Bạn không có quyền truy cập vào báo cáo này.',
    'Connection request not found.': 'Không tìm thấy yêu cầu kết nối.',
    'Meal template has no items.': 'Mẫu bữa ăn không có mục nào.',
    'Alert acknowledged successfully.': 'Đã xác nhận cảnh báo thành công.',
    'At least one portfolio image is required.': 'Cần ít nhất một hình ảnh hồ sơ năng lực.',
    'Google account does not have an email address.': 'Tài khoản Google không có địa chỉ email.',
    'User does not exist.': 'Người dùng không tồn tại.',
    'Invalid operation.': 'Thao tác không hợp lệ.',
    'Connection request sent to Coach.': 'Đã gửi yêu cầu kết nối đến Huấn luyện viên.',
    'Invalid or expired refresh token.': 'Token làm mới không hợp lệ hoặc đã hết hạn.',
    'Target weight must be between 30kg and 300kg.': 'Cân nặng mục tiêu phải từ 30kg đến 300kg.',
    'Account type is required.': 'Loại tài khoản là bắt buộc.',
    'Weekly report not found.': 'Không tìm thấy báo cáo hàng tuần.',
    'Invalid month (must be between 1 and 12).': 'Tháng không hợp lệ (phải từ 1 đến 12).',
    'Weight is required.': 'Cân nặng là bắt buộc.',
    'This report was sent to another coach.': 'Báo cáo này đã được gửi cho một huấn luyện viên khác.',
    "Food applied to today's meal plan successfully.": 'Đã áp dụng món ăn vào kế hoạch hôm nay thành công.',
    'Breakfast time must be in HH:mm format.': 'Thời gian bữa sáng phải ở định dạng HH:mm.',
    'MealType must be Breakfast, Lunch, Dinner, or Snack.': 'Loại bữa ăn phải là Sáng, Trưa, Tối hoặc Ăn vặt.',
    'Fat must be positive.': 'Chất béo (Fat) phải là số dương.',
    'Professional headline is required.': 'Tiêu đề hồ sơ chuyên gia là bắt buộc.',
    'Paid subscriptions must use SePay. Subscribe: POST /api/payments/sepay/create-order. Renew: POST /api/payments/sepay/create-renew-order.': 'Đăng ký trả phí phải sử dụng SePay.',
    'You have an active Premium program. Please complete your current program before starting a new one.': 'Bạn có một chương trình Premium đang hoạt động. Vui lòng hoàn thành chương trình hiện tại trước khi bắt đầu chương trình mới.',
    'Review submitted. Student has been notified.': 'Đã gửi đánh giá. Học viên đã được thông báo.',
    'Invalid SePay webhook payload.': 'Dữ liệu webhook SePay không hợp lệ.',
    'Lunch time must be in HH:mm format.': 'Thời gian bữa trưa phải ở định dạng HH:mm.',
    'Email is already registered.': 'Email này đã được đăng ký.',
    'Each template item must reference Food/Recipe or contain an AI scan snapshot.': 'Mỗi mục mẫu phải liên kết đến Món ăn/Công thức hoặc chứa ảnh AI Scan.',
    'Email does not exist.': 'Email không tồn tại.',
    'Date of birth is required.': 'Ngày sinh là bắt buộc.',
    'Firebase is not initialized. Check Firebase credential configuration.': 'Firebase chưa được khởi tạo. Vui lòng kiểm tra cấu hình.',
    'Service fee is required.': 'Phí dịch vụ là bắt buộc.',
    'Subscription plan name already exists.': 'Tên gói đăng ký đã tồn tại.',
    'This request is not a mid-week or final weekly report.': 'Đây không phải là báo cáo giữa tuần hoặc cuối tuần.',
    'Invalid or missing user identity in token.': 'Danh tính người dùng trong token bị thiếu hoặc không hợp lệ.',
    'Amount must be greater than zero.': 'Số tiền phải lớn hơn 0.',
    'Payment order not found.': 'Không tìm thấy đơn hàng thanh toán.',
    'An identity verification image is required.': 'Cần có hình ảnh xác minh danh tính.',
    'Job not found.': 'Không tìm thấy công việc.',
    'Please verify your OTP before logging in.': 'Vui lòng xác minh mã OTP của bạn trước khi đăng nhập.',
    'Message not found.': 'Không tìm thấy tin nhắn.',
    'Original program details not found.': 'Không tìm thấy chi tiết chương trình gốc.',
    'No budget configuration found.': 'Không tìm thấy cấu hình ngân sách.',
    'Feedback type is required.': 'Loại phản hồi là bắt buộc.',
    'Payment order not found by transfer content.': 'Không tìm thấy đơn hàng thanh toán theo nội dung chuyển khoản.',
    'User id is invalid.': 'ID người dùng không hợp lệ.',
    'Invalid Google sign-in token.': 'Token đăng nhập Google không hợp lệ.',
    'Original ingredient not found.': 'Không tìm thấy nguyên liệu gốc.',
    'Action requires user confirmation.': 'Thao tác yêu cầu sự xác nhận của người dùng.',
    'This action type is reserved for the next implementation phase.': 'Loại thao tác này được dành riêng cho giai đoạn tiếp theo.',
    'Cannot create feedback event': 'Không thể tạo sự kiện phản hồi',
    'input_text and expected_output are required': 'input_text và expected_output là bắt buộc',
    'Cannot create training sample': 'Không thể tạo mẫu dữ liệu huấn luyện',
    'Sample not found': 'Không tìm thấy mẫu dữ liệu',
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

/// Tiện ích mở rộng giúp dễ dàng dịch data payload trên UI
extension DataTranslationExtension on String {
  String get translatedData => ApiMessageTranslator.translateData(this);
}
