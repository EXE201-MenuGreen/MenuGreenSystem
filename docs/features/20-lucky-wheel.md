# 20. Lucky Wheel (Vòng Quay May Mắn)

**Status:** PLANNED / DỰ KIẾN (Chưa triển khai)  
**Last updated:** 2026-07-14

**Related controller:** `backend/MenuGreen.API/Controllers/LuckyWheelController.cs` (Dự kiến)  
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/LuckyWheelService.cs` (Dự kiến)  

---

## 1. Overview

**Vòng Quay May Mắn (Lucky Wheel)** là một tính năng game hóa (gamification) độc quyền dành riêng cho gói **Casual** (người dùng phổ thông, băn khoăn về chế độ ăn uống). Tính năng này khuyến khích tương tác hàng ngày bằng cách tặng quà ngẫu nhiên mỗi 24 giờ như điểm thói quen, công thức ăn uống lành mạnh ngẫu nhiên, hoặc mẹo nhanh.

---

## 2. Business Rules

- Chỉ người dùng có vai trò `Casual` hoặc `Admin` được phép tham gia vòng quay.
- Mỗi người dùng chỉ được quay tối đa **1 lần mỗi ngày** (tính theo ngày UTC hoặc ngày địa phương).
- Trạng thái quay của ngày hôm nay sẽ được lưu trữ và kiểm tra trước khi thực hiện lượt quay mới.
- **Cơ cấu phần thưởng dự kiến**:
  - **Points (Điểm)**: Cộng trực tiếp 5, 10, hoặc 20 điểm thói quen vào tài khoản.
  - **Recipe (Công thức)**: Đề xuất ngẫu nhiên công thức nấu ăn ngon như *Salad ức gà*, *Cá hồi sốt chanh*.
  - **Tip (Mẹo)**: Gợi ý nhanh về lối sống lành mạnh (ví dụ: *Uống thêm 250ml nước lọc ngay bây giờ*).

---

## 3. Planned API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/LuckyWheel/spin` | Quay vòng quay (1 lần/ngày), chọn giải thưởng ngẫu nhiên và lưu vết |
| `GET` | `/api/LuckyWheel/status` | Kiểm tra trạng thái lượt quay ngày hôm nay và thời gian được quay tiếp theo |

---

## 4. UI Components (Planned)

- **Màn hình Vòng quay**: Giao diện vòng tròn may mắn quay thưởng với các ô giải thưởng, nút "Quay Ngay" (bị vô hiệu hóa và hiển thị đếm ngược nếu đã quay hôm nay).
- **Hộp thoại chúc mừng**: Hiển thị khi quay trúng phần thưởng kèm nút "Xem công thức" (nếu trúng công thức) hoặc "OK".

---

## 5. Relationship with Other Modules

- **ActivityLog**: Lưu trữ nhật ký hoạt động quay thưởng để kiểm soát giới hạn lượt quay hàng ngày.
- **User / Profiles**: Cộng điểm tích lũy vào tài khoản học tập/thói quen của người dùng.
- **Recipe & Catalog**: Truy vấn và gợi ý các món ăn/công thức có sẵn trong hệ thống khi trúng giải công thức.
