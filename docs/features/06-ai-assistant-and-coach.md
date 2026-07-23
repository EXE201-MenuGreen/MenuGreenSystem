# 06. AI Assistant & Coach

**Status:** API Done · UI Partial (2026-07-23: Chat + conversation list + provider + repository đã hoạt động, một số feature cần mở rộng)
**Last updated:** 2026-07-23

**Related controllers:**
- `backend/MenuGreen.API/Controllers/AiAssistantController.cs`
- `backend/MenuGreen.API/Controllers/AiCoachController.cs`
- `backend/MenuGreen.API/Controllers/AiAdminController.cs`

**Related Flutter feature:** `frontend/lib/features/ai_assistant/`

---

## 1. Overview

Hệ thống AI gồm 2 phần chính:

1. **AI Nutrition Assistant** — Chatbot trợ lý dinh dưỡng (hỏi đáp tự do).
2. **Contextual AI Coach** — Huấn luyện viên cá nhân hóa cao, dùng full context từ hệ thống.

Cả hai đều có **function calling** để thực thi hành động (log meal, tạo plan, ...).

---

## 2. Business Rules

### 2.1 AI Nutrition Assistant

- Hỗ trợ hội thoại tự do về dinh dưỡng.
- Có thể gọi recommendation, meal plan, nutrition tracking như các công cụ phụ trợ (Function Calling / Tool Use).
- Output không chỉ là câu trả lời mà còn là **action suggestions** tiếp theo.
- Lưu lịch sử chat để làm dữ liệu train tiếp theo và duy trì trí nhớ ngắn hạn/dài hạn.
- Hỗ trợ song song 2 endpoint đổi title để tương thích ngược với Flutter client cũ: `PATCH` và `POST /conversations/{id}/title`.

### 2.2 Contextual AI Coach

- Lớp AI sâu, cá nhân hóa cao, nhận context từ toàn bộ hệ thống.
- Backend tổng hợp context từ: `HealthProfile`, `UserAllergy`, `NutritionTrackingService`, `Goals/drift-alerts`, `GymGoals/alerts`.
- Dịch vụ AI ghép context JSON vào **System Prompt** cho model LLM.
- Lưu lịch sử chat để train model và duy trì trí nhớ.
- Function calling phải có **`confirmed: true`** mới thực thi (audit trail).
- Suggested prompts: 3-5 câu hỏi nhanh dựa trên tình trạng dinh dưỡng hiện tại.

### 2.3 Safety & Guardrails (chung cho cả 2)

- Luôn áp dụng rule-based filter trước khi gửi vào LLM (loại trừ dị ứng, giới hạn calo).
- AI response phải validate trước khi trả về user (không trả lời trái medical advice).
- Log tất cả AI interactions để audit và train model.

### 2.4 Subscription Gating

- Tính năng AI có thể là **Premium feature** — kiểm tra entitlement trước khi gọi AI API (xem [`08-subscription-and-payment.md`](./08-subscription-and-payment.md)).

### 2.5 Message Convention

- Backend responses tiếng Anh (JSON fields, error messages, enum values).
- Flutter dịch qua `ApiMessageTranslator` trước khi show user (xem rule `backend-english-frontend-vietnamese-i18n.mdc`).

---

## 3. API Endpoints

### 3.1 AI Nutrition Assistant — Conversations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiAssistant/conversations` | Tạo phiên chat mới (firstMessage optional) |
| `GET` | `/api/AiAssistant/conversations` | Danh sách hội thoại |
| `GET` | `/api/AiAssistant/conversations/{id}` | Chi tiết hội thoại |
| `DELETE` | `/api/AiAssistant/conversations/{id}` | Xóa hội thoại |
| `PATCH` | `/api/AiAssistant/conversations/{id}/title` | Đổi tiêu đề (chuẩn mới) |
| `POST` | `/api/AiAssistant/conversations/{id}/title` | Đổi tiêu đề (backward-compat với Flutter cũ) |

### 3.2 AI Nutrition Assistant — Messages

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiAssistant/conversations/{id}/messages` | Gửi message + nhận AI response |
| `GET` | `/api/AiAssistant/conversations/{id}/messages` | Lấy lịch sử messages |
| `POST` | `/api/AiAssistant/conversations/{id}/messages/{msgId}/regenerate` | Tạo lại response |
| `PATCH` | `/api/AiAssistant/conversations/{id}/messages/{msgId}/feedback` | Feedback cho message |

### 3.3 AI Nutrition Assistant — Context & Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAssistant/context` | Lấy context cho AI |
| `PUT` | `/api/AiAssistant/context` | Cập nhật context ưu tiên |
| `GET` | `/api/AiAssistant/profile` | Đọc UserAiProfile |
| `PUT` | `/api/AiAssistant/profile` | Cập nhật UserAiProfile |

