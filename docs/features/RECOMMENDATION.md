# Recommendation Engine

**Status:** ✅ API Complete | 🟡 UI Partial (Flutter)

---

## Overview

Recommendation Engine cung cấp gợi ý món ăn/công thức cá nhân hóa dựa trên:
- Profile người dùng (calories target, macros, dị ứng)
- Ngân sách & thời gian nấu
- Lịch sử feedback

---

## API Endpoints

### A. Generate Recommendations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Recommendation/generate` | Generate recommendation theo context |
| `POST` | `/api/Recommendation/generate/safe` | Safe - loại trừ dị ứng |
| `POST` | `/api/Recommendation/generate/daily-menu` | Menu trong ngày |
| `POST` | `/api/Recommendation/generate/weekly-plan` | Plan theo tuần |
| `POST` | `/api/Recommendation/generate/budget-aware` | Theo ngân sách |
| `POST` | `/api/Recommendation/generate/smart-schedule` | Có giờ ăn gợi ý |

### B. History & Feedback

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Recommendation/history` | Lịch sử recommendations |
| `GET` | `/api/Recommendation/{id}` | Chi tiết recommendation |
| `DELETE` | `/api/Recommendation/history/{id}` | Xóa lịch sử |
| `POST` | `/api/Recommendation/feedback` | Gửi feedback |
| `PUT` | `/api/Recommendation/feedback/{id}` | Cập nhật feedback |
| `GET` | `/api/Recommendation/feedback/summary` | Tổng hợp feedback |

### C. Explain & Optimize

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Recommendation/explain/{id}` | Giải thích tại sao gợi ý |
| `GET` | `/api/Recommendation/scores` | Điểm phù hợp theo tiêu chí |
| `POST` | `/api/Recommendation/retrain` | Tối ưu cá nhân hóa từ feedback |

---

## Scoring System

### Calorie Score
```
Score = |ActualCalories - TargetCalories|
```
- Thấp hơn = tốt hơn

### Eco Score
```
Score = (Budget - Price) + LimitMinutes
```
- Tối ưu giá + thời gian

### Lunch Score
```
Score = |Calories - Target| + max(0, Price - Budget) + max(0, Time - 20min)
```
- Phù hợp bữa trưa vội

---

## Personalization (Retrain)

`POST /api/Recommendation/retrain`:
- Đọc feedback của user hiện tại
- Tính trọng số theo mode (lose weight, gain weight, maintain)
- Lưu vào `UserAiProfile.Preferences.recommendationTuning`
- Ghi audit log

---

## Related Documents

- [AI Features API](./AI_ASSISTANT.md)
- [Nutrition Calculations](./NUTRITION_CALCULATIONS_README.md)

---

*Last updated: 2026-07-05*
