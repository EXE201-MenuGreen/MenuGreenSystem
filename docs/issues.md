# Issues Log

## [RESOLVED] SepayPaymentScreen resume order sai plan khi chuyển gói

**Date:** 2026-08-12
**Status:** Resolved
**Severity:** High

### Description
Khi user nhấn đăng ký gói Office (80.000đ), không thanh toán, sau đó chuyển sang đăng ký gói Gym/PT (120.000đ), màn hình QR hiển thị số tiền 80.000đ của gói Office thay vì 120.000đ.

### Root Cause
Hàm `_pickPendingOrder` trong `sepay_payment_screen.dart` có fallback logic lấy bất kỳ subscribe order nào khi không tìm thấy order đúng plan. Khi user chuyển sang gói mới, order cũ (Office) được resume sai.

### Environment
- Frontend Flutter app
- SepayPaymentScreen - subscription payment flow

### Fix Applied
File: `frontend/lib/features/subscription/views/sepay_payment_screen.dart`
- Hàm `_pickPendingOrder`:
  - Bỏ fallback `for (final o in orders) { if (o.isSubscribeOrder) return o; }`
  - Bỏ fallback `for (final o in orders) { if (o.isRenewOrder) return o; }`
  - Bỏ fallback `return orders.isNotEmpty ? orders.first : null;`
  - Thay bằng `return null` khi không tìm thấy order đúng plan/subscription

### Attempts
- [x] Fix logic `_pickPendingOrder` - chỉ resume order khi planId/subscriptionId khớp chính xác

## [RESOLVED] Không tạo được order mới khi có pending order của gói khác

**Date:** 2026-08-12
**Status:** Resolved
**Severity:** High

### Description
Khi user có order pending của gói Office (80.000đ) và muốn đăng ký gói Gym/PT (120.000đ), API trả lỗi "You already have a pending SePay payment" và frontend hiển thị lỗi thay vì cho phép tạo order mới.

### Root Cause
Backend không có API để cancel pending order, nên khi user muốn chuyển sang gói khác thì bị chặn.

### Fix Applied

#### Backend
1. **ISepayPaymentService.cs** - Thêm method interface:
   ```csharp
   Task CancelOrderAsync(Guid userId, Guid paymentId);
   ```

2. **SepayPaymentService.cs** - Implement method:
   ```csharp
   public async Task CancelOrderAsync(Guid userId, Guid paymentId)
   ```

3. **SepayController.cs** - Thêm endpoint:
   ```csharp
   [HttpDelete("{paymentId:guid}")]
   ```

#### Frontend
1. **api_endpoints.dart** - Thêm endpoint:
   ```dart
   static String sepayCancelOrder(String paymentId) =>
       '$baseUrl/payments/sepay/$paymentId';
   ```

2. **sepay_payment_repository.dart** - Thêm method:
   ```dart
   Future<({bool success, String message})> cancelOrder(String paymentId)
   ```

3. **sepay_payment_screen.dart** - Logic xử lý:
   - Thêm `_cancelPendingOrderForDifferentPlan()` - tìm và cancel pending order khác plan
   - Thêm `_isPendingOrderError()` - kiểm tra lỗi pending order
   - Thêm `_createOrderAfterCancel()` - tạo order sau khi cancel thành công
   - Update `_createOrder()` - khi gặp lỗi pending order, tự động cancel và retry

### User Flow sau fix
1. User có order Office pending (80.000đ)
2. User chọn đăng ký Gym/PT (120.000đ)
3. Frontend phát hiện có pending order khác plan → Tự động cancel order Office
4. Frontend gọi API tạo order mới cho Gym/PT
5. QR hiển thị đúng giá 120.000đ