### 3.4 AI Nutrition Assistant — Action Suggestions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAssistant/suggestions` | Gợi ý hành động tiếp theo |
| `POST` | `/api/AiAssistant/actions/meal-plan` | Tạo meal plan 7 ngày |
| `POST` | `/api/AiAssistant/actions/replace-food` | Thay thế món an toàn |
| `POST` | `/api/AiAssistant/actions/budget-optimize` | Tối ưu theo ngân sách |

### 3.5 AI Nutrition Assistant — Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAssistant/insights` | Thống kê topics từ messages |
| `GET` | `/api/AiAssistant/conversations/{id}/summary` | Tóm tắt hội thoại |
| `GET` | `/api/AiAssistant/usage` | Usage statistics (daily/weekly/monthly) |

### 3.6 Contextual AI Coach — Context APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiCoach/context?date=` | Snapshot ngữ cảnh user (profile, nutrition, allergies, current plan) |
| `GET` | `/api/AiCoach/suggested-prompts` | 3-5 câu hỏi nhanh dựa trên tình trạng |

### 3.7 Contextual AI Coach — Session Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiCoach/sessions` | Tạo phiên chat mới |
| `POST` | `/api/AiCoach/sessions/{sessionId}/messages` | Gửi message + nhận AI response |
| `GET` | `/api/AiCoach/sessions/{sessionId}/history` | Lịch sử hội thoại |
| `DELETE` | `/api/AiCoach/sessions/{sessionId}` | Xóa phiên chat |
| `POST` | `/api/AiCoach/execute-action` | Thực thi action (log_meal, generate_meal_plan, schedule_meal, ...) |

### 3.8 Contextual AI Coach — Feedback

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiCoach/sessions/{sessionId}/messages/{messageId}/feedback` | Feedback cho message trong session (mới) |
| `POST` | `/api/AiCoach/messages/{messageId}/feedback` | Feedback cho message (backward-compat flat path) |

**Tổng user-facing: 31 endpoint** (22 AiAssistant + 9 AiCoach).
(Update 2026-07-08: EP regenerate/feedback trên AiAssistant có cả PATCH và POST (backward-compat Flutter cũ), EP feedback trên AiCoach có 2 path (sessions-flat). Update 2026-07-09: thêm §3.9 AiAdminController. Update 2026-07-23: xác nhận Flutter UI đã kết nối API.)

### 3.9 AI Admin (AiAdminController — AdminOnly)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAdmin/overview/health` | System health check |
| `GET` | `/api/AiAdmin/debug/db` | DB debug info |
| `POST` | `/api/AiAdmin/debug/db` | Execute DB command |
| `GET` | `/api/AiAdmin/debug/postgres` | PostgreSQL debug info |
| `POST` | `/api/AiAdmin/debug/postgres` | Execute PostgreSQL command |
| `POST` | `/api/AiAdmin/crawler/normalize` | Normalize crawler data |
| `POST` | `/api/AiAdmin/crawler/ingest` | Ingest food data |
| `GET` | `/api/AiAdmin/training-samples` | List training samples |
| `POST` | `/api/AiAdmin/training-samples` | Create training sample |
| `PATCH` | `/api/AiAdmin/training-samples/{id}` | Update training sample |
| `POST` | `/api/AiAdmin/feedback/{id}/to-training-sample` | Convert feedback to training sample |
| `POST` | `/api/AiAdmin/curation/nightly` | Trigger nightly curation job |

**Tổng system: 43 endpoint** (31 user-facing + 12 admin).

---

## 4. UI Components

### 4.1 Flutter UI (2026-07-23 Update)

| Component | File | Status | Notes |
|-----------|------|--------|-------|
| AiConversationListScreen | `features/ai_assistant/views/ai_conversation_list_screen.dart` | Partial | Hiển thị danh sách, tạo/xóa conversation |
| AiChatScreen | `features/ai_assistant/views/ai_chat_screen.dart` | Done | Chat UI với message bubbles, gửi message, feedback, regenerate, food detection |
| AiAssistantProvider | `features/ai_assistant/providers/ai_assistant_provider.dart` | Done | State management đầy đủ |
| AiAssistantRepository | `features/ai_assistant/repositories/ai_assistant_repository.dart` | Partial | Kết nối API cơ bản |
| AiAssistantModels | `features/ai_assistant/models/ai_assistant_models.dart` | Partial | Data models |
| ai_assistant.dart (barrel) | `features/ai_assistant/ai_assistant.dart` | Done | Export barrel |

### 4.2 Đã triển khai trong AiChatScreen

- Message bubbles cho user và assistant
- Gửi message + nhận AI response
- Feedback buttons (like/dislike)
- Regenerate response
- Food detection từ message content + quick-add vào meal plan
- Smooth scroll to bottom khi có message mới

### 4.3 Cần mở rộng

- Suggested prompts chips (từ `/api/AiAssistant/suggestions`)
- Action suggestions từ AI (meal plan, replace food, ...)
- Confirmation dialog cho function calling
- Suggested prompts từ `/api/AiCoach/suggested-prompts` cho AI Coach tab

---

## 5. Navigation Flow

