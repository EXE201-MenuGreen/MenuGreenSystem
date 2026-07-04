# AI Features API Specification

Tài liệu này tổng hợp toàn bộ tính năng AI cần có trong hệ thống, dùng làm cơ sở để build API backend cho Recommendation Engine, AI Nutrition Assistant và Contextual AI Coach.

---

## Status Legend

- `✅` Route/API surface đã có và đang dùng được.
- `⚠️` Đã có route nhưng logic nâng cao hoặc production-hardening chưa full.
- `❌` Chưa có hoặc chưa đạt đúng yêu cầu.

## 1. Recommendation Engine (Rule + AI)

**Mục tiêu:** Đề xuất món/thực đơn cá nhân hóa, vừa đúng dinh dưỡng vừa khả thi về ngân sách và thói quen Việt.

### Data Models

```csharp
// Lưu từng lần sinh gợi ý
RecommendationHistory
// Lưu đánh giá chất lượng gợi ý
RecommendationFeedback
// Lưu yêu cầu ngân sách
BudgetRequest
```

### API Endpoints

#### A. Sinh recommendation (✅ Đã có API)
- `✅ POST /api/Recommendation/generate` — sinh recommendation theo context user.
- `✅ POST /api/Recommendation/generate/safe` — sinh gợi ý an toàn, loại trừ dị ứng.
- `✅ POST /api/Recommendation/generate/daily-menu` — sinh thực đơn trong ngày.
- `✅ POST /api/Recommendation/generate/weekly-plan` — sinh plan theo tuần.
- `✅ POST /api/Recommendation/generate/budget-aware` — sinh đề xuất theo ngân sách.
- `✅ POST /api/Recommendation/generate/smart-schedule` — sinh đề xuất có giờ ăn gợi ý.

#### B. Lịch sử và truy vấn (✅ Đã có API)
- `✅ GET /api/Recommendation/history` — danh sách lịch sử recommendation của user.
- `✅ GET /api/Recommendation/{id}` — xem chi tiết một lần recommendation.
- `✅ DELETE /api/Recommendation/history/{id}` — xoá lịch sử không cần thiết.

#### C. Feedback loop (✅ Đã có API)
- `✅ POST /api/Recommendation/feedback` — user chấm chất lượng đề xuất.
- `✅ PUT /api/Recommendation/feedback/{id}` — cập nhật feedback nếu user đổi ý.
- `✅ GET /api/Recommendation/feedback/summary` — tổng hợp tỷ lệ thích/không thích.

#### D. Giải thích recommendation (✅ Đã có API)
- `✅ GET /api/Recommendation/explain/{id}` — giải thích vì sao món/thực đơn được đề xuất.

#### E. Tối ưu cá nhân hóa (✅ Đã hoàn thiện rule recalibration)
- `✅ POST /api/Recommendation/retrain` — dry-run/apply rule weights từ feedback đúng user, lưu tín hiệu preferred/avoided item vào `UserAiProfile` và ghi audit.
- `✅ GET /api/Recommendation/scores` — điểm phù hợp theo từng tiêu chí: calories, macro, dị ứng, ngân sách.

### Business Rules
- Rule-based là nền an toàn tối thiểu; AI là lớp nâng cao để cá nhân hóa theo ngữ cảnh.
- Recommendation phải trả về được lý do gợi ý để user tin và hiểu vì sao món đó xuất hiện.
- Tối ưu dần model/rule theo feedback.

---

## 2. AI Nutrition Assistant

**Mục tiêu:** Tương tác hội thoại và tư vấn tình huống. Lớp chat "coach dinh dưỡng" giúp user hỏi theo ngữ cảnh thực tế.

### Data Models

```csharp
// Phiên chat
AiConversation
// Tin nhắn trong phiên chat
AiMessage
// Hồ sơ AI cá nhân của user
UserAiProfile
```

### API Endpoints

