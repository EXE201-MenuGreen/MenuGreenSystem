# Features Documentation

Thư mục này chứa tài liệu canonical cho **mỗi nhóm tính năng nghiệp vụ** của MenuGreen. Mỗi file là **single source of truth** cho một nhóm — không cần đọc chỗ khác để biết trạng thái, API, UI hay business rule của tính năng đó.

> **Quy ước đọc:** Người mới onboard nên đọc file `01` → `10` theo thứ tự để hiểu hành trình người dùng.

---

## Mục lục theo nhóm nghiệp vụ

| # | File | Mô tả | Trạng thái API | Trạng thái UI |
|---|---|---|---|---|
| 01 | [Auth & Account](./01-auth-and-account.md) | Đăng ký/đăng nhập/OTP, Onboarding 5 bước, Profile, Health Profile | Done | Done |
| 02 | [Nutrition Tracking](./02-nutrition-tracking.md) | Nhật ký ăn uống, cân nặng, dashboard ngày/tuần/tháng | Done | Done |
| 03 | [Meal Plan](./03-meal-plan.md) | Lập kế hoạch bữa ăn, dashboard, streaks, nhắc bữa | Done | Done |
| 04 | [Discover & Allergy](./04-discover-and-allergy.md) | Khám phá món/công thức, allergy profile, portion converter | Done | Done |
| 05 | [Recommendation Engine](./05-recommendation-engine.md) | Rule-based + AI gợi ý, history, feedback, retrain | Done | Done |
| 06 | [AI Assistant & Coach](./06-ai-assistant-and-coach.md) | Chatbot AI, contextual coach, function calling | Done | Placeholder |
| 07 | [Notification](./07-notification.md) | Settings, inbox, meal-plan-remind, tracking open/click | Done | Done |
| 08 | [Subscription & Payment](./08-subscription-and-payment.md) | SubscriptionPlan, UserSubscription, SePay QR | Done | Done |
| 09 | [Analytics](./09-analytics.md) | Activity log, funnel, cohort, churn (Admin only) | Done | Out of scope |
| 10 | [Vietnam Local Features](./10-vietnam-local-features.md) | Daily Starter, Gym/PT, Food Capture, Safety, Allergy Badge, Planned vs Actual + Nutrition Formulas | Done | Partial |
| 11 | [Premium Programs](./11-premium-programs.md) | Chương trình Premium có cấu trúc: milestone, check-in, graduation | Done | Not Done |
| 12 | [Meal Templates](./12-meal-templates.md) | Lưu nhanh bữa ăn lặp lại, log từ template | Done | Not Done |
| 13 | [Micro-Learning](./13-micro-learning.md) | Thẻ kiến thức dinh dưỡng ngắn, quiz, gamification | Done | Not Done |
| 14 | [Adaptive Reminders](./14-adaptive-reminders.md) | Optimal meal time, scheduled reminders, snooze | Done | Not Done |
| 15 | [PT Review](./15-pt-review.md) | PT review weekly report, shareable link, apply/reject suggestions | Done | Not Done |
| 16 | [Budget Management](./16-budget-management.md) | Cấu hình ngân sách ăn uống cho gợi ý | Done | Not Done |
| 17 | [Coaches Ecosystem](./17-coaches.md) | Hệ sinh thái Coach-Student dài hạn, PT dashboard, điều chỉnh meal plan | Done | Not Done |
| 18 | [Ingredient Catalog](./18-ingredient-catalog.md) | CRUD nguyên liệu thô, search, catalog | Done | Not Done |
| 19 | [User Management](./19-user-management.md) | Đổi mật khẩu, admin user CRUD (lock, role) | Done | Partial |

---

## Chú thích trạng thái

- **API Done** — Toàn bộ endpoint đã implement và deploy production.
- **UI Done** — Toàn bộ màn hình/widget đã code và kết nối API.
- **UI Placeholder** — Có màn hình nhưng chưa gọi API, hoặc đang dùng mock.
- **UI Partial** — Một phần UI đã có (ví dụ: chỉ gợi ý an toàn trong Discover, chưa có màn riêng cho history/feedback).
- **Out of scope** — Tính năng chỉ phục vụ Admin panel, không nằm trong mobile app.

---

## Workflow người dùng tổng quan

```
[Onboarding 5 bước]               → 01-auth-and-account.md
        │
        ▼
[Trang chủ]                       → 02-nutrition-tracking.md (Home tab)
        │  ▲
        │  └── Ghi meal log ─────→ 02-nutrition-tracking.md
        │  └── Ghi cân nặng ────→ 02-nutrition-tracking.md
        │
[Khám phá]                        → 04-discover-and-allergy.md (Discover tab)
        │  └── Lọc dị ứng ─────→ 04-discover-and-allergy.md
        │  └── Gợi ý an toàn ──→ 05-recommendation-engine.md
        │
[Lịch sử]                         → 02-nutrition-tracking.md (History tab)
        │
[Meal Plan]                       → 03-meal-plan.md
        │  └── Đặt reminder ────→ 07-notification.md
        │
[AI Tab]                          → 06-ai-assistant-and-coach.md
        │
[Gói thành viên]                  → 08-subscription-and-payment.md (khi cần nâng cấp)
```

---

## Ánh xạ với cấu trúc cũ

Các file README cũ đã được tách/thay thế như sau:

| File cũ (đã archive) | File mới (canonical) |
|---|---|
| `features/MEAL_PLAN.md` | `03-meal-plan.md` |
| `features/AI_ASSISTANT.md` | `06-ai-assistant-and-coach.md` |
| `features/ANALYTICS.md` | `09-analytics.md` |
| `features/RECOMMENDATION.md` | `05-recommendation-engine.md` |
| `features/index.md` | `README.md` (file này) |
| `README_USER_WORKFLOW.md` | Tách vào `01`–`10` |
| `README_WORKFLOW_API_STATUS.md` | Tách vào `01`–`10` |
| `README_AI_FEATURES_API.md` | `06-ai-assistant-and-coach.md` |
| `README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md` | `README.md` (file này) + `10-vietnam-local-features.md` |
| `NUTRITION_CALCULATIONS_README.md` | `10-vietnam-local-features.md` (Appendix) |

File cũ vẫn ở `../_archive/` để tham khảo, không cập nhật.

---

## Cấu trúc mỗi file canonical

Mỗi file `01-10` theo cùng template để dễ tìm thông tin:

1. **Overview** — Mô tả ngắn, giá trị cho user.
2. **Business Rules** — Quy tắc nghiệp vụ, công thức, threshold.
3. **API Endpoints** — Bảng đầy đủ endpoint.
4. **UI Components** — Bảng widget/screen Flutter + trạng thái.
5. **Navigation Flow** — Diagram điều hướng.
6. **Data Models** — Sơ đồ entity chính (nếu có).
7. **Related Documents** — Link tới file liên quan.

---

## Liên kết ngoài

- Project overview: [`../00-overview/PROJECT_STATUS.md`](../00-overview/PROJECT_STATUS.md)
- **System Specification (SPEC): [`../00-overview/SPEC.md`](../00-overview/SPEC.md)** — Kiến trúc tổng thể, cross-service dependencies, API architecture, deployment, Flutter app structure, Open Issues
- Backend models: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md)
- Issues tracker: [`../issues.md`](../issues.md)
- Deployment guide: [`../01-deployment/`](../01-deployment/)

---

*Last updated: 2026-07-23 — Cập nhật AI Assistant UI status.*