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

---

## [RESOLVED] Cancel subscription không cancel pending payment

**Date:** 2026-08-12
**Status:** Resolved
**Severity:** High

### Description
User nhấn "Hủy gói" trên màn hình gói dịch vụ, sau đó tạo gói mới → Bị lỗi "You already have a pending SePay payment".

### Root Cause
`UserSubscriptionService.CancelAsync()` chỉ cancel subscription nhưng **KHÔNG cancel payment PENDING** liên quan. Payment PENDING vẫn tồn tại trong DB, nên khi tạo order mới sẽ bị block bởi `EnsureNoPendingSepayPaymentAsync()`.

### Environment
- Backend .NET API
- Tables: `user_subscriptions`, `payments`

### Fix Applied

#### Backend
1. **UserSubscriptionService.cs** - Update `CancelAsync()`:
   - Thêm logic tìm và cancel tất cả payment PENDING của subscription
   ```csharp
   var pendingPayments = await _unitOfWork.Payments.FindAsync(
       p => p.UserSubscriptionId == subscription.Id && p.Status == "PENDING" && p.Provider == "SEPAY");
   foreach (var payment in pendingPayments)
   {
       payment.Status = "CANCELLED";
       payment.UpdatedAt = DateTimeOffset.UtcNow;
       _unitOfWork.Payments.Update(payment);
   }
   ```

2. **SepayPaymentService.cs** - Update `CancelOrderAsync()`:
   - Tách riêng subscription cancel để không block payment cancel
   - Đảm bảo `CompleteAsync()` luôn được gọi

3. **SepayController.cs** - Cải thiện error handling:
   - Hiển thị chi tiết lỗi inner exception

4. **database/63_add_cancelled_payment_status.sql** - Migration thêm CANCELLED vào CHECK constraint

5. **database/64_cleanup_pending_payments.sql** - Script cleanup:
   - Query xem pending payments
   - UPDATE cancel pending payments cho cancelled subscriptions

#### Production Deployment Steps
1. Chạy migration 63 (nếu chưa có):
   ```sql
   ALTER TABLE payments DROP CONSTRAINT IF EXISTS CK_payments_status;
   ALTER TABLE payments ADD CONSTRAINT CK_payments_status 
       CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));
   ```

2. Cleanup pending payments cũ:
   ```sql
   UPDATE payments
   SET "Status" = 'CANCELLED', "UpdatedAt" = NOW()
   WHERE "Provider" = 'SEPAY' AND "Status" = 'PENDING'
   AND "UserSubscriptionId" IN (
       SELECT "Id" FROM user_subscriptions WHERE "Status" = 'Cancelled'
   );
   ```

3. Deploy backend code mới