#### A. Conversation lifecycle (✅ Đã có API)
- `✅ POST /api/AiAssistant/conversations` — tạo phiên chat mới.
- `✅ GET /api/AiAssistant/conversations` — danh sách hội thoại của user.
- `✅ GET /api/AiAssistant/conversations/{id}` — xem chi tiết hội thoại.
- `✅ DELETE /api/AiAssistant/conversations/{id}` — xoá hội thoại.
- `✅ PATCH /api/AiAssistant/conversations/{id}/title` — đổi tiêu đề hội thoại (hỗ trợ song song `POST /api/AiAssistant/conversations/{id}/title` để tương thích ngược với Mobile Flutter client).

#### B. Message workflow (✅ Đã có API)
- `✅ POST /api/AiAssistant/conversations/{id}/messages` — gửi message user và nhận response AI.
- `✅ GET /api/AiAssistant/conversations/{id}/messages` — lấy toàn bộ message trong hội thoại.
- `✅ POST /api/AiAssistant/conversations/{id}/messages/{messageId}/regenerate` — tạo lại câu trả lời AI.
- `✅ PATCH /api/AiAssistant/conversations/{id}/messages/{messageId}/feedback` — user chấm câu trả lời.

#### C. Context & profile (✅ Đã có API)
- `✅ GET /api/AiAssistant/context` — lấy context AI hiện tại từ profile/tracking/recommendation.
- `✅ PUT /api/AiAssistant/context` — cập nhật ngữ cảnh ưu tiên cho AI assistant (song hành cùng PUT /profile).
- `✅ GET /api/AiAssistant/profile` — đọc `UserAiProfile` để AI dùng cá nhân hóa.
- `✅ PUT /api/AiAssistant/profile` — cập nhật hồ sơ AI của user.

#### D. Action suggestions (✅ Đã có execution thật)
- `✅ GET /api/AiAssistant/suggestions` — đề xuất hành động tiếp theo từ hội thoại.
- `✅ POST /api/AiAssistant/actions/meal-plan` — tạo meal plan 7 ngày qua worker theo target, budget và thời gian nấu thật của user.
- `✅ POST /api/AiAssistant/actions/replace-food` — lấy món gốc từ DB và gọi safe recommendation, loại món gốc cùng dị ứng.
- `✅ POST /api/AiAssistant/actions/budget-optimize` — dùng budget/profile thật và trả recommendation đã lưu history.

#### E. History/analytics (✅ Đọc dữ liệu hội thoại thật)
- `✅ GET /api/AiAssistant/insights` — thống kê chủ đề và tỷ lệ quan tâm từ user messages thật.
- `✅ GET /api/AiAssistant/conversations/{id}/summary` — tóm tắt extractive theo nội dung, chủ đề và câu hỏi chính của hội thoại thuộc user.
- `✅ GET /api/AiAssistant/usage` — tổng hợp usage theo ngày, tuần, tháng, active days và last-used thật.

### Business Rules
- AI assistant có thể gọi recommendation, meal plan, nutrition tracking như các công cụ phụ trợ (Function Calling / Tool Use).
- Output không chỉ là câu trả lời mà còn là hành động gợi ý tiếp theo.
- Lưu lịch sử chat để làm dữ liệu train tiếp theo và duy trì trí nhớ ngắn hạn/dài hạn.

---

## 3. Contextual AI Coach

**Mục tiêu:** Lớp AI sâu, cá nhân hóa cao, nhận context từ toàn bộ hệ thống để đưa vào prompt.

### Context Extraction APIs (✅ Đã có API surface)

#### A. API Lấy Ngữ cảnh Dinh dưỡng cho AI
- `✅ GET /api/AiCoach/context` — Lấy toàn bộ snapshot ngữ cảnh của user cho ngày hiện tại (hoặc ngày cụ thể).

