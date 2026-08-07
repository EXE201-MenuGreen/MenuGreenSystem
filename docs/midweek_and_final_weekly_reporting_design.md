# Thiết kế báo cáo giữa tuần và cuối tuần

## Mục tiêu

- Tách check-in giữa tuần khỏi báo cáo tổng kết cuối tuần.
- Chỉ điều chỉnh món tương lai và luôn xác định chính xác món cũ/món mới.
- Không thay đổi meal plan cho đến khi Gymer duyệt toàn bộ đề xuất.
- Nhắc Gymer lúc 23:45 (Asia/Ho_Chi_Minh) bằng thông báo trong ứng dụng và push.

## Quy tắc nghiệp vụ

### Check-in giữa tuần

- Chỉ tạo một lần vào Thứ Năm, trong khung 00:00–23:59 giờ Việt Nam.
- Dữ liệu báo cáo chạy từ Thứ Hai đến thời điểm gửi.
- PT chỉ được chỉnh Thứ Sáu–Chủ nhật của cùng tuần.
- `Replace` và `Remove` phải tham chiếu một `MealPlanItem` hiện hữu.
- `Add` phải chọn `Food` hoặc `Recipe` cụ thể.
- Gymer duyệt hoặc từ chối toàn bộ proposal.
- Proposal chưa xử lý được nhắc lúc 23:45 và hết hạn lúc 00:00 Thứ Sáu; meal plan cũ được giữ nguyên.

### Báo cáo cuối tuần

- Chỉ tạo một lần vào Chủ nhật, trong khung 00:00–23:59 giờ Việt Nam.
- Hệ thống tạo bản nháp meal plan cho Thứ Hai–Chủ nhật tuần kế tiếp.
- PT chỉnh trực tiếp bản nháp và gửi một proposal hoàn chỉnh.
- Gymer duyệt hoặc từ chối toàn bộ proposal.
- Proposal chưa xử lý được nhắc lúc 23:45 Chủ nhật nhưng không tự hết hạn và không tự áp dụng.

## Mô hình dữ liệu

### `MealPlanProposal`

- `Id`, `UserId`, `CoachId`, `ReviewRequestId`
- `ProposalType`: `CurrentWeekAdjustment` hoặc `NextWeekPlan`
- `Status`: `Draft`, `Pending`, `Applied`, `Rejected`, `Expired`
- `PeriodStart`, `PeriodEnd`, `ExpiresAt`
- `SourcePlanVersion`, `ReminderSentAt`
- `CreatedAt`, `SubmittedAt`, `ActionedAt`, `UpdatedAt`

### `MealPlanProposalItem`

- `Id`, `ProposalId`, `Action`, `PlannedDate`, `MealType`
- `ExistingMealPlanItemId`
- `FoodId`, `RecipeId`, `QuantityG`, `TargetCalories`, `SortOrder`

## Luồng trạng thái

```text
Draft -> Pending -> Applied
                 -> Rejected
                 -> Expired (chỉ giữa tuần)
```

Apply phải idempotent và chạy trong transaction. Proposal chỉ được xử lý khi thuộc Gymer hiện tại, còn `Pending`, chưa hết hạn và các món nguồn vẫn tồn tại.

## API

- `POST /api/reviews/midweek`
- `POST /api/reviews/{reviewId}/proposal/draft`
- `GET /api/meal-plan-proposals/{id}`
- `PUT /api/meal-plan-proposals/{id}`
- `POST /api/meal-plan-proposals/{id}/submit`
- `POST /api/meal-plan-proposals/{id}/apply`
- `POST /api/meal-plan-proposals/{id}/reject`

## Job nền

- Chạy theo lịch 23:45 giờ Việt Nam.
- Chỉ lấy proposal `Pending` chưa có `ReminderSentAt` trong deadline hiện tại.
- Tạo notification trong ứng dụng trước, push sau; push lỗi không rollback notification.
- Việc gửi có tính idempotent và retry an toàn.
- Một lượt kiểm tra sau 00:00 chuyển proposal giữa tuần quá hạn sang `Expired`.

## Bảo mật và độ tin cậy

- Chỉ PT đang kết nối mới tạo/chỉnh proposal của Gymer.
- Gymer chỉ xem và xử lý proposal của chính mình.
- Lưu dấu vết người tạo, người xử lý và thời điểm chuyển trạng thái.
- Index `Status + ExpiresAt` phục vụ quét theo lô; mục tiêu tối thiểu 10.000 proposal/lượt.

## Kiểm thử bắt buộc

- Quy tắc Thứ Năm/Chủ nhật theo timezone Việt Nam.
- Add/Replace/Remove đúng món và đúng phạm vi ngày.
- Apply toàn bộ hoặc rollback toàn bộ; không apply hai lần.
- Quyền PT/Gymer, proposal hết hạn và dữ liệu nguồn đã thay đổi.
- Job 23:45 không gửi trùng, có retry, hết hạn đúng loại proposal.
- Widget test cho form giữa tuần, cuối tuần và preview trước/sau.

## Decision log

- Chọn mô hình lai: giữ `PtReviewRequest`, tách thay đổi meal plan thành proposal.
- Check-in giữa tuần cố định Thứ Năm và độc lập với báo cáo Chủ nhật.
- Gymer duyệt toàn bộ; không duyệt từng món trong phiên bản đầu.
- Không tự động áp dụng khi Gymer im lặng.
- Giữa tuần hết hạn lúc 00:00 Thứ Sáu; cuối tuần tiếp tục chờ.
- Nhắc bằng in-app và push lúc 23:45.

