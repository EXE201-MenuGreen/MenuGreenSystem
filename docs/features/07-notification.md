# 07. Notification

**Status:** API Done · UI Done (Settings + Inbox)
**Last updated:** 2026-07-09

**Related controllers:**
- `backend/MenuGreen.API/Controllers/NotificationController.cs`
- `backend/MenuGreen.API/Controllers/NotificationAdminController.cs`

**Related Flutter features:**
- `frontend/lib/features/notifications/`
- `frontend/lib/core/services/notification_handler.dart`

---

## 1. Overview

Hệ thống notification xử lý toàn bộ thông báo cho user:

- **Settings** — cấu hình kênh nhận (push/in-app), meal reminder, prep reminder.
- **Inbox** — danh sách notification với swipe actions, pagination, badge count.
- **Tracking** — đo lường open/click/action-complete cho analytics.
- **Re-engagement** — campaign nhắc user inactive.
- **Meal Plan Reminder** — push nhắc bữa ăn (liên kết với Meal Plan, xem [`03-meal-plan.md`](./03-meal-plan.md)).

---

## 2. Business Rules

### 2.1 Channels

- **Push** — qua FCM (Firebase Cloud Messaging).
- **In-app** — hiển thị trong InboxScreen + badge count trên tab.
- Channels độc lập: user có thể tắt push nhưng vẫn nhận in-app.

### 2.2 Notification Types

- **Meal Reminder** — nhắc trước giờ ăn (Breakfast/Lunch/Dinner/Snack) theo schedule.
- **Prep Reminder** — nhắc chuẩn bị nguyên liệu trước.
- **Goal Drift Alert** — cảnh báo calo/macro lệch mục tiêu (xem [`09-analytics.md`](./09-analytics.md)).
- **Re-engagement** — nhắc user inactive >N ngày.
- **System** — thông báo hệ thống (subscription, cập nhật app, ...).

### 2.3 Tracking

- `track/open` — ghi nhận user đã mở notification.
- `track/click` — ghi nhận user tap vào action trong notification.
- `track/action-complete` — ghi nhận user hoàn thành action (VD: log meal sau khi tap notification).

### 2.4 Read State

- Mỗi notification có state: `unread` / `read` / `opened` / `dismissed`.
- `PATCH /read-all` — đánh dấu tất cả đã đọc.
- `unread-count` — đếm số chưa đọc (cho badge UI).

---

## 3. API Endpoints

### 3.1 Settings

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Notification/settings` | Lấy settings hiện tại |
| `PUT` | `/api/Notification/settings` | Cập nhật settings |
| `POST` | `/api/Notification/settings/reset` | Reset về default |
| `GET` | `/api/Notification/channels` | Danh sách channels |

### 3.2 Inbox CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Notification?unreadOnly=` | Danh sách notification (lọc unread, không dùng page/pageSize) |
| `GET` | `/api/Notification/{id}` | Chi tiết notification |
| `GET` | `/api/Notification/unread-count` | Số chưa đọc |
| `PATCH` | `/api/Notification/{id}/read` | Đánh dấu đã đọc |
| `PATCH` | `/api/Notification/{id}/open` | Đánh dấu đã mở |
| `PATCH` | `/api/Notification/{id}/dismiss` | Dismiss notification |
| `PATCH` | `/api/Notification/read-all` | Đánh dấu tất cả đã đọc |
| `DELETE` | `/api/Notification/{id}` | Xóa notification |
| `DELETE` | `/api/Notification/batch` | Xóa nhiều (theo ids) |
| `DELETE` | `/api/Notification/range` | Xóa theo date range |

### 3.3 Send & Schedule

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Notification/meal-plan-remind` | Nhắc meal plan |
| `POST` | `/api/Notification/schedule-prep-reminder` | Nhắc chuẩn bị trước |
| `POST` | `/api/Notification/send` | Gửi notification (admin/system) |
| `POST` | `/api/Notification/send/bulk` | Gửi bulk cho danh sách user |
| `POST` | `/api/Notification/send/event` | Gửi tự động theo event trigger |
| `POST` | `/api/Notification/send/schedule` | Lên lịch gửi notification |
| `POST` | `/api/Notification/send/retry` | Retry notification gửi fail |

### 3.4 Tracking

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Notification/{id}/track/open` | Track open |
| `POST` | `/api/Notification/{id}/track/click` | Track click |
| `POST` | `/api/Notification/{id}/track/action-complete` | Track action complete |

### 3.5 Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Notification/analytics` | Tổng hợp open/click/conversion rate |
| `GET` | `/api/Notification/analytics/re-engagement` | Report re-engagement campaign (sent/open/click/action-complete) |

