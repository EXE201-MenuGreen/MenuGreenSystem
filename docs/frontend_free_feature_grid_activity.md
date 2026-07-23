# Hoạt động Frontend: Khung tính năng dành cho người dùng Free

## 1. Mục tiêu

Điều chỉnh khung tính năng trên Home để người dùng Free chỉ thấy các chức năng họ có thể sử dụng. Office và Gym/PT được tách khỏi danh sách công cụ Free; nếu cần upsell, chúng xuất hiện trong một khu vực giới thiệu gói riêng và có trạng thái rõ ràng.

Frontend chịu trách nhiệm trình bày trải nghiệm phù hợp, nhưng không thay thế authorization của backend.

## 2. Danh sách tính năng Free

| Thứ tự | Nhãn đề xuất | Màn hình/hoạt động |
|---:|---|---|
| 1 | Hôm nay ăn gì? | Gợi ý bữa ăn cá nhân hóa |
| 2 | Tìm món ăn | Tìm kiếm và khám phá món |
| 3 | Quét & tính calo | Quét nguyên liệu, ước tính dinh dưỡng |
| 4 | Kế hoạch ăn | Tạo và quản lý kế hoạch ăn |
| 5 | Cân nặng | Ghi cân nặng bằng bottom sheet |
| 6 | Ăn ngoài? | Ước tính calo và ghi nhanh bữa ăn ngoài |
| 7 | Yêu thích | Danh sách món yêu thích |
| 8 | Thực đơn đã lưu | Quản lý mẫu thực đơn |
| 9 | Sở thích Việt Nam | Cá nhân hóa vùng miền và khẩu vị |
| 10 | Thay thế nguyên liệu | Quản lý cấu hình thay thế |
| 11 | Kế hoạch vs Thực tế | Phân tích độ bám sát kế hoạch |
| 12 | Góc dinh dưỡng | Nội dung micro-learning |
| 13 | An toàn & Tuân thủ | Consent, quyền dữ liệu và báo cáo sự cố |

Không đưa `Gói Gym/PT` và `Không gian Office` vào grid “Tất cả tính năng” của người dùng Free.

## 3. Bố cục đề xuất

### Shortcut trên Home

Hiển thị 7 chức năng có tần suất sử dụng cao và một nút mở rộng:

```text
Hôm nay ăn gì? | Tìm món ăn | Quét & tính calo | Kế hoạch ăn
Cân nặng       | Ăn ngoài?  | Yêu thích         | Khác
```

### Bottom sheet “Tất cả tính năng”

Hiển thị 13 tính năng Free theo thứ tự tại mục 2. Bottom sheet vẫn dùng lưới 4 cột, có thể kéo và cuộn trên màn hình nhỏ.

### Khu vực giới thiệu gói

Nếu sản phẩm cần upsell, thêm card riêng phía dưới grid:

```text
Khám phá gói chuyên biệt
Gym/PT · Office
```

- Free bấm vào card: mở trang giới thiệu/nâng cấp.
- Có Gym/PT: hiển thị card hoặc panel Gym đang hoạt động.
- Có Office: hiển thị panel Office đang hoạt động.
- Có cả hai: hiển thị cả hai khu vực hoặc một hub “Gói của tôi”.

Không trình bày shortcut trả phí giống hệt shortcut Free vì dễ tạo kỳ vọng sai.

## 4. Nguồn dữ liệu quyền truy cập

Khi Home được khởi tạo hoặc refresh:

1. Gọi `GET /api/UserSubscription/me/active` hoặc endpoint entitlement tổng hợp.
2. Chuyển response thành một model quyền truy cập duy nhất.
3. Truyền model này cho `QuickActionGrid`.
4. Lọc action theo entitlement trước khi render.
5. Khi API quyền bị lỗi, fallback an toàn về Free; không tự mở quyền Office/Gym.

Model đề xuất:

```dart
class FeatureAccess {
  const FeatureAccess({
    required this.hasOffice,
    required this.hasGym,
  });

  final bool hasOffice;
  final bool hasGym;

  static const free = FeatureAccess(hasOffice: false, hasGym: false);
}
```