**Response structure:**
```json
{
  "userProfile": {
    "gender": "male",
    "age": 28,
    "weightKg": 72.5,
    "heightCm": 175,
    "goalMode": "Bulk",
    "vietnameseRegion": "South"
  },
  "nutritionalTarget": {
    "caloriesKcal": 2400,
    "proteinG": 150,
    "carbsG": 280,
    "fatG": 75
  },
  "actualIntakeToday": {
    "caloriesKcal": 1850,
    "proteinG": 115,
    "carbsG": 230,
    "fatG": 55,
    "waterMl": 1500
  },
  "remainingBudgetToday": {
    "caloriesKcal": 550,
    "proteinG": 35,
    "carbsG": 50,
    "fatG": 20
  },
  "safetyAndAllergies": {
    "allergenKeys": ["peanut", "seafood"],
    "allergyRiskLevel": "High"
  },
  "preferences": {
    "dietaryType": "CleanEating",
    "dislikedIngredients": ["hành tây", "ngò rí"]
  },
  "currentMealPlan": {
    "plannedMeals": ["Ức gà áp chảo", "Cơm lứt", "Salad bơ"],
    "completedMeals": ["Cơm lứt", "Ức gà áp chảo"]
  }
}
```

- `✅ GET /api/AiCoach/suggested-prompts` — Gợi ý 3-5 câu hỏi nhanh dựa trên tình trạng dinh dưỡng ngày hiện tại.

#### B. API Quản lý Hội thoại Chat & Hành động (Function Calling)
- `✅ POST /api/AiCoach/sessions` — Khởi tạo phiên trò chuyện mới.
- `✅ POST /api/AiCoach/sessions/{sessionId}/messages` — Gửi tin nhắn user và nhận phản hồi AI.
- `✅ GET /api/AiCoach/sessions/{sessionId}/history` — Lấy lịch sử hội thoại.
- `✅ DELETE /api/AiCoach/sessions/{sessionId}` — Xóa lịch sử phiên chat.
- `✅ POST /api/AiCoach/execute-action` — thực thi action sau confirmation: meal plan, replace food, budget optimize, schedule meal, log meal, show recipe và follow-up; action ghi dữ liệu có audit.

#### C. API Ghi nhận phản hồi để Train Model
- `✅ POST /api/AiCoach/messages/{messageId}/feedback` — Ghi nhận phản hồi của user về câu trả lời AI (Like/Dislike, lý do hữu ích/không hữu ích, sai sót thông tin).

### Business Rules
- Backend tổng hợp context từ: `HealthProfile`, `UserAllergy`, `NutritionTrackingService`, `Goals/drift-alerts`, `GymGoals/alerts`.
- Dịch vụ AI ghép ngữ cảnh JSON vào System Prompt cho model LLM.
- Lưu lịch sử chat để train model và duy trì trí nhớ.

---

## 4. Supporting APIs & Integration Points

### Nutrition & Tracking APIs (Tái sử dụng)
- `GET /Nutrition/recommendations/budget-aware` — gợi ý món theo mục tiêu dinh dưỡng và ngân sách.
- `GET /Nutrition/recommendations/local-friendly` — gợi ý món dễ ăn, dễ tìm, phù hợp thói quen Việt.
- `POST /Nutrition/recommendations/feedback` — ghi nhận feedback để tối ưu gợi ý local.

### Allergy APIs (Tái sử dụng)
- `GET /api/Allergy/recommendations` — gợi ý món phù hợp với hồ sơ dị ứng.

- `GET /api/Recipe/{recipeId}/safe-alternatives` — tìm công thức thay thế an toàn.

### Meal Plan APIs (Tái sử dụng)
- `POST /api/MealPlan/{planId}/items/{itemId}/substitute-ingredient` — thay thế nguyên liệu.
- `POST /api/NutritionTracking/meal-logs/{mealLogId}/substitute-ingredient` — ghi nhận thay thế trong nhật ký.

### Onboarding APIs (Tái sử dụng)
- `GET /api/UserAiProfile/me` — lấy profile AI/personalization hiện tại.
- `GET /api/DailyStarter/recommendations` — lấy thực đơn gợi ý cho user mới.