```
MainScreen
└── Tab AI → AiConversationListScreen
        ├── Empty state → Tap "New chat" → AiChatScreen (POST /conversations)
        └── Tap conversation → AiChatScreen
                ├── Suggested prompts (chips) → tap gửi luôn
                ├── Input box → POST /messages → render streaming response
                ├── Action suggestion từ AI
                │       ├── "Tạo meal plan" → confirmation dialog
                │       │       └── confirm → POST /actions/meal-plan → MealPlanScreen (xem 03-meal-plan.md)
                │       ├── "Thay món" → confirmation dialog
                │       │       └── confirm → POST /actions/replace-food → FoodDetailScreen
                │       └── "Log meal" → confirmation dialog
                │               └── confirm → POST /execute-action → MealLogSheet (xem 02-nutrition-tracking.md)
                ├── Food detection → thêm nhanh vào meal plan
                └── Feedback (like/dislike) → PATCH /feedback
```

---

## 6. Data Models (rút gọn)

```
AiConversation
├── Id, UserId, Title
├── CreatedAt, UpdatedAt
└── Messages[] (AiMessage)

AiMessage
├── Id, ConversationId, Role (user/assistant)
├── Content, Tokens, CreatedAt
└── Feedback (IsPositive, Reason, Comment)

UserAiProfile
├── UserId, Preferences (JSON)
├── DislikedFoods, DietaryType
├── RecommendationTuning (JSON)
└── CreatedAt, UpdatedAt

AiCoachSession (parallel to Conversation)
├── Id, UserId, CreatedAt, DeletedAt?
└── Messages[]

AiCoachContextSnapshot (read-only)
├── UserProfile (gender, age, weightKg, heightCm, goalMode, region)
├── NutritionalTarget (caloriesKcal, proteinG, carbsG, fatG)
├── ActualIntakeToday (caloriesKcal, proteinG, ..., waterMl)
├── RemainingBudgetToday
├── SafetyAndAllergies (allergenKeys, allergyRiskLevel)
├── Preferences (dietaryType, dislikedIngredients)
└── CurrentMealPlan (plannedMeals, completedMeals)

ExecuteActionRequest
├── Type (log_meal / generate_meal_plan / schedule_meal / ...)
├── Confirmed (bool — required true)
└── Payload (object — tuỳ type)
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md).

---

## 7. Execute Action Payloads (examples)

### 7.1 log_meal

```json
{
  "type": "log_meal",
  "confirmed": true,
  "payload": {
    "recipe_id": "uuid",
    "meal_slot": "dinner",
    "quantity_g": 250,
    "unit": "g",
    "notes": "Optional notes"
  }
}
```

### 7.2 generate_meal_plan

```json
{
  "type": "generate_meal_plan",
  "confirmed": true,
  "payload": {
    "budget_vnd_per_day": 120000,
    "max_cook_time_min": 45,
    "target_calories_per_day": 2000
  }
}
```

### 7.3 schedule_meal

```json
{
  "type": "schedule_meal",
  "confirmed": true,
  "payload": {
    "recipe_id": "uuid",
    "meal_slot": "breakfast",
    "planned_date": "2026-07-05",
    "scheduled_time": "07:30:00"
  }
}
```

---

## 8. Related Documents

- Recommendation engine (function calling): [`05-recommendation-engine.md`](./05-recommendation-engine.md)
- User profile (AI context): [`01-auth-and-account.md`](./01-auth-and-account.md)
- Meal log (AI log_meal action): [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)
- Meal plan (AI generate_meal_plan): [`03-meal-plan.md`](./03-meal-plan.md)
- Allergy (excludeUserAllergies): [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)
- Subscription gating: [`08-subscription-and-payment.md`](./08-subscription-and-payment.md)
- User workflow cũ (mục 4.8): [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)
- File AI Assistant API spec cũ: [`../_archive/root-readmes/README_AI_FEATURES_API.md`](../_archive/root-readmes/README_AI_FEATURES_API.md)
- File features cũ: [`../_archive/features/AI_ASSISTANT.md`](../_archive/features/AI_ASSISTANT.md)

---

## 9. Thay đổi so với file cũ

| Ngày | Thay đổi |
|------|-----------|
| 2026-07-09 | Tạo file canonical gộp cả AI Assistant và AI Coach |
| 2026-07-23 | Cập nhật status UI: "Placeholder" → "Partial" (chat + conversation list đã kết nối API, cần mở rộng thêm features) |

File cũ `features/AI_ASSISTANT.md` chỉ mô tả AI Assistant. **Contextual AI Coach** (`/api/AiCoach/*`) là controller riêng (`AiCoachController.cs`) chỉ được document trong `README_AI_FEATURES_API.md` — không xuất hiện ở `PROJECT_STATUS.md` hay `README_WORKFLOW_API_STATUS.md`. Tạo ra "shadow feature".

→ File canonical này gộp cả 2 phần, đánh status **"API Done · UI Partial"** với chat functionality đã hoạt động.
