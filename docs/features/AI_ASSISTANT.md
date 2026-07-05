# AI Nutrition Assistant & Coach

**Status:** ✅ API Complete | ⏳ UI Pending (Flutter)

---

## Overview

Hệ thống AI gồm 2 phần:
1. **AI Nutrition Assistant** - Chatbot trợ lý dinh dưỡng
2. **Contextual AI Coach** - Huấn luyện viên cá nhân hóa cao

---

## AI Nutrition Assistant

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiAssistant/conversations` | Tạo phiên chat mới |
| `GET` | `/api/AiAssistant/conversations` | Danh sách hội thoại |
| `GET` | `/api/AiAssistant/conversations/{id}` | Chi tiết hội thoại |
| `DELETE` | `/api/AiAssistant/conversations/{id}` | Xóa hội thoại |
| `PATCH` | `/api/AiAssistant/conversations/{id}/title` | Đổi tiêu đề |

### Messages

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiAssistant/conversations/{id}/messages` | Gửi message + nhận AI response |
| `GET` | `/api/AiAssistant/conversations/{id}/messages` | Lấy lịch sử messages |
| `POST` | `/api/AiAssistant/conversations/{id}/messages/{msgId}/regenerate` | Tạo lại response |
| `PATCH` | `/api/AiAssistant/conversations/{id}/messages/{msgId}/feedback` | Feedback cho message |

### Context & Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAssistant/context` | Lấy context cho AI |
| `PUT` | `/api/AiAssistant/context` | Cập nhật context ưu tiên |
| `GET` | `/api/AiAssistant/profile` | Đọc UserAiProfile |
| `PUT` | `/api/AiAssistant/profile` | Cập nhật UserAiProfile |

### Action Suggestions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAssistant/suggestions` | Gợi ý hành động tiếp theo |
| `POST` | `/api/AiAssistant/actions/meal-plan` | Tạo meal plan 7 ngày |
| `POST` | `/api/AiAssistant/actions/replace-food` | Thay thế món an toàn |
| `POST` | `/api/AiAssistant/actions/budget-optimize` | Tối ưu theo ngân sách |

### Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiAssistant/insights` | Thống kê topics từ messages |
| `GET` | `/api/AiAssistant/conversations/{id}/summary` | Tóm tắt hội thoại |
| `GET` | `/api/AiAssistant/usage` | Usage statistics |

---

## Contextual AI Coach

### Context APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/AiCoach/context` | Snapshot ngữ cảnh user (profile, nutrition, allergies) |
| `GET` | `/api/AiCoach/suggested-prompts` | 3-5 câu hỏi nhanh dựa trên tình trạng |

### Session Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiCoach/sessions` | Tạo phiên chat mới |
| `POST` | `/api/AiCoach/sessions/{sessionId}/messages` | Gửi message |
| `GET` | `/api/AiCoach/sessions/{sessionId}/history` | Lịch sử hội thoại |
| `DELETE` | `/api/AiCoach/sessions/{sessionId}` | Xóa phiên chat |
| `POST` | `/api/AiCoach/execute-action` | Thực thi action (log meal, create plan, etc.) |

### Feedback

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/AiCoach/messages/{messageId}/feedback` | Feedback cho AI response |

### Execute Action Types

```json
{
  "type": "log_meal",
  "confirmed": true,
  "payload": {
    "recipe_id": "uuid",
    "meal_slot": "dinner",
    "quantity_g": 250
  }
}
```

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

## Data Models

```
AiConversation
├── Id, UserId, Title, CreatedAt, UpdatedAt
└── Messages[] (AiMessage)

AiMessage
├── Id, ConversationId, Role (user/assistant)
├── Content, Tokens, CreatedAt
└── Feedback

UserAiProfile
├── UserId, Preferences
├── DislikedFoods, DietaryType
├── RecommendationTuning
└── CreatedAt, UpdatedAt
```

---

## Related Documents

- [AI Features API Full Spec](../README_AI_FEATURES_API.md)
- [AI Yellow Items Implementation Report](../AI_YELLOW_ITEMS_IMPLEMENTATION_REPORT.md)

---

*Last updated: 2026-07-05*
