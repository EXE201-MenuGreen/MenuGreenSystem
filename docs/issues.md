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
