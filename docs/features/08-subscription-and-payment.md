# 08. Subscription & Payment

**Status:** API Done · UI Done (100%)
**Last updated:** 2026-07-24

**Related controllers:**
- `backend/MenuGreen.API/Controllers/SubscriptionPlanController.cs` (Admin CRUD)
- `backend/MenuGreen.API/Controllers/UserSubscriptionController.cs` (User workflow)
- `backend/MenuGreen.API/Controllers/SepayController.cs` (Payment gateway)

**Related services:**
- `backend/MenuGreen.BusinessLogicLayer/Services/FeatureAccessService.cs` (Feature access resolver)
- `backend/MenuGreen.BusinessLogicLayer/Services/FeatureAccessResolver.cs` (Feature groups)

**Related Flutter feature:** `frontend/lib/features/subscription/`

> **2026-07-24 — Phạm vi gói:** MenuGreen hiện chỉ cung cấp **4 gói** chính: **Free (Cơ bản)**, **Casual**, **Gym/PT**, **Office**. Không còn bán gói `Pro` riêng; người dùng muốn trải nghiệm đầy đủ tính năng Casual + Gym/PT + Coach + AI cần kích hoạt cả hai gói Casual và Gym/PT.

---

## 1. Overview

Quản lý gói thành viên và thanh toán qua cổng SePay:

- **Subscription Plans** — CRUD gói (Free, Casual, Gym/PT, Office) do Admin quản lý.
- **User Subscription** — subscribe/renew/cancel gói (miễn phí active ngay, trả phí qua SePay).
- **SePay Payment** — tạo QR thanh toán, webhook xác thực giao dịch.
- **Feature Access** — quyền truy cập tính năng dựa trên subscription plan.

---

## 2. Business Rules

### 2.1 Subscription Plan (Admin)

- Plans có các trường: `Name`, `PriceVnd`, `DurationDays`, `FeatureGroup`, `Features[]`, `IsActive`.
- Admin có thể CRUD plans; user chỉ thấy plans active.
- Plans được nhóm theo `FeatureGroup`: `free`, `casual`, `gym`, `office`.

### 2.2 Feature Groups & Access

Hệ thống `FeatureAccessResolver` quản lý quyền truy cập dựa trên subscription:

| Feature Group | Entitlements | Mô tả |
|---------------|--------------|--------|
| `free` | `free_features` | Luôn có (mặc định) |
| `casual` | `casual_features` | Gói Casual - vòng quay, quick-log, micro-learning |
| `office` | `office_features` | Gói Office - grocery list, scan meals, budget |
| `gym` | `gym_features` + `coach_access` + `ai_features` | Gói Gym/PT - PT review, coach, AI |

**Cơ chế hoạt động:**
- Mỗi subscription có `FeatureGroup` xác định quyền truy cập.
- `FeatureAccessResolver.Resolve()` tổng hợp tất cả active subscriptions của user.
- Tier được xác định: `free` → `casual/office/gym` → `multi` (nhiều nhóm).
- `ExpiresAt` = ngày hết hạn subscription trả phí gần nhất.

### 2.3 User Subscription Workflow

- **Subscribe Free:** gói miễn phí → kích hoạt ngay, không qua payment.
- **Subscribe Paid:** gói trả phí → tạo SePay order → user quét QR → webhook xác nhận → kích hoạt gói.
- **Renew:** tương tự subscribe, dùng `create-renew-order`.
- **Cancel:** hủy subscription hiện tại (status = cancelled, vẫn dùng đến hết hạn).
- **Auto-renew:** có thể bật trong settings (TODO nếu chưa có).

### 2.4 SePay Payment

- Tạo order với số tiền VND → trả QR code (SePay VietQR).
- Webhook từ SePay gọi về khi user thanh toán thành công.
- Polling status: `GET /api/payments/sepay/pending` để check đơn đang chờ.

### 2.5 Premium Features Gating

- AI Assistant yêu cầu entitlement `ai_features` (Gym/PT).
- Coach features yêu cầu entitlement `coach_access`.
- Check entitlement tại backend qua `FeatureAccessService.HasEntitlementAsync()`.
- Không còn gói "Pro" riêng: người dùng muốn full feature cần kích hoạt **cả Casual + Gym/PT** (hoặc dùng Office cộng thêm Gym/PT). `FeatureAccessResolver` không còn nhánh mapping `pro/premium/vip/gold`.

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
| `GET` | `/api/UserSubscription/me/active` | Tất cả subscriptions active (không chỉ mới nhất) |
| `GET` | `/api/UserSubscription/me/entitlements` | Feature access tổng hợp |
| `GET` | `/api/UserSubscription/{id}` | Chi tiết subscription |
| `GET` | `/api/UserSubscription/me/history` | Lịch sử subscription |

> **2026-07-23:** Thêm 2 endpoints mới: `me/active` và `me/entitlements`.

