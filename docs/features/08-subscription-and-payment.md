# 08. Subscription & Payment

**Status:** API Done · UI Done (100%)
**Last updated:** 2026-07-08

**Related controllers:**
- `backend/MenuGreen.API/Controllers/SubscriptionPlanController.cs` (Admin CRUD)
- `backend/MenuGreen.API/Controllers/UserSubscriptionController.cs` (User workflow)
- `backend/MenuGreen.API/Controllers/SepayController.cs` (Payment gateway)

**Related Flutter feature:** `frontend/lib/features/subscription/`

---

## 1. Overview

Quản lý gói thành viên và thanh toán qua cổng SePay:

- **Subscription Plans** — CRUD gói (Free, Premium, Pro) do Admin quản lý.
- **User Subscription** — subscribe/renew/cancel gói (miễn phí active ngay, trả phí qua SePay).
- **SePay Payment** — tạo QR thanh toán, webhook xác thực giao dịch.
- **Subscription History** — lịch sử giao dịch, metrics cho Admin.

---

## 2. Business Rules

### 2.1 Subscription Plan (Admin)

- Plans có các trường: `Name`, `PriceVnd`, `DurationDays`, `Features[]`, `IsActive`.
- Admin có thể CRUD plans; user chỉ thấy plans active.

### 2.2 User Subscription Workflow

- **Subscribe Free:** gói miễn phí → kích hoạt ngay, không qua payment.
- **Subscribe Paid:** gói trả phí → tạo SePay order → user quét QR → webhook xác nhận → kích hoạt gói.
- **Renew:** tương tự subscribe, dùng `create-renew-order`.
- **Cancel:** hủy subscription hiện tại (status = cancelled, vẫn dùng đến hết hạn).
- **Auto-renew:** có thể bật trong settings (TODO nếu chưa có).

### 2.3 SePay Payment

- Tạo order với số tiền VND → trả QR code (SePay VietQR).
- Webhook từ SePay gọi về khi user thanh toán thành công.
- Polling status: `GET /api/payments/sepay/pending` để check đơn đang chờ.

### 2.4 Premium Features Gating

- AI Assistant có thể yêu cầu Premium (xem [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)).
- Check entitlement tại backend trước khi thực thi action premium.

---

## 3. API Endpoints

### 3.1 Subscription Plan (Admin)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/SubscriptionPlan?isActive=` | Lấy tất cả plans (Admin, lọc isActive) |
| `GET` | `/api/SubscriptionPlan/{id}` | Chi tiết plan |
| `GET` | `/api/SubscriptionPlan/{id}/features` | Features của plan (AllowAnonymous) |
| `GET` | `/api/SubscriptionPlan/{id}/status` | Trạng thái plan (active/inactive) |
| `POST` | `/api/SubscriptionPlan` | Tạo plan (Admin) |
| `PUT` | `/api/SubscriptionPlan/{id}` | Cập nhật plan (Admin) |
| `DELETE` | `/api/SubscriptionPlan/{id}` | Xóa plan (Admin) |
| `PATCH` | `/api/SubscriptionPlan/{id}/status` | Cập nhật status (Admin) |

### 3.2 User Subscription (User)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/UserSubscription/plans` | Plans active (cho user) |
| `POST` | `/api/UserSubscription/subscribe` | Subscribe gói miễn phí |
| `POST` | `/api/UserSubscription/renew` | Renew gói miễn phí |
| `POST` | `/api/UserSubscription/cancel` | Cancel gói hiện tại |
| `GET` | `/api/UserSubscription/me` | Subscription hiện tại |
| `GET` | `/api/UserSubscription/{id}` | Chi tiết subscription |
| `GET` | `/api/UserSubscription/me/history` | Lịch sử subscription |

### 3.3 SePay Payment

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/payments/sepay/create-order` | Tạo đơn mới |
| `POST` | `/api/payments/sepay/create-renew-order` | Tạo đơn gia hạn |
| `GET` | `/api/payments/sepay/pending` | Đơn đang chờ |
| `GET` | `/api/payments/sepay/{paymentId}` | Trạng thái đơn |
| `POST` | `/api/payments/sepay/webhook` | Webhook SePay xác thực (AllowAnonymous) |

**Tổng: 20 endpoint** (8 SubscriptionPlan + 7 UserSubscription + 5 SePay).

---

## 4. UI Components

| Component | File | Status |
|-----------|------|--------|
| UpgradePlanScreen | `features/subscription/views/upgrade_plan_screen.dart` | Done |
| SePayPaymentScreen | `features/subscription/views/sepay_payment_screen.dart` | Done |
| SePayPaymentSuccessScreen | `features/subscription/views/sepay_payment_success_screen.dart` | Done |
| UserSubscriptionRepository | `features/subscription/repositories/user_subscription_repository.dart` | Done |
| SePayPaymentRepository | `features/subscription/repositories/sepay_payment_repository.dart` | Done |
| SubscriptionModels | `features/subscription/models/subscription_models.dart` | Done |
| SePayModels | `features/subscription/models/sepay_models.dart` | Done |

**Tổng: 3 screens, 2 repositories.**

---

## 5. Navigation Flow

```
ProfileScreen
└── "Quản lý gói" → UpgradePlanScreen
        ├── Hiển thị plans active
        ├── Plan miễn phí → POST /subscribe → activate → back to Profile
        └── Plan trả phí → SePayPaymentScreen
                ├── Tạo order → POST /create-order
                ├── Hiển thị QR code
                ├── Polling status (mỗi 3s) → GET /{paymentId}
                ├── Polling /pending để đồng bộ
                └── Success → SePayPaymentSuccessScreen
                        └── "Về trang chủ" → MainScreen
```

---

## 6. Data Models (rút gọn)

```
SubscriptionPlan
├── Id, Name, Description
├── PriceVnd, DurationDays
├── Features[] (string)
├── IsActive, DisplayOrder
└── CreatedAt, UpdatedAt

UserSubscription
├── Id, UserId, PlanId
├── Status (Active / Expired / Cancelled / Pending)
├── StartDate, EndDate
├── AutoRenew
├── CancelledAt?
└── CreatedAt, UpdatedAt

SepayTransaction
├── Id, UserId, SubscriptionId
├── AmountVnd, OrderCode
├── Status (Pending / Paid / Failed / Refunded)
├── QrCodeUrl, QrData
├── PaidAt?
├── WebhookPayload (JSON)
└── CreatedAt
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.5 Subscriptions & Payments).

---

## 7. Related Documents

- AI Premium gating: [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)
- User workflow cũ (mục 4.11): [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)
- API status cũ (mục 2.8): [`../_archive/root-readmes/README_WORKFLOW_API_STATUS.md`](../_archive/root-readmes/README_WORKFLOW_API_STATUS.md)