### 3.6 Re-engagement Campaigns

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Notification/campaigns` | Tạo campaign mới |
| `GET` | `/api/Notification/campaigns` | Danh sách campaigns |
| `GET` | `/api/Notification/campaigns/{id}` | Chi tiết campaign |
| `PUT` | `/api/Notification/campaigns/{id}` | Cập nhật campaign |
| `POST` | `/api/Notification/campaigns/{id}/run` | Kích hoạt campaign |
| `POST` | `/api/Notification/campaigns/{id}/pause` | Tạm dừng campaign |

**Tổng: 32 endpoint** (3 Settings + 10 Inbox + 7 Send & Schedule + 3 Tracking + 1 Analytics + 6 Campaigns + 2 Admin).
(Update 2026-07-08: thêm Campaigns CRUD + send subroutes. Update 2026-07-09: thêm §3.7 NotificationAdminController + sửa params notification list.)

### 3.7 Notification Admin (NotificationAdminController — AdminOnly)

|| Method | Endpoint | Description |
||--------|----------|-------------|
|| `POST` | `/api/admin/notifications/dispatch` | Trigger manual dispatch tất cả due notifications |
|| `GET` | `/api/admin/notifications/pending` | Pending notification stats (processed/sent/failed/skipped) |

**Tổng: 32 endpoint** (3 Settings + 10 Inbox + 7 Send & Schedule + 3 Tracking + 1 Analytics + 6 Campaigns + 2 Admin).

---

## 4. UI Components

| Component | File | Status |
|-----------|------|--------|
| NotificationRepository | `features/notifications/repositories/notification_repository.dart` | Done |
| NotificationProvider | `features/notifications/providers/notification_provider.dart` | Done |
| NotificationSettingsScreen | `features/notifications/views/notification_settings_screen.dart` | Done |
| NotificationInboxScreen | `features/notifications/views/notification_inbox_screen.dart` | Done |
| NotificationTile | `features/notifications/widgets/notification_tile.dart` | Done |
| EmptyNotificationState | `features/notifications/widgets/empty_notification_state.dart` | Done |
| NotificationHandler (FCM) | `core/services/notification_handler.dart` | Done |
| NotificationModels | `features/notifications/models/notification_models.dart` | Done |
| Models barrel | `features/notifications/models/models.dart` | Done |
| notifications.dart (barrel) | `features/notifications/notifications.dart` | Done |

**Tổng: 2 screens, 2 widgets, 1 FCM handler.**

---

## 5. Navigation Flow

```
MainScreen (Tab index 4 hoặc trong Profile)
└── NotificationInboxScreen
        ├── Badge count (unread-count)
        ├── Swipe left → Delete (DELETE)
        ├── Swipe right → Mark as read (PATCH /read)
        ├── Tap → NotificationTile chi tiết
        │       ├── Action button (nếu có) → track/click → navigate
        │       └── Auto PATCH /open
        └── EmptyState → "Chưa có thông báo"

NotificationSettingsScreen (từ Profile)
└── Card-based UI:
        ├── Meal Reminder toggle + time pickers
        ├── Prep Reminder toggle + advance minutes
        ├── Push channel toggle
        ├── In-app channel toggle
        └── Reset button → POST /settings/reset
```

---

## 6. Data Models (rút gọn)

```
Notification
├── Id, UserId, Type (MealReminder / PrepReminder / GoalDrift / ReEngagement / System)
├── Title, Body, ImageUrl?
├── ActionUrl? (deep link)
├── Channel (Push / InApp)
├── Status (Unread / Read / Opened / Dismissed)
├── ScheduledAt, SentAt?
├── OpenedAt?, ClickedAt?, ActionCompletedAt?
└── Metadata (JSON)

NotificationSettings
├── UserId
├── ChannelsEnabled (Push: bool, InApp: bool)
├── MealReminderEnabled
├── MealReminderTimes (Breakfast/Lunch/Dinner/Snack)
├── PrepReminderEnabled
├── PrepReminderAdvanceMinutes
└── QuietHoursStart, QuietHoursEnd?

NotificationAnalytics
├── TotalSent, TotalDelivered
├── TotalOpened, TotalClicked
├── TotalActionCompleted
├── OpenRate, ClickRate, ConversionRate
└── ByType (breakdown)
```

---

## 7. Related Documents

- Meal Plan (kích hoạt reminder): [`03-meal-plan.md`](./03-meal-plan.md)
- Goal Drift Alert (trigger notification): [`09-analytics.md`](./09-analytics.md)
- Re-engagement (inactive user): [`09-analytics.md`](./09-analytics.md)
- User workflow cũ (Notification UI): [`../_archive/root-readmes/README_WORKFLOW_API_STATUS.md` → 2.9](../_archive/root-readmes/README_WORKFLOW_API_STATUS.md)