Không dùng `_isOfficeMode` làm bằng chứng người dùng đã mua Office. Mode cá nhân hóa và entitlement thanh toán là hai khái niệm khác nhau.

## 5. Thay đổi cấu trúc `QuickActionGrid`

Mỗi action nên khai báo nhóm quyền thay vì viết điều kiện riêng lẻ:

```dart
enum FeatureAudience { free, office, gym }

class QuickActionItem {
  const QuickActionItem({
    required this.type,
    required this.label,
    required this.audience,
    // icon, colors...
  });

  final QuickActionType type;
  final String label;
  final FeatureAudience audience;
}
```

Quy tắc lọc:

```dart
bool canShow(QuickActionItem action, FeatureAccess access) {
  return switch (action.audience) {
    FeatureAudience.free => true,
    FeatureAudience.office => access.hasOffice,
    FeatureAudience.gym => access.hasGym,
  };
}
```

Với quyết định tách upsell khỏi grid Free, danh sách “Tất cả tính năng” chỉ nhận các action `free`. Các action Office/Gym được dùng trong panel riêng khi đã có quyền.

## 6. Điều hướng và trạng thái

- Mỗi shortcut Free tiếp tục mở màn hình hiện có.
- `Cân nặng` tiếp tục mở `WeightLogSheet`.
- Đổi nhãn `Tính calo` thành `Quét & tính calo` để khớp với `IngredientScanScreen`.
- Trong lúc tải entitlement, có thể render grid Free ngay để tránh layout nhảy mạnh.
- Sau khi mua hoặc kích hoạt gói, gọi lại `refreshSubscriptionAccess()` và cập nhật Home mà không yêu cầu đăng nhập lại.
- Backend trả `403` tại màn hình trả phí: đưa người dùng về trạng thái an toàn, refresh entitlement và hiển thị thông báo phù hợp.

## 7. Khả năng truy cập và UI

- Mỗi action có `Semantics` hoặc tooltip mô tả ngắn.
- Vùng bấm tối thiểu 48 × 48 logical pixels.
- Nhãn tối đa hai dòng nhưng không được làm mất nghĩa quan trọng.
- Kiểm tra text scale lớn và màn hình hẹp.
- Không chỉ dùng màu sắc để biểu thị Free/đã khóa.
- Giữ thứ tự action ổn định giữa các lần mở ứng dụng.

## 8. Kiểm thử widget

- Free thấy đủ 13 action trong bottom sheet.
- Free không thấy `Gói Gym/PT` và `Không gian Office` trong grid.
- Shortcut Home có đúng 7 action Free và nút `Khác`.
- Bấm từng shortcut điều hướng đúng màn hình; `Cân nặng` mở bottom sheet.
- `hasOffice = true` hiển thị panel Office, không làm biến đổi quyền Gym.
- `hasGym = true` hiển thị panel Gym, không làm biến đổi quyền Office.
- Lỗi tải subscription fallback về `FeatureAccess.free`.
- Refresh sau kích hoạt gói cập nhật giao diện.
- Nhãn `Quét & tính calo` hiển thị đúng tiếng Việt và không overflow ở kích thước màn hình mục tiêu.

## 9. Tiêu chí hoàn thành

- Khung Free không còn shortcut Office hoặc Gym/PT.
- 13 chức năng Free vẫn truy cập được từ “Tất cả tính năng”.
- 7 shortcut chính phản ánh các tác vụ thường dùng nhất.
- Quyền Office và Gym được suy ra từ subscription/entitlement, không từ mode giao diện.
- Upsell, nếu có, nằm ở khu vực riêng và có nhãn rõ ràng.
- Widget test bao phủ các trạng thái Free, Office, Gym và lỗi API.

## 10. Tệp liên quan

- `frontend/lib/features/home/views/home_view.dart`
- `frontend/lib/features/home/widgets/quick_action_grid.dart`
- `frontend/lib/features/home/widgets/gymer_package_card.dart`
- `frontend/lib/features/office/widgets/office_home_panel.dart`
- `frontend/lib/features/subscription/utils/subscription_access.dart`
- `frontend/lib/features/subscription/repositories/user_subscription_repository.dart`

