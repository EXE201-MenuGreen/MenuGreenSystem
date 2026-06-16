# README: WORKFLOW API STATUS - CHƯA ĐỦ API

**Cập nhật:** 2026-06-16

Tài liệu này ghi nhận chi tiết trạng thái API của từng workflow, so sánh **API cần có** (theo thiết kế) với **API đã có** (trong codebase) và liệt kê **API còn thiếu** cần triển khai thêm.

---

## Mục lục

1. [2.5 Meal Plan](#25-meal-plan)
2. [2.6 Recommendation](#26-recommendation)
3. [2.7 AI Assistant](#27-ai-assistant)
4. [2.9 Notification](#29-notification)
5. [2.10 Analytics](#210-analytics)

---

## 2.5 Meal Plan

**File Controller:** `backend/MenuGreen.API/Controllers/MealPlanController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Meal plan header CRUD | ✅ Hoàn tất | |
| B. Meal plan item CRUD | ✅ Hoàn tất | |
| C. Quick actions (convert/commit/duplicate) | ✅ Hoàn tất | |
| D. Routine / reminder | ✅ Hoàn tất | `NotificationController` |
| E. Báo cáo planned vs actual | ✅ Hoàn tất | |

### API đã có

```
GET    /api/MealPlan                              # GetAll (lọc isActive)
GET    /api/MealPlan/{id}                         # GetById
POST   /api/MealPlan                              # Create
PUT    /api/MealPlan/{id}                         # Update
DELETE /api/MealPlan/{id}                         # Delete
PATCH  /api/MealPlan/{id}/status                  # UpdateStatus

POST   /api/MealPlan/{planId}/items               # AddItem
PUT    /api/MealPlan/{planId}/items/{itemId}     # UpdateItem
DELETE /api/MealPlan/{planId}/items/{itemId}     # DeleteItem
PATCH  /api/MealPlan/{planId}/items/{itemId}/status

POST   /api/MealPlan/{planId}/items/{itemId}/convert-to-log
POST   /api/MealPlan/{planId}/commit
POST   /api/MealPlan/{planId}/duplicate

GET    /api/MealPlan/dashboard?date=              # Dashboard ngày
GET    /api/MealPlan/compare?from=&to=            # Compare planned vs actual
GET    /api/MealPlan/streaks                      # Streaks

# Từ NotificationController
POST   /api/Notification/meal-plan-remind
GET    /api/Notification/settings
PUT    /api/Notification/settings
```

### Kết luận

**Meal Plan API: ✅ HOÀN CHỈNH**

Workflow 2.5 đã có đủ API cần thiết. Chỉ còn thiếu UI Flutter (end-to-end screen).

---

## 2.6 Recommendation

**File Controller:** `backend/MenuGreen.API/Controllers/RecommendationController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Sinh recommendation | 🟡 Một phần | Có `calories`, `eco`, `lunch`, `daily-menu`, `smart-schedule`; thiếu generate mới |
| B. Lưu lịch sử và truy vấn | ✅ Hoàn tất | `history`, `preview` |
| C. Feedback loop | 🟡 Một phần | Có `POST feedback`; thiếu `PUT feedback/{id}`, `GET feedback/summary` |
| D. Giải thích recommendation | ✅ Hoàn tất | `explain/{id}` |
| E. Tối ưu cá nhân hóa | ✅ Hoàn tất | `scores`, `retrain` |

### API đã có

```
GET    /api/Recommendation/calories
GET    /api/Recommendation/eco
GET    /api/Recommendation/lunch
GET    /api/Recommendation/daily-menu
POST   /api/Recommendation/smart-schedule
GET    /api/Recommendation/history
GET    /api/Recommendation/{id}
POST   /api/Recommendation/preview
POST   /api/Recommendation/feedback
GET    /api/Recommendation/explain/{id}
GET    /api/Recommendation/scores
POST   /api/Recommendation/retrain
```

### API còn thiếu

```
❌ POST /api/Recommendation/generate              # Sinh recommendation tổng quát
❌ POST /api/Recommendation/generate/safe         # Sinh gợi ý an toàn (loại trừ dị ứng)
❌ POST /api/Recommendation/generate/weekly-plan # Sinh plan theo tuần
❌ POST /api/Recommendation/generate/budget-aware # Sinh đề xuất theo ngân sách
❌ PUT  /api/Recommendation/feedback/{id}         # Cập nhật feedback nếu đổi ý
❌ GET  /api/Recommendation/feedback/summary      # Tổng hợp tỷ lệ thích/không thích
```

### Chi tiết API còn thiếu

#### 1. POST /api/Recommendation/generate

**Mục đích:** Sinh recommendation tổng quát theo ngữ cảnh user.

**Request Body:**
```json
{
  "mealType": "breakfast|lunch|dinner|snack",
  "targetCalories": 500,
  "excludeUserAllergies": true,
  "maxResults": 5
}
```

**Response:**
```json
{
  "id": "guid",
  "items": [
    {
      "foodId": "guid|null",
      "recipeId": "guid|null",
      "name": "string",
      "calories": 350,
      "protein": 25,
      "carbs": 30,
      "fat": 10,
      "reason": "Phù hợp với bữa sáng, giàu protein"
    }
  ],
  "totalCalories": 350,
  "createdAt": "datetime"
}
```

#### 2. POST /api/Recommendation/generate/safe

**Mục đích:** Sinh gợi ý an toàn, loại trừ dị ứng user.

**Request Body:**
```json
{
  "mealType": "breakfast|lunch|dinner|snack",
  "targetCalories": 500,
  "maxResults": 5
}
```

**Response:** Tương tự `/generate` nhưng đã loại trừ allergens.

#### 3. POST /api/Recommendation/generate/weekly-plan

**Mục đích:** Sinh plan ăn theo tuần.

**Request Body:**
```json
{
  "startDate": "2026-06-16",
  "targetCaloriesPerDay": 2000,
  "mealPreferences": {
    "breakfast": true,
    "lunch": true,
    "dinner": true,
    "snacks": 2
  }
}
```

**Response:**
```json
{
  "id": "guid",
  "weekStartDate": "2026-06-16",
  "days": [
    {
      "date": "2026-06-16",
      "meals": [
        {
          "type": "breakfast",
          "items": [...],
          "totalCalories": 500
        }
      ],
      "totalCalories": 2000
    }
  ]
}
```

#### 4. POST /api/Recommendation/generate/budget-aware

**Mục đích:** Sinh đề xuất theo ngân sách hàng ngày.

**Request Body:**
```json
{
  "mealType": "lunch",
  "maxBudgetPerMeal": 50000,
  "excludeUserAllergies": true
}
```

**Response:**
```json
{
  "items": [
    {
      "foodId": "guid",
      "name": "Cơm gà",
      "estimatedCost": 45000,
      "calories": 480,
      "valueScore": 9.6
    }
  ],
  "totalBudget": 45000,
  "remaining": 5000
}
```

#### 5. PUT /api/Recommendation/feedback/{id}

**Mục đích:** Cập nhật feedback nếu user đổi ý.

**Request Body:**
```json
{
  "rating": 4,
  "comment": "Tôi đổi ý, thực sự không thích món này",
  "wouldRecommend": false
}
```

#### 6. GET /api/Recommendation/feedback/summary

**Mục đích:** Tổng hợp tỷ lệ thích/không thích.

**Response:**
```json
{
  "totalFeedbacks": 150,
  "positiveCount": 120,
  "negativeCount": 30,
  "positiveRate": 0.80,
  "byMealType": {
    "breakfast": { "positive": 40, "negative": 10, "rate": 0.80 },
    "lunch": { "positive": 45, "negative": 8, "rate": 0.85 },
    "dinner": { "positive": 35, "negative": 12, "rate": 0.74 }
  }
}
```

---

## 2.7 AI Assistant

**File Controller:** `backend/MenuGreen.API/Controllers/NutritionAssistantController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Conversation lifecycle | ❌ Chưa có | |
| B. Message workflow | 🟡 Một phần | Chỉ có `POST chat` đơn giản |
| C. Context & profile | ❌ Chưa có | |
| D. Action suggestions | ❌ Chưa có | |
| E. History/analytics | ❌ Chưa có | |

### API đã có

```
POST   /api/NutritionAssistant/chat
```

### API còn thiếu

```
❌ TẤT CẢ - Cần triển khai hoàn chỉnh
```

### Chi tiết API còn thiếu

#### A. Conversation lifecycle

```
POST   /api/AiAssistant/conversations          # Tạo phiên chat mới
GET    /api/AiAssistant/conversations          # Danh sách hội thoại
GET    /api/AiAssistant/conversations/{id}     # Chi tiết hội thoại
DELETE /api/AiAssistant/conversations/{id}     # Xoá hội thoại
PATCH  /api/AiAssistant/conversations/{id}/title # Đổi tiêu đề
```

#### B. Message workflow

```
POST   /api/AiAssistant/conversations/{id}/messages           # Gửi message
GET    /api/AiAssistant/conversations/{id}/messages           # Lấy messages
POST   /api/AiAssistant/conversations/{id}/messages/{msgId}/regenerate
PATCH  /api/AiAssistant/conversations/{id}/messages/{msgId}/feedback
```

#### C. Context & profile

```
GET    /api/AiAssistant/context              # Lấy context hiện tại
PUT    /api/AiAssistant/context               # Cập nhật context ưu tiên
GET    /api/AiAssistant/profile              # Đọc UserAiProfile
PUT    /api/AiAssistant/profile              # Cập nhật UserAiProfile
```

#### D. Action suggestions

```
GET    /api/AiAssistant/suggestions          # Đề xuất hành động tiếp
POST   /api/AiAssistant/actions/meal-plan     # Tạo meal plan từ gợi ý
POST   /api/AiAssistant/actions/replace-food  # Đề xuất món thay thế
POST   /api/AiAssistant/actions/budget-optimize # Tối ưu theo ngân sách
```

#### E. History/analytics

```
GET    /api/AiAssistant/insights             # Thống kê chủ đề hỏi
GET    /api/AiAssistant/conversations/{id}/summary # Tóm tắt hội thoại
GET    /api/AiAssistant/usage                # Số lần dùng theo thời gian
```

### Lưu ý quan trọng

- **Controller hiện tại:** `NutritionAssistantController` chỉ có 1 endpoint `POST /chat` cơ bản.
- **Cần tạo mới:** `AiAssistantController` với đầy đủ CRUD conversation/message.
- **Entity cần dùng:** `AiConversation`, `AiMessage`, `UserAiProfile` (đã có trong DbContext).
- **AI Provider:** Cần tích hợp với LLM (OpenAI/Gemini) cho chat thật sự.

---

## 2.9 Notification

**File Controller:** `backend/MenuGreen.API/Controllers/NotificationController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Notification setting | ✅ Hoàn tất | |
| B. Notification inbox | ✅ Hoàn tất | |
| C. Gửi notification | 🟡 Cơ bản | Có `send`; thiếu bulk/event/schedule |
| D. Re-engagement campaign | ❌ Chưa có | |
| E. Tracking open/click | ✅ Hoàn tất | |
| E. Analytics | 🟡 Một phần | Có `analytics`; thiếu `re-engagement` |

### API đã có

```
GET    /api/Notification/settings
PUT    /api/Notification/settings
POST   /api/Notification/settings/reset
GET    /api/Notification/channels

GET    /api/Notification
GET    /api/Notification/{id}
GET    /api/Notification/unread-count
PATCH  /api/Notification/{id}/read
PATCH  /api/Notification/read-all
DELETE /api/Notification/{id}
DELETE /api/Notification/batch
DELETE /api/Notification/range

POST   /api/Notification/meal-plan-remind
POST   /api/Notification/schedule-prep-reminder
POST   /api/Notification/send

POST   /api/Notification/{id}/track/open
POST   /api/Notification/{id}/track/click
POST   /api/Notification/{id}/track/action-complete

GET    /api/Notification/analytics
```

### API còn thiếu

```
❌ POST /api/Notification/send/bulk              # Gửi hàng loạt
❌ POST /api/Notification/send/event             # Gửi theo sự kiện
❌ POST /api/Notification/send/schedule          # Lên lịch gửi
❌ POST /api/Notification/send/retry             # Gửi lại nếu thất bại

❌ POST /api/Notification/campaigns              # Tạo chiến dịch
❌ GET  /api/Notification/campaigns              # Danh sách chiến dịch
❌ GET  /api/Notification/campaigns/{id}         # Chi tiết chiến dịch
❌ PUT  /api/Notification/campaigns/{id}         # Cập nhật chiến dịch
❌ POST /api/Notification/campaigns/{id}/run      # Chạy chiến dịch
❌ POST /api/Notification/campaigns/{id}/pause    # Tạm dừng chiến dịch

❌ GET  /api/Notification/analytics/re-engagement # Báo cáo re-engagement
```

### Chi tiết API còn thiếu

#### C. Gửi notification theo sự kiện

**1. POST /api/Notification/send/bulk**

```json
{
  "userIds": ["guid1", "guid2"],
  "notification": {
    "title": "Nhắc nhở bữa ăn",
    "body": "�ã 12:00 rồi, bạn ơi!",
    "type": "meal_reminder"
  },
  "scheduleAt": "2026-06-16T12:00:00Z"
}
```

**2. POST /api/Notification/send/event**

```json
{
  "eventType": "meal_time|subscription_expiring|weight_reminder|meal_not_logged",
  "userId": "guid",
  "context": {
    "mealType": "lunch",
    "daysUntilExpiry": 3
  }
}
```

**3. POST /api/Notification/send/schedule**

```json
{
  "title": "Nhắc ăn tối",
  "body": "Đã 18:00, bạn đã lên kế hoạch ăn gì?",
  "scheduledAt": "2026-06-16T18:00:00Z",
  "userId": "guid"
}
```

#### D. Re-engagement campaign

**1. POST /api/Notification/campaigns**

```json
{
  "name": "Chiến dịch quay lại tháng 6",
  "targetSegment": "inactive_7_days",
  "notification": {
    "title": "Bạn đang bỏ lỡ gì?",
    "body": "Quay lại và ghi nhận bữa ăn hôm nay nhé!"
  },
  "schedule": {
    "startDate": "2026-06-01",
    "endDate": "2026-06-30",
    "sendTime": "10:00:00"
  },
  "isActive": true
}
```

---

## 2.10 Analytics

**File Controller:** `backend/MenuGreen.API/Controllers/AnalyticsController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Activity log | ✅ Hoàn tất | |
| B. Dashboard & metrics | ✅ Hoàn tất | |
| C. Funnel analysis | ✅ Hoàn tất | |
| D. Cohort analysis | ✅ Hoàn tất | |
| E. Churn & retention | ✅ Hoàn tất | |
| F. Export | ✅ Hoàn tất | |

### API đã có

```
POST   /api/Analytics/activity-log
POST   /api/Analytics/activity-log/bulk
GET    /api/Analytics/activity-log
GET    /api/Analytics/activity-log/{id}

GET    /api/Analytics/dashboard
GET    /api/Analytics/summary
GET    /api/Analytics/metrics
GET    /api/Analytics/top-events

GET    /api/Analytics/funnel
POST   /api/Analytics/funnel/preview
GET    /api/Analytics/funnel/meal-onboarding
GET    /api/Analytics/funnel/subscription

GET    /api/Analytics/cohort
GET    /api/Analytics/cohort/retention
GET    /api/Analytics/cohort/by-signup-date
GET    /api/Analytics/cohort/by-first-meal-log
GET    /api/Analytics/cohort/by-subscription

GET    /api/Analytics/drop-off
GET    /api/Analytics/churn-risk
GET    /api/Analytics/inactive-users
GET    /api/Analytics/reactivation-opportunities

GET    /api/Analytics/export/activity-log
GET    /api/Analytics/export/funnel
GET    /api/Analytics/export/cohort
```

### Kết luận

**Analytics API: ✅ HOÀN CHỈNH**

Workflow 2.10 có đầy đủ API. Chỉ còn thiếu:
- UI Flutter để hiển thị dashboard và báo cáo (Admin panel).

---

## Tổng kết

| Workflow | API Status | UI Status | Ưu tiên |
|----------|:----------:|:---------:|---------|
| 2.5 Meal Plan | ✅ Hoàn chỉnh | ❌ Chưa có | **P1** - Cần UI |
| 2.6 Recommendation | 🟡 78% (11/14) | 🟡 Một phần | **P2** - Thêm 6 API + UI |
| 2.7 AI Assistant | ❌ 7% (1/14) | ❌ Chưa nối | **P3** - Cần xây mới |
| 2.9 Notification | 🟡 73% (19/26) | ❌ Chưa đầy đủ | **P2** - Thêm 7 API + UI |
| 2.10 Analytics | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** - Admin UI |

### Thứ tự ưu tiên triển khai

1. **P1 - Meal Plan UI:** Vì API đã hoàn chỉnh, chỉ cần build UI Flutter.
2. **P2 - Recommendation Enhancement:** Thêm 6 API còn thiếu + UI feedback/history.
3. **P2 - Notification Enhancement:** Thêm 7 API (campaign, bulk, event) + UI settings/inbox.
4. **P3 - AI Assistant:** Xây mới hoàn toàn controller + tích hợp LLM.
5. **P3 - Analytics Admin UI:** Build admin dashboard để xem KPI.

---

## Related Documents

- [README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md](./README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md)
- [README_USER_WORKFLOW.md](./README_USER_WORKFLOW.md)
- [README_SEPAY_PAYMENT_WORKFLOW.md](./README_SEPAY_PAYMENT_WORKFLOW.md)
