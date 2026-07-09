# 09. Analytics

**Status:** API Done · UI Out of Scope (Admin only)
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/AnalyticsController.cs`

**Related Flutter feature:** Không có (Admin panel only)

---

## 1. Overview

Analytics APIs cung cấp dữ liệu thống kê cho admin dashboard:

- Activity logs
- Funnel analysis
- Cohort analysis
- Churn & retention
- Export data
- Planned vs Actual insights

> **Note:** UI cho analytics là Admin panel, không nằm trong mobile app scope.

---

## 2. Business Rules

### 2.1 Activity Log

- Ghi log mọi event quan trọng của user (meal_logged, onboarding_completed, subscription_subscribed, ...).
- Bulk endpoint cho việc ghi nhiều log cùng lúc (offline batch sync).

### 2.2 Funnel Analysis

- Funnel meal-onboarding: đo conversion từ đăng ký → onboarding → first meal log → active user.
- Funnel subscription: free → paid conversion.
- Preview funnel: tính toán không lưu (cho admin test tham số).

### 2.3 Cohort Analysis

- Cohort theo signup date / first meal log date / subscription date.
- Retention rate: % user còn active sau N tuần.

### 2.4 Churn & Retention

- **Drop-off:** user rời bỏ tại bước nào trong funnel.
- **Churn risk:** user có dấu hiệu sắp rời bỏ (giảm log, ...).
- **Inactive users:** không log > N ngày.
- **Reactivation opportunities:** user đã inactive lâu nhưng có tiềm năng quay lại.

### 2.5 Planned vs Actual (workflow 2.17)

- So sánh meal plan vs meal log thực tế.
- Adherence Score (0-100): công thức 4 thành phần (chi tiết tại [`10-vietnam-local-features.md` → Appendix A.9](./10-vietnam-local-features.md#9-adherence-score)).
- Drift analysis: bữa bỏ qua, thay thế, khẩu phần lệch.
- Recalibrate: tái phân bổ calo/macro tuần tiếp theo (xem [`10-vietnam-local-features.md` → Appendix A.10](./10-vietnam-local-features.md#10-recalibration)).

---

## 3. API Endpoints

### 3.1 Activity Log

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Analytics/activity-log` | Ghi log hoạt động |
| `POST` | `/api/Analytics/activity-log/bulk` | Ghi nhiều logs |
| `GET` | `/api/Analytics/activity-log` | Lấy danh sách logs |
| `GET` | `/api/Analytics/activity-log/{id}` | Chi tiết log |

### 3.2 Dashboard & Metrics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/dashboard` | Dashboard tổng quan |
| `GET` | `/api/Analytics/summary` | Summary metrics |
| `GET` | `/api/Analytics/metrics` | Key metrics |
| `GET` | `/api/Analytics/top-events` | Top events |

### 3.3 Funnel Analysis

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/funnel` | Funnel analysis |
| `POST` | `/api/Analytics/funnel/preview` | Preview funnel (không lưu) |
| `GET` | `/api/Analytics/funnel/meal-onboarding` | Meal onboarding funnel |
| `GET` | `/api/Analytics/funnel/subscription` | Subscription funnel |

### 3.4 Cohort Analysis

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/cohort` | Cohort data |
| `GET` | `/api/Analytics/cohort/retention` | Retention rates |
| `GET` | `/api/Analytics/cohort/by-signup-date` | Cohorts theo signup |
| `GET` | `/api/Analytics/cohort/by-first-meal-log` | Cohorts theo first log |
| `GET` | `/api/Analytics/cohort/by-subscription` | Cohorts theo subscription |

### 3.5 Churn & Retention

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/drop-off` | Drop-off analysis |
| `GET` | `/api/Analytics/churn-risk` | Users at churn risk |
| `GET` | `/api/Analytics/inactive-users` | Inactive users |
| `GET` | `/api/Analytics/reactivation-opportunities` | Reactivation chances |

### 3.6 Planned vs Actual — PlannedVsActualController (RIÊNG BIỆT, không thuộc AnalyticsController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/planned-vs-actual` | So sánh planned vs actual |
| `GET` | `/api/Analytics/planned-vs-actual/adherence-score` | Điểm bám sát (0-100) |
| `GET` | `/api/Analytics/planned-vs-actual/drift-analysis` | Phân tích lệch |
| `GET` | `/api/Analytics/planned-vs-actual/recommendations` | Gợi ý hành động khắc phục |
| `GET` | `/api/Analytics/planned-vs-actual/monthly-report` | Báo cáo tháng (HTML) |
| `POST` | `/api/Analytics/planned-vs-actual/recalibrate` | Tái phân bổ calo/macro tuần sau |

### 3.7 Export

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/export/activity-log` | Export activity logs |
| `GET` | `/api/Analytics/export/funnel` | Export funnel data |
| `GET` | `/api/Analytics/export/cohort` | Export cohort data |

### 3.8 Nutrition Analytics (`AnalyticsController.nutrition`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/nutrition/dashboard` | Nutrition analytics dashboard |
| `GET` | `/api/Analytics/nutrition/macro-distribution` | Phân bố macro trong kỳ |
| `GET` | `/api/Analytics/nutrition/goal-achievement` | Tỷ lệ đạt target |
| `GET` | `/api/Analytics/nutrition/top-foods` | Top foods (năng lượng) |
| `GET` | `/api/Analytics/nutrition/calorie-distribution` | Phân bố calo theo thời gian |
| `GET` | `/api/Analytics/nutrition/meal-type-breakdown` | Calo theo meal type |
| `GET` | `/api/Analytics/nutrition/user-insights` | Insights cá nhân |

**Tổng: 35 endpoint** (4 Activity + 4 Dashboard & Metrics + 4 Funnel + 5 Cohort + 4 Churn & Retention + 6 Planned vs Actual + 3 Export + 7 Nutrition). *(Update 2026-07-09: sửa 37 → 35; PlannedVsActual thực tế thuộc PlannedVsActualController riêng biệt.)* UI không có trong app — admin dùng BI tool.

---

## 4. UI Components

> Không có UI trong mobile app. Admin sử dụng dashboard riêng (BI tool hoặc custom admin panel).

---

## 5. Navigation Flow

N/A — không có UI user-facing.

---

## 6. Data Models (rút gọn)

```
ActivityLog
├── Id, UserId, EventType
├── EventData (JSON)
├── Timestamp
└── Source (Web / iOS / Android / Backend)

FunnelResult
├── FunnelName, Steps[]
└── ConversionRate

Cohort
├── CohortId (e.g., "2026-W26")
├── CohortStartDate
├── Size
└── RetentionByWeek[]

ChurnRisk
├── UserId
├── RiskScore (0-100)
└── ReasonCodes[]

PlannedVsActualSummary
├── FromDate, ToDate
├── TotalPlanned{Calories, Protein, Carbs, Fat, Cost}
├── TotalActual{...}
├── Difference{...}
└── AdherenceScore (0-100)
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md).

---

## 7. Related Documents

- Planned vs Actual formulas: [`10-vietnam-local-features.md` → Appendix A.8 & A.9](./10-vietnam-local-features.md#8-planned-vs-actual-nutrition)
- Goal drift alerts (trigger notification): [`07-notification.md`](./07-notification.md)
- Meal Plan (data nguồn): [`03-meal-plan.md`](./03-meal-plan.md)
- Nutrition Tracking (data nguồn): [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)
- User workflow cũ: [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)
- File cũ (archive): [`../_archive/features/ANALYTICS.md`](../_archive/features/ANALYTICS.md)