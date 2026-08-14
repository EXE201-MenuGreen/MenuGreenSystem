# Điều chỉnh định lượng nguyên liệu theo mục tiêu dinh dưỡng

## Mục tiêu

PT có thể thay đổi định lượng từng nguyên liệu trước khi gửi lộ trình. Hệ thống tự tính lại kcal, protein, carb và fat, nhưng không cập nhật bản ghi gốc trong `foods`, `ingredients`, `recipes` hoặc `recipe_ingredients`.

## Nguyên tắc dữ liệu

- `recipe_ingredients` là công thức chuẩn trong danh mục.
- `meal_plan_proposal_items` giữ snapshot khẩu phần PT đang đề xuất.
- Khi gymer chấp nhận, snapshot được sao chép sang `meal_plan_items`.
- Khi gymer xác nhận đã ăn, `meal_logs` giữ snapshot thực tế và `consumption_ratio`.
- Việc đổi công thức chuẩn trong tương lai không làm thay đổi lộ trình hoặc lịch sử đã lưu.

Snapshot nguyên liệu dùng JSONB và gồm: `ingredientId`, tên, định lượng gốc, định lượng đã chỉnh, đơn vị, kcal, protein, carb và fat của dòng nguyên liệu.

## Cách tính

Với nguyên liệu có dữ liệu dinh dưỡng trên 100 g hoặc 100 ml:

```text
chỉ_số_dòng = chỉ_số_cơ_sở × định_lượng_mới / 100
```

Với nguyên liệu được lưu theo đơn vị đếm:

```text
chỉ_số_dòng = chỉ_số_cơ_sở × số_lượng_mới
```

Tổng dinh dưỡng món ăn là tổng các dòng nguyên liệu. Backend luôn tính lại từ dữ liệu nguyên liệu; không tin trực tiếp giá trị kcal do client gửi lên.

Khi gymer ghi nhận ăn khác khẩu phần dự kiến:

```text
consumption_ratio = actual_quantity_g / planned_quantity_g
dinh_dưỡng_thực_tế = dinh_dưỡng_kế_hoạch × consumption_ratio
```

## Tự cân bằng kcal trong ngày

Ở bước chọn món, cả Gymer đang soạn bản nháp và PT đang duyệt đều thấy tổng kcal
của bốn bữa theo từng ngày, số bữa đã có và trạng thái `Thiếu`, `Vượt` hoặc
`Đạt mục tiêu`. Khi bấm **Tự chỉnh**, hệ thống áp dụng cùng một hệ số cho tất cả
món trong ngày:

```text
hệ_số = kcal_mục_tiêu / tổng_kcal_hiện_tại
khối_lượng_món_mới = khối_lượng_món_cũ × hệ_số
định_lượng_nguyên_liệu_mới = định_lượng_nguyên_liệu_cũ × hệ_số
macro_mới = macro_cũ × hệ_số
```

Dùng một hệ số chung giúp giữ nguyên tỷ lệ kcal và macro giữa bữa sáng, trưa,
tối và bữa phụ. Sau khi làm tròn kcal từng món, sai số còn lại được cộng vào
món có kcal lớn nhất để tổng hiển thị bằng chính xác mục tiêu. PT vẫn có thể mở
từng món và chỉnh thủ công sau đó.

Gymer chỉ được tự chỉnh trước khi gửi RouteApproval. Sau khi gửi, giao diện khóa
nút và backend cũng từ chối mọi yêu cầu cân bằng, thêm, sửa hoặc xóa món của ngày
đó. PT vẫn được tự chỉnh hoặc chỉnh khối lượng món thủ công trong màn hình duyệt,
sau đó lưu/duyệt lộ trình.

Gymer gọi API nguyên tử sau để tránh chỉ cập nhật được một phần trong bốn món:

```http
POST /api/MealPlan/{planId}/balance-calories
```

Payload gồm `plannedDate`, `targetCalories` và `itemIds`. Backend tải snapshot
dinh dưỡng hiện tại, co giãn khẩu phần, xử lý sai số làm tròn và lưu cả bốn món
trong một lần.

Thuật toán chỉ cập nhật bản nháp của ngày đang chọn. Các bản ghi danh mục trong
`foods`, `recipes`, `ingredients` và `recipe_ingredients` không bị thay đổi.

## API

Điều chỉnh một món trong proposal đang ở trạng thái nháp:

```http
PUT /api/meal-plan-proposals/{proposalId}/items/{itemId}/portion
```

Payload:

```json
{
  "ingredients": [
    { "ingredientId": "uuid", "quantity": 150, "unit": "g" },
    { "ingredientId": "uuid", "quantity": 180, "unit": "g" }
  ]
}
```

Luồng gửi đánh giá của PT cũng chấp nhận `quantityG` và `ingredients` trong từng `mealPlanAdjustment`.

Luồng PT chủ động tạo hoặc cập nhật lộ trình qua
`/api/Coaches/clients/{clientId}/meal-plans` dùng cùng contract trong từng
`items`. Với món thường, backend tính theo `quantityG`. Với công thức, backend
ưu tiên danh sách `ingredients`; nếu công thức chưa có định lượng chi tiết thì
co giãn toàn bộ khẩu phần theo `quantityG`.

Trên ứng dụng PT, kcal/protein/carb/fat trong dialog chỉnh món là kết quả chỉ
đọc. PT thay đổi tổng gram hoặc định lượng nguyên liệu và ứng dụng cập nhật bản
xem trước; backend vẫn tính lại lần cuối trước khi lưu snapshot.

## Triển khai cơ sở dữ liệu

Schema mới nằm trực tiếp trong `26_meal_logs.sql` và `58_meal_plan_proposals.sql`. Khi dựng lại database, chạy tuần tự toàn bộ các file `01` đến `58`; dự án không còn dùng file compatibility riêng.

Các bản ghi cũ không có snapshot vẫn dùng dữ liệu công thức hiện tại để tương thích ngược.

## Hoàn tác

Rollback ứng dụng trước, sau đó chỉ xóa các cột mới khi chắc chắn không cần giữ snapshot lịch sử. Nên sao lưu các cột JSONB trước khi xóa.