### Analytics APIs (Tái sử dụng)
- `GET /api/Analytics/planned-vs-actual` — so sánh kế hoạch và thực tế.
- `GET /api/Analytics/planned-vs-actual/adherence-score` — điểm bám sát kế hoạch.
- `GET /api/Analytics/planned-vs-actual/drift-analysis` — phân tích nguyên nhân lệch.
- `GET /api/Analytics/planned-vs-actual/recommendations` — gợi ý hành động khắc phục.
- `POST /api/Analytics/planned-vs-actual/recalibrate` — tái phân bổ calo/macro tuần tiếp theo.

---

## 5. Implementation Priority

### Phase 1: Foundation (Trước)
1. **Data Models** — Tạo `AiConversation`, `AiMessage`, `UserAiProfile` trong DB.
2. **Context APIs** — Build `AiCoach/context` và `AiCoach/suggested-prompts` để cung cấp snapshot cho AI.
3. **AI Provider Integration** — Nối LLM provider (OpenAI/Azure/local model) vào backend, xử lý prompt orchestration.

### Phase 2: Core AI Features
1. **AI Nutrition Assistant Chat** — Build conversation/message CRUD + gọi LLM + streaming response.
2. **AI Nutrition Assistant Context** — Kết nối context từ tracking, profile, allergy vào assistant.
3. **Function Calling** — Cho phép AI thực hiện hành động (log meal, tạo meal plan, nhắc uống nước).

### Phase 3: Advanced Features
1. **Smart Recommendation** — Nâng cao recommendation engine với AI layer.
2. **Feedback Loop** — Thu thập feedback để train/tune model.
3. **Insights & Analytics** — Thống kê sử dụng AI, tóm tắt hội thoại, phân tích xu hướng.

### Phase 4: Optimization
1. **Personalization** — Tối ưu prompt dựa trên `UserAiProfile` và lịch sử.
2. **Localization** — Gợi ý prompt và response phù hợp văn hóa Việt Nam.
3. **Performance** — Cache context, tối ưu latency, streaming response.

---

## 6. Technical Considerations

### Backend Message Convention
- **Backend responses:** Tiếng Anh (JSON fields, error messages, enum values).
- **Frontend display:** Dịch sang tiếng Việt trước khi show user.

### LLM Provider
- API nên trừu tượng để dễ đổi provider (OpenAI, Azure OpenAI, local LLM).
- Prompt system nên inject context JSON vào system message.
- Cần xử lý streaming cho response tốt UX.

### Safety & Guardrails
- Luôn áp dụng rule-based filter trước khi gửi vào LLM (loại trừ dị ứng, giới hạn calo).
- AI response cần được validate trước khi trả về user (không trả lời trái medical advice).
- Log tất cả AI interactions để audit và train model.

### Subscription Gating
- Tính năng AI có thể là Premium feature.
- Kiểm tra entitlement trước khi gọi AI API.

---

## 7. Current Status Summary

Estimated API surface completion: **97-98%**

| Feature | Status |
|---------|--------|
| Recommendation Engine (rule-based) | ✅ Đã có API cơ bản |
| Recommendation History/Feedback/Explain | ✅ Đã có API |
| Recommendation Smart-schedule | ✅ Đã có API |
| AI Nutrition Assistant (Chat) | ✅ Đã có API |
| AI Context APIs | ✅ Đã có API |
| AI Function Calling | ✅ Confirmation-gated execution + audit |
| AI Feedback Loop for Training | ✅ Đã có API cơ bản |
| AI Insights/Analytics | ✅ Thống kê từ conversation/message thật |

---

## 8. Hướng dẫn Test & Ví dụ JSON Body cho các API Đầu vào

Để thuận tiện cho việc test bằng Postman, Swagger hoặc tích hợp Frontend, dưới đây là các cấu trúc JSON Body mẫu cho tất cả các API đầu vào của cả **AI Nutrition Assistant** và **Contextual AI Coach**:

---

### PHẦN I. API CỦA AI NUTRITION ASSISTANT (Trợ lý Dinh dưỡng Chung)

#### 1. Tạo phiên chat mới (`POST /api/AiAssistant/conversations`)
```json
{
  "firstMessage": "Tôi muốn bắt đầu hành trình ăn uống lành mạnh"
}
```