### 3.3 SePay Payment

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/payments/sepay/create-order` | Tạo đơn mới |
| `POST` | `/api/payments/sepay/create-renew-order` | Tạo đơn gia hạn |
| `GET` | `/api/payments/sepay/pending` | Đơn đang chờ |
| `GET` | `/api/payments/sepay/{paymentId}` | Trạng thái đơn |
| `POST` | `/api/payments/sepay/webhook` | Webhook SePay xác thực (AllowAnonymous) |

**Tổng: 22 endpoint** (8 SubscriptionPlan + 9 UserSubscription + 5 SePay).

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
        ├── Hiển thị plans active (có FeatureGroup)
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
├── FeatureGroup (free/casual/gym/office)
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

FeatureAccessResponse (2026-07-23)
├── Tier (free/casual/office/gym/multi)
├── Entitlements[] (free_features/casual_features/office_features/gym_features/coach_access/ai_features)
├── FeatureGroups[] (tên các feature group đang active)
└── ExpiresAt (ngày hết hạn gần nhất)
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.5 Subscriptions & Payments).

---

## 7. Feature Access Resolution

### 7.1 FeatureAccessResolver Logic

```csharp
// Entitlements luôn có
entitlements.Add("free_features");

// Casual subscription → casual_features
if (group == "casual" || planName.Contains("casual"))
    entitlements.Add("casual_features");

// Office subscription → office_features
if (group == "office" || planName.Contains("office"))
    entitlements.Add("office_features");

// Gym subscription → gym_features + coach_access + ai_features
if (group == "gym" || planName.Contains("gym"))
    entitlements.Add("gym_features");
    entitlements.Add("coach_access");
    entitlements.Add("ai_features");
```

> Không còn khối mapping riêng cho `pro/premium/vip/gold`. Người dùng muốn trải nghiệm đầy đủ phải kích hoạt cả gói Casual lẫn Gym/PT.

### 7.2 Using Feature Access in Backend

```csharp
// Kiểm tra entitlement trong service
var hasAccess = await _featureAccessService.HasEntitlementAsync(userId, "ai_features");

// Lấy toàn bộ feature access
var access = await _featureAccessService.GetAsync(userId);
// access.Tier = "gym" / "casual" / "free" / "multi"
// access.Entitlements = ["free_features", "gym_features", "coach_access", "ai_features"]
```

---

## 8. Database Migration Scripts

| Script | Mô tả |
|--------|--------|
| `06_subscription_plans.sql` | Bảng subscription_plans (chỉ seed Free, Casual, Gym/PT, Office — 2 plan Pro đã xóa hẳn 2026-07-24) |
| `07_subscriptions.sql` | Bảng subscriptions (seed dùng 4 gói chính) |
| `08_user_subscriptions.sql` | Bảng user_subscriptions (seed dùng 4 gói chính) |
| `57_gymer_subscription_plan.sql` | Gym/PT subscription plan (FeatureGroup='gym') |
| `58_casual_subscription_plan.sql` | Casual subscription plan (FeatureGroup='casual') |

> Hai plan `Pro Tháng/GYM` và `Pro Năm` đã được **xóa hẳn** khỏi `06_subscription_plans.sql` (2026-07-24). Các dòng INSERT tham chiếu trong `07_subscriptions.sql` và `08_user_subscriptions.sql` cũng đã được lọc bỏ. Nếu DB production cũ đã từng seed 2 plan Pro, cần chạy thêm migration dọn dẹp:
>
> ```sql
> -- Migration dọn dẹp DB production cũ (chạy một lần, idempotent)
> DELETE FROM user_subscriptions
> WHERE "SubscriptionPlanId" IN (
>     '10000000-0000-0000-0000-000000000002',
>     '10000000-0000-0000-0000-000000000003'
> );
> DELETE FROM subscriptions
> WHERE "PlanId" IN (
>     '10000000-0000-0000-0000-000000000002',
>     '10000000-0000-0000-0000-000000000003'
> );
> DELETE FROM subscription_plans
> WHERE "Id" IN (
>     '10000000-0000-0000-0000-000000000002',
>     '10000000-0000-0000-0000-000000000003'
> );
> ```

---

## 9. Related Documents

- AI Premium gating: [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)
- Coach features: [`17-coaches.md`](./17-coaches.md)
- Office workflow: [`../workflow/office_workflow.md`](../workflow/office_workflow.md)
- Gym workflow: [`../workflow/gymer_workflow.md`](../workflow/gymer_workflow.md)
- User workflow cũ (mục 4.11): [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)
- API status cũ (mục 2.8): [`../_archive/root-readmes/README_WORKFLOW_API_STATUS.md`](../_archive/root-readmes/README_WORKFLOW_API_STATUS.md)

---

## 10. Changelog

| Ngày | Thay đổi |
|------|-----------|
| 2026-07-08 | Tạo file canonical |
| 2026-07-23 | Thêm Feature Access system, endpoints `me/active` và `me/entitlements`, FeatureAccessResolver, FeatureGroup documentation |
| 2026-07-24 | Bỏ gói `Pro` khỏi catalog và tài liệu. `FeatureAccessResolver` không còn map `pro/premium/vip/gold`. Hai plan `Pro Tháng/GYM` và `Pro Năm` đã được **xóa hẳn** khỏi `06_subscription_plans.sql` (cùng với các dòng seed tham chiếu trong `07_subscriptions.sql` và `08_user_subscriptions.sql`). Phạm vi hỗ trợ: **Free, Casual, Gym/PT, Office** |
