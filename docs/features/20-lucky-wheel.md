# Tính năng 20: Vòng Quay Món Ăn (Food Lucky Wheel)

## 1. Tổng quan
Vòng Quay Món Ăn là một tính năng hỗ trợ ra quyết định và tăng tính tương tác (Gamification) dành cho nhóm người dùng **Casual / Simple Eater (Nhóm Ăn uống đơn giản)**. Tính năng này giúp họ giải quyết câu hỏi khó khăn *"Hôm nay ăn gì?"* bằng cách lựa chọn ngẫu nhiên 1 trong 10 món ăn được gợi ý cá nhân hóa và không bị trùng lặp từ cơ sở dữ liệu.

---

## 2. Thuật toán lựa chọn món ăn cá nhân hóa
Khi người dùng truy cập vào màn hình vòng quay, Backend sẽ tự động tạo ra một danh sách gồm chính xác **10 món ăn không trùng lặp** theo các nguyên tắc sau:
1. **Loại bỏ chất gây dị ứng (Allergens)**: Truy vấn danh sách các chất gây dị ứng đang hoạt động của người dùng. Hệ thống sẽ lọc bỏ tất cả các món ăn chứa thành phần gây dị ứng cho người dùng đó.
2. **Chấm điểm độ tương thích (Personalization Scoring)**: Với mỗi món ăn an toàn còn lại, hệ thống tính toán điểm tương thích:
   - **Phù hợp ngân sách (+10 điểm)**: Giá tiền ước tính của món ăn bằng hoặc thấp hơn cấu hình `BudgetPerMealVnd` (Ngân sách mỗi bữa ăn) trong sở thích của người dùng.
   - **Phù hợp vùng miền (+15 điểm)**: Vùng miền ẩm thực của món ăn trùng khớp với miền ăn uống ưu thích của người dùng (`VietnamRegion` - Bắc, Trung, hoặc Nam).
   - **Phù hợp sở thích cá nhân (+20 điểm)**: Tên món ăn có chứa các từ khóa nằm trong danh sách món ăn ưa thích trong hồ sơ AI của người dùng.
3. **Lựa chọn ứng viên ngẫu nhiên**:
   - Sắp xếp các món ăn an toàn theo điểm tương thích từ cao xuống thấp.
   - Chọn ra 30 ứng viên có điểm số cao nhất.
   - Lấy ngẫu nhiên ra 10 món ăn không trùng lặp từ nhóm 30 ứng viên này để vẽ lên các ô trên vòng quay. Điều này vừa đảm bảo món ăn phù hợp với người dùng vừa mang lại sự đa dạng đổi mới mỗi khi mở vòng quay.

---

## 3. Các API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| `GET`  | `/api/LuckyWheel/foods` | Trả về danh sách 10 món ăn cá nhân hóa và không trùng lặp để vẽ lên vòng quay. |
| `POST` | `/api/LuckyWheel/apply` | Áp dụng món ăn được chọn vào thực đơn của ngày hôm nay theo bữa tương ứng (Sáng, Trưa, Tối, Phụ). |

---

## 4. Luồng trải nghiệm người dùng (UI/UX Flow)
1. Người dùng nhấp vào mục **"Vòng quay món ăn"** từ trang cá nhân hoặc bảng điều khiển.
2. Ứng dụng tải về 10 món ăn cá nhân hóa từ Backend và vẽ tên các món ăn lên 10 ô của vòng quay di động.
3. Người dùng nhấn nút **"Quay Ngay"**. Vòng quay sẽ xoay tròn với hiệu ứng vật lý giảm tốc mượt mà và dừng lại ở món ăn trúng thưởng.
4. Một hộp thoại popup hiện lên hiển thị tên món ăn, mô tả, calo, thành phần dinh dưỡng (Protein, Carbs, Fat), giá dự kiến cùng hai nút hành động:
   - **"Ăn món này"**: Gửi yêu cầu POST lên API để thêm món ăn này vào thực đơn của ngày hôm nay, sau đó tự động đóng màn hình và quay về trang chủ.
   - **"Quay lại"**: Đóng hộp thoại để người dùng có thể quay lại món ăn khác.