#### 2. Cập nhật tiêu đề cuộc trò chuyện (`PATCH` / `POST /api/AiAssistant/conversations/{id}/title`)
```json
{
  "title": "Kế hoạch ăn uống giảm mỡ bụng"
}
```

#### 3. Gửi tin nhắn và nhận phản hồi AI (`POST /api/AiAssistant/conversations/{id}/messages`)
```json
{
  "message": "Tôi bị dị ứng lạc (đậu phộng), hãy gợi ý cho tôi một bữa tối lành mạnh không chứa lạc.",
  "language": "vi",
  "stream": false
}
```

#### 4. Gửi phản hồi feedback cho tin nhắn trợ lý (`PATCH` / `POST /api/AiAssistant/conversations/{id}/messages/{msgId}/feedback`)
```json
{
  "isPositive": true,
  "reason": "Helpful",
  "comment": "Các gợi ý thay thế ức gà rất chi tiết và dễ mua!"
}
```

#### 5. Cập nhật hồ sơ AI và ngữ cảnh ưu tiên (`PUT /api/AiAssistant/context` hoặc `PUT /api/AiAssistant/profile`)
```json
{
  "preferences": "nhẹ bụng, ít dầu mỡ, nhiều đạm",
  "dislikedFoods": "hành tây, ngò rí",
  "eatingPattern": "Keto"
}
```

#### 6. AI gợi ý tạo thực đơn bằng Prompt (`POST /api/AiAssistant/actions/meal-plan`)
```json
{
  "prompt": "Lên thực đơn 1700 calo nhiều protein cho hôm nay"
}
```

#### 7. Gợi ý đổi món thay thế an toàn (`POST /api/AiAssistant/actions/replace-food`)
```json
{
  "foodId": "fd000008-0000-0000-0000-000000000008",
  "reason": "Dị ứng trứng gà"
}
```

---

### PHẦN II. API CỦA CONTEXTUAL AI COACH (Huấn luyện viên Cá nhân)

#### 1. Khởi tạo phiên trò chuyện (`POST /api/AiCoach/sessions`)
```json
{
  "firstMessage": "Chào AI Coach, hãy giúp tôi lên thực đơn hôm nay"
}
```

#### 2. Gửi tin nhắn trong cuộc trò chuyện (`POST /api/AiCoach/sessions/{sessionId}/messages`)
```json
{
  "message": "Tôi bị dị ứng lạc (đậu phộng), hãy gợi ý cho tôi một bữa tối lành mạnh không chứa lạc.",
  "language": "vi",
  "stream": false
}
```

#### 3. Gửi phản hồi feedback cho tin nhắn của Coach (`POST /api/AiCoach/messages/{messageId}/feedback`)
```json
{
  "isPositive": false,
  "reason": "IncorrectInformation",
  "comment": "Món ăn gợi ý có chứa nguyên liệu gây dị ứng của tôi"
}
```

#### 4. Thực thi hành động AI (`POST /api/AiCoach/execute-action`)

##### A. Hành động: Ghi nhật ký ăn uống (`log_meal`)
```json
{
  "type": "log_meal",
  "confirmed": true,
  "payload": {
    "recipe_id": "ec000004-0000-0000-0000-000000000004",
    "meal_slot": "dinner",
    "quantity_g": 250,
    "unit": "g",
    "notes": "Test ghi bữa tối qua Swagger"
  }
}
```

##### B. Hành động: Tạo thực đơn 7 ngày (`generate_meal_plan`)
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

##### C. Hành động: Lên lịch bữa ăn (`schedule_meal`)
```json
{
  "type": "schedule_meal",
  "confirmed": true,
  "payload": {
    "recipe_id": "ec000004-0000-0000-0000-000000000004",
    "meal_slot": "breakfast",
    "planned_date": "2026-07-05",
    "scheduled_time": "07:30:00"
  }
}
```

---

*Tài liệu này được tổng hợp từ `README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md` và các yêu cầu hệ thống hiện có.*
