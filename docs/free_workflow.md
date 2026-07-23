# MenuGreen — Luồng nghiệp vụ và phạm vi tính năng dành cho người dùng Free

> Tài liệu mô tả cách hoạt động đề xuất cho nhóm người dùng Free trong hệ thống MenuGreen.  
> Mục tiêu là đảm bảo người dùng không mua gói vẫn có một trải nghiệm dinh dưỡng hoàn chỉnh, hữu ích và đáng tin cậy, đồng thời không làm trùng giá trị cốt lõi của các gói Casual, Office và Gym/PT.

---

## 1. Mục tiêu

Nhóm Free là lớp trải nghiệm nền tảng của MenuGreen. Người dùng Free phải có thể:

- thiết lập hồ sơ sức khỏe và dinh dưỡng cơ bản;
- tự tìm kiếm, lựa chọn và ghi nhận món ăn;
- theo dõi lượng calorie, macro và cân nặng;
- tạo kế hoạch ăn thủ công;
- lưu món, mẫu bữa ăn và sở thích cá nhân;
- quản lý dị ứng, consent và quyền dữ liệu;
- sử dụng ứng dụng hằng ngày mà không bắt buộc phải mua gói.

Nhóm Free không tập trung vào tự động hóa sâu, game hóa hoặc quy trình chuyên biệt. Các giá trị đó thuộc về:

- **Casual:** tự động gợi ý nhanh, Daily Starter, Lucky Wheel, micro-learning cá nhân hóa và game hóa;
- **Office:** kế hoạch cơm hộp, ngân sách, danh sách đi chợ và nhắc nhở theo môi trường công sở;
- **Gym/PT:** mục tiêu hình thể, PT Review, Coach và chương trình tập luyện dài hạn.

Nguyên tắc tổng quát:

```text
Free = người dùng chủ động sử dụng công cụ
Casual = hệ thống chủ động giúp người dùng ra quyết định nhanh
Office = hệ thống tổ chức ăn uống theo môi trường làm việc
Gym/PT = hệ thống tối ưu dinh dưỡng theo mục tiêu luyện tập
```

---

## 2. Phạm vi người dùng Free

Người dùng Free là tài khoản đã đăng ký và hoàn thành các bước onboarding tối thiểu nhưng không có entitlement trả phí đang hiệu lực.

Entitlement mặc định:

```text
free_features
```

`free_features` luôn được cấp cho tài khoản người dùng hợp lệ, không phụ thuộc vào subscription Office, Gym/PT hoặc Casual.

Người dùng có subscription trả phí vẫn giữ toàn bộ quyền Free:

```text
Free + Office
Free + Gym/PT
Free + Casual
Free + Office + Gym/PT
```

Không có trường hợp mua gói trả phí làm mất quyền Free.

---

## 3. Nguyên tắc thiết kế trải nghiệm Free

### 3.1. Free phải là một sản phẩm hoàn chỉnh

Free không nên tạo cảm giác là bản dùng thử bị cắt xén. Người dùng phải hoàn thành được vòng lặp cơ bản:

```text
Thiết lập hồ sơ
→ tìm hoặc chọn món
→ xem dinh dưỡng
→ ghi nhận bữa ăn
→ theo dõi tiến độ
→ điều chỉnh hành vi
```

### 3.2. Free ưu tiên thao tác chủ động

Người dùng Free tự:

- tìm món;
- chọn món;
- nhập bữa ăn;
- điều chỉnh khẩu phần;
- tạo kế hoạch;
- theo dõi tiến độ;
- đọc nội dung dinh dưỡng.

Hệ thống có thể hỗ trợ bằng bộ lọc, dữ liệu và tính toán cơ bản nhưng không nên tự động quyết định thay người dùng giống gói Casual.

### 3.3. Không khóa dữ liệu cá nhân cơ bản

Người dùng luôn được xem:

- hồ sơ đã nhập;
- lịch sử cân nặng;
- nhật ký bữa ăn;
- món yêu thích;
- kế hoạch thủ công;
- dữ liệu consent;
- quyền truy cập dữ liệu;
- báo cáo hoặc dữ liệu đã tạo từ trước.

Không nên bắt mua gói mới được xem dữ liệu cá nhân của chính mình.

### 3.4. Frontend không thay thế authorization

Frontend chỉ lọc và trình bày tính năng. Backend là nguồn sự thật duy nhất về quyền truy cập.

```text
Ẩn shortcut ≠ authorization
```

Mọi API Free yêu cầu người dùng đã xác thực. Mọi API Office, Gym/PT hoặc Casual chuyên biệt phải có policy entitlement tương ứng.

---

## 4. Danh mục chức năng Free đề xuất

| Nhóm | Chức năng |
|---|---|
| Tài khoản và hồ sơ | Đăng ký, đăng nhập, onboarding, hồ sơ sức khỏe cơ bản |
| An toàn | Dị ứng, consent, quyền dữ liệu, báo cáo sự cố |
| Tra cứu | Tìm món, xem chi tiết món, calorie, macro, nguyên liệu, công thức |
| Ghi nhận | Ghi bữa ăn thủ công, ghi bữa ăn ngoài, chỉnh khẩu phần |
| Theo dõi | Dashboard cơ bản, calorie trong ngày, macro cơ bản, cân nặng |
| Tổ chức cá nhân | Yêu thích, thực đơn đã lưu, sở thích vùng miền và khẩu vị |
| Kế hoạch | Tạo kế hoạch ăn thủ công, đánh dấu đã ăn, so sánh kế hoạch với thực tế cơ bản |
| Kiến thức | Thư viện nội dung dinh dưỡng chung, không cá nhân hóa sâu |
| Quét cơ bản | Quét nguyên liệu hoặc món ăn ở mức cơ bản nếu chi phí hệ thống cho phép |

---

## 5. Luồng đăng ký và onboarding

### 5.1. Đăng ký

Người dùng có thể đăng ký bằng:

- Email và OTP;
- Google Sign-In;
- phương thức đăng nhập khác nếu hệ thống hỗ trợ.

Sau khi đăng ký:

```text
Role = User hoặc Free theo mô hình hiện tại
Entitlement = free_features
```

Không nên dùng role để đại diện cho gói sản phẩm. Role nên phục vụ quyền hệ thống như `User`, `Admin`, `Coach`; entitlement dùng cho quyền tính năng.

### 5.2. Onboarding cơ bản

Người dùng nhập:

- ngày sinh hoặc tuổi;
- giới tính nếu nghiệp vụ cần;
- chiều cao;
- cân nặng hiện tại;
- cân nặng mục tiêu;
- mức độ hoạt động;
- mục tiêu cơ bản: giữ cân, giảm cân hoặc tăng cân lành mạnh;
- dị ứng;
- sở thích món ăn;
- vùng miền và khẩu vị.

Backend có thể tính:

- BMI;
- BMR;
- TDEE;
- calorie target;
- macro mục tiêu cơ bản.

### 5.3. Cho phép bỏ qua một phần onboarding

Các trường an toàn như dị ứng cần được nhắc rõ. Các trường không bắt buộc có thể cho phép bỏ qua và bổ sung sau.

Nếu dữ liệu chưa đầy đủ, ứng dụng không nên chặn toàn bộ Home. Thay vào đó hiển thị card:

```text
Hoàn thiện hồ sơ để tính calorie chính xác hơn
[Hoàn thiện hồ sơ]
```

---

## 6. Home dành cho người dùng Free

## 6.1. Mục tiêu của Home

Home Free phải giúp người dùng trả lời nhanh:

- Hôm nay tôi đã ghi những gì?
- Tôi đã dùng bao nhiêu calorie?
- Tôi còn cần làm gì?
- Tôi có thể tìm hoặc ghi món ở đâu?

Home không nên biến thành danh sách quảng cáo gói trả phí.

## 6.2. Bố cục đề xuất

```text
[Chào người dùng]

[Tiến độ hôm nay]
Calories đã dùng / mục tiêu
Protein / Carb / Fat cơ bản
Số bữa đã ghi

[Quick actions]
Tìm món | Ghi bữa ăn | Tra cứu calo | Cân nặng
Kế hoạch | Ăn ngoài? | Yêu thích     | Khác

[Bữa ăn hôm nay]
Sáng / Trưa / Tối / Ăn nhẹ

[Kế hoạch hiện tại]
Kế hoạch do người dùng tự tạo

[Tổng kết ngắn]
Số ngày có dữ liệu, xu hướng cân nặng

[Khám phá gói chuyên biệt]
Casual · Office · Gym/PT
```

## 6.3. Quick actions đề xuất

Bảy shortcut chính và nút `Khác`:

1. Tìm món
2. Ghi bữa ăn
3. Tra cứu calo
4. Cân nặng
5. Kế hoạch ăn
6. Ăn ngoài?
7. Yêu thích
8. Khác

Không đặt `Lucky Wheel`, `Daily Starter`, `Không gian Office` hoặc `GYMER VIP` trong grid Free.

## 6.4. Trạng thái không có dữ liệu

Khi người dùng chưa ghi bữa ăn:

```text
Bạn chưa ghi bữa ăn hôm nay
[Ghi bữa ăn đầu tiên]
```

Khi chưa có kế hoạch:

```text
Bạn chưa có kế hoạch ăn
[Tạo kế hoạch thủ công]
```

Không nên hiển thị màn hình trống hoặc yêu cầu nâng cấp ngay.

---

## 7. Tìm món ăn

### 7.1. Luồng cơ bản

```text
Người dùng mở Tìm món
→ nhập từ khóa hoặc chọn bộ lọc
→ backend trả danh sách món
→ người dùng xem chi tiết
→ có thể yêu thích, thêm vào nhật ký hoặc kế hoạch
```

### 7.2. Bộ lọc Free

- tên món;
- loại bữa;
- khoảng calorie;
- vùng miền;
- thời gian nấu;
- nguyên liệu chính;
- món chay;
- loại trừ dị ứng;
- giá ước tính nếu có dữ liệu.

### 7.3. Ranh giới với Casual

Free trả kết quả dựa trên lựa chọn do người dùng nhập.

Casual có thể:

- chủ động tạo danh sách gợi ý;
- tự chọn 10 món cho vòng quay;
- dựa trên lịch sử ăn;
- dùng calorie còn lại;
- tự áp dụng món vào ngày hiện tại.

Free không cần Lucky Wheel hoặc Daily Starter.

---

## 8. Xem chi tiết món

Màn chi tiết món Free nên hiển thị:

- tên món;
- ảnh;
- mô tả;
- khẩu phần;
- calorie;
- protein;
- carbohydrate;
- chất béo;
- chất xơ nếu có;
- nguyên liệu;
- hướng dẫn nấu;
- thời gian chuẩn bị và nấu;
- giá ước tính;
- cảnh báo dị ứng;
- nguồn hoặc mức độ ước tính của dữ liệu.

Hành động:

- thêm vào yêu thích;
- ghi vào bữa ăn;
- thêm vào kế hoạch;
- điều chỉnh khẩu phần;
- xem nguyên liệu thay thế cơ bản.

---

## 9. Ghi bữa ăn thủ công

### 9.1. Các cách ghi

Người dùng Free có thể:

1. tìm món trong hệ thống;
2. chọn món yêu thích;
3. chọn món đã ăn gần đây;
4. nhập món ăn ngoài;
5. tạo mục ghi thủ công.

### 9.2. Dữ liệu cần nhập

- loại bữa;
- món ăn;
- khẩu phần;
- ngày và giờ;
- ghi chú tùy chọn;
- calorie ước tính nếu là món ngoài.

### 9.3. Luồng

```text
Mở Ghi bữa ăn
→ chọn Sáng/Trưa/Tối/Ăn nhẹ
→ tìm hoặc nhập món
→ điều chỉnh khẩu phần
→ xem calorie dự kiến
→ xác nhận lưu
→ cập nhật Dashboard
```

### 9.4. Ranh giới với Casual

Free yêu cầu người dùng chủ động chọn bữa và món.

Casual có thể tự nhận diện khung giờ và cung cấp thao tác `Ghi nhận nhanh` một chạm.

---

## 10. Ghi bữa ăn ngoài

Tính năng `Ăn ngoài?` hỗ trợ trường hợp món không có công thức chính xác.

Người dùng nhập:

- tên món;
- loại món;
- khẩu phần;
- mô tả ngắn;
- calorie ước tính;
- ảnh tùy chọn.

Hệ thống có thể cung cấp khoảng calorie:

```text
Ước tính: 480–620 kcal
```

Cần nói rõ đây là dữ liệu ước tính, không phải kết quả tuyệt đối.

Người dùng có thể chỉnh lại sau khi lưu.

---

## 11. Tra cứu calorie và macro

Người dùng có thể tìm:

- món ăn;
- thực phẩm;
- nguyên liệu;
- khẩu phần.

Kết quả hiển thị:

- calorie theo khẩu phần;
- protein;
- carbohydrate;
- chất béo;
- chất xơ;
- đơn vị tham chiếu.

Không nên yêu cầu mua gói mới được xem dữ liệu dinh dưỡng cơ bản.

---

## 12. Quét và tính calorie cơ bản

Nếu MenuGreen duy trì tính năng scan trong Free, phạm vi nên giới hạn rõ.

### 12.1. Free được phép

- chụp hoặc tải ảnh;
- nhận diện nguyên liệu hoặc món ở mức cơ bản;
- xem kết quả ước tính;
- chỉnh khẩu phần;
- lưu vào nhật ký.

### 12.2. Không thuộc Free

Các thao tác chuyên biệt:

- thêm trực tiếp vào kế hoạch cơm hộp Office;
- tính lại ngân sách Office;
- chia nguyên liệu vào lượt đi chợ;
- đánh giá protein theo ngày tập/ngày nghỉ;
- gửi cho Coach;
- đưa vào Premium Program.

### 12.3. Khi AI lỗi

Người dùng vẫn phải có đường lui:

```text
Không thể nhận diện ảnh
[Thử lại] [Nhập món thủ công]
```

Không để AI trở thành điểm nghẽn của luồng Free.

---

## 13. Theo dõi calorie và dashboard cơ bản

Dashboard Free hiển thị:

- calorie đã ghi trong ngày;
- calorie mục tiêu;
- calorie còn lại;
- protein, carbohydrate và chất béo;
- số bữa đã ghi;
- cân nặng gần nhất;
- xu hướng ngắn hạn nếu đủ dữ liệu.

Ví dụ:

```text
Đã dùng: 1.250 / 2.000 kcal
Còn lại: 750 kcal
Protein: 68 / 100 g
```

Dashboard chỉ phản ánh dữ liệu đã ghi. Không nên giả định người dùng đã ăn món chưa được xác nhận.

---

## 14. Theo dõi cân nặng

Người dùng Free có thể:

- ghi cân nặng;
- chọn ngày ghi;
- thêm ghi chú;
- xem lịch sử;
- xem biểu đồ xu hướng;
- xem cân nặng mục tiêu.

Luồng nhanh:

```text
Home
→ Cân nặng
→ mở WeightLogSheet
→ nhập cân nặng
→ lưu
→ cập nhật Dashboard
```

Không khóa lịch sử cân nặng sau khi gói trả phí hết hạn.

---

## 15. Kế hoạch ăn thủ công

## 15.1. Phạm vi Free

Người dùng có thể:

- tạo kế hoạch cho một hoặc nhiều ngày;
- tự thêm món vào sáng, trưa, tối hoặc ăn nhẹ;
- chỉnh ngày;
- đổi món thủ công;
- xem tổng calorie dự kiến;
- lưu thành mẫu;
- đánh dấu món đã ăn;
- sao chép kế hoạch đơn giản.

## 15.2. Luồng

```text
Tạo kế hoạch
→ chọn ngày hoặc khoảng ngày
→ thêm món cho từng bữa
→ xem tổng calorie
→ lưu kế hoạch
```

## 15.3. Không thuộc Free

Free không tự động:

- tạo 21 bữa theo ngân sách;
- tối ưu theo lịch làm việc;
- chia danh sách đi chợ theo lượt;
- tạo calorie ngày tập/ngày nghỉ;
- mở khóa milestone chương trình;
- tạo kế hoạch một chạm từ Daily Starter.

---

## 16. Kế hoạch so với thực tế

Free có thể xem so sánh cơ bản:

| Nội dung | Kế hoạch | Thực tế |
|---|---:|---:|
| Calories | 1.900 kcal | 2.050 kcal |
| Số bữa | 3 | 4 |
| Bữa hoàn thành | 3 | 2 |

Phạm vi Free:

- tổng calorie;
- số bữa;
- món đã thực hiện;
- món bị bỏ qua;
- chênh lệch cơ bản.

Phân tích tự động sâu hoặc đề xuất thay đổi hành vi có thể thuộc Casual, Office hoặc Gym/PT tùy ngữ cảnh.

---

## 17. Yêu thích và món gần đây

Người dùng có thể:

- thêm hoặc bỏ yêu thích;
- xem danh sách món yêu thích;
- lọc theo loại bữa;
- thêm món yêu thích vào nhật ký;
- thêm món vào kế hoạch;
- xem các món đã dùng gần đây.

Đây là cách giúp người dùng Free thao tác nhanh hơn mà không trùng với tự động hóa một chạm của Casual.

---

## 18. Thực đơn và mẫu bữa ăn đã lưu

Người dùng Free có thể:

- tạo mẫu;
- sửa;
- xóa;
- duplicate;
- lưu một tổ hợp món;
- ghi nhanh mẫu vào nhật ký sau khi xác nhận.

Mẫu Free là dữ liệu do người dùng tự tạo.

Khác với Office:

- không tự tạo kế hoạch 7 ngày;
- không có ngân sách tuần;
- không có shopping trips;
- không có logic ưu tiên cơm hộp.

Khác với Casual:

- không tự chọn mẫu dựa trên ngữ cảnh;
- không áp dụng Daily Starter một chạm nếu chưa có xác nhận.

---

## 19. Sở thích vùng miền và khẩu vị

Người dùng có thể quản lý:

- vùng miền;
- khẩu vị;
- món chay;
- món không thích;
- nguyên liệu không muốn dùng;
- mức cay;
- thời gian nấu mong muốn.

Dữ liệu này được dùng cho:

- bộ lọc tìm món;
- sắp xếp kết quả;
- cảnh báo hoặc loại trừ món;
- cá nhân hóa cơ bản.

Không dùng dữ liệu này để tự cấp entitlement.

---

## 20. Dị ứng và an toàn

Dị ứng là dữ liệu quan trọng và phải được áp dụng cho toàn bộ hệ thống.

Backend cần:

- lọc món có nguyên liệu dị ứng;
- cảnh báo khi dữ liệu nguyên liệu chưa đầy đủ;
- không tự động đưa món nguy hiểm vào kế hoạch;
- kiểm tra lại khi đổi món;
- kiểm tra kết quả scan nếu có thể;
- cho người dùng cập nhật dị ứng bất kỳ lúc nào.

Không được bỏ qua dị ứng chỉ vì người dùng đang dùng Free.

---

## 21. Thay thế nguyên liệu cơ bản

Free có thể:

- xem danh sách nguyên liệu thay thế đã được cấu hình;
- chọn một nguyên liệu thay thế;
- xem ảnh hưởng dinh dưỡng cơ bản;
- lưu sở thích thay thế.

Phiên bản nâng cao có thể thuộc gói khác:

- tự tối ưu theo ngân sách;
- tự tối ưu theo dị ứng và macro;
- tự sửa toàn bộ kế hoạch;
- tự cập nhật grocery list;
- phân tích ảnh hưởng đến chương trình Gym.

---

## 22. Góc dinh dưỡng Free

Free nên có thư viện kiến thức chung:

- calorie là gì;
- macro là gì;
- protein;
- carbohydrate;
- chất béo;
- chất xơ;
- khẩu phần;
- đọc nhãn dinh dưỡng;
- an toàn thực phẩm.

Người dùng tự chọn nội dung muốn đọc.

Không thuộc Free:

- thẻ kiến thức cá nhân hóa từ lịch sử;
- quiz theo hành vi;
- streak học tập;
- điểm thưởng;
- nhiệm vụ hằng ngày.

Các phần đó thuộc Casual.

---

## 23. Consent và quyền dữ liệu

Người dùng Free có quyền:

- xem consent đã chấp nhận;
- thay đổi lựa chọn consent nếu nghiệp vụ cho phép;
- yêu cầu xuất dữ liệu;
- yêu cầu xóa tài khoản;
- xem chính sách dữ liệu;
- thu hồi quyền Coach hoặc liên kết khác nếu tồn tại;
- báo cáo sự cố.

Đây là quyền nền tảng, không phải tính năng trả phí.

---

## 24. Upsell gói trả phí

## 24.1. Nguyên tắc

Không hiển thị hàng loạt icon khóa trong grid Free.

Upsell nên:

- nằm ở khu vực riêng;
- giải thích lợi ích cụ thể;
- xuất hiện theo ngữ cảnh;
- không chặn thao tác Free;
- không làm mất dữ liệu đã nhập.

## 24.2. Card Casual

```text
Muốn chọn món nhanh hơn?

Casual hỗ trợ Vòng quay món ăn,
Daily Starter và ghi nhận một chạm.

[Tìm hiểu gói Casual]
```

## 24.3. Card Office

```text
Bạn thường chuẩn bị cơm đi làm?

Office hỗ trợ kế hoạch 7 ngày,
ngân sách và danh sách đi chợ.

[Tìm hiểu gói Office]
```

## 24.4. Card Gym/PT

```text
Bạn đang theo mục tiêu hình thể?

Gym/PT hỗ trợ calorie ngày tập,
PT Review, Coach và lộ trình dài hạn.

[Tìm hiểu gói Gym/PT]
```

---

## 25. Nguồn dữ liệu quyền truy cập

Frontend nên lấy quyền từ endpoint tổng hợp:

```http
GET /api/UserSubscription/me/entitlements
```

Response Free:

```json
{
  "tier": "free",
  "entitlements": ["free_features"],
  "featureGroups": ["free"],
  "expiresAt": null
}
```

Model Flutter:

```dart
class FeatureAccess {
  const FeatureAccess({
    required this.hasCasual,
    required this.hasOffice,
    required this.hasGym,
  });

  final bool hasCasual;
  final bool hasOffice;
  final bool hasGym;

  static const free = FeatureAccess(
    hasCasual: false,
    hasOffice: false,
    hasGym: false,
  );
}
```

Khi API quyền lỗi:

```text
fallback về FeatureAccess.free
```

Không tự mở quyền trả phí.

---

## 26. Authorization backend

### 26.1. API Free

API Free yêu cầu:

```csharp
[Authorize(Policy = "UserOnly")]
```

Hoặc policy tương đương yêu cầu tài khoản hợp lệ.

### 26.2. API trả phí

- Casual: `casual_features`
- Office: `office_features`
- Gym/PT: `gym_features`
- Coach: `coach_access`

Thiếu quyền:

```http
403 Forbidden
```

Không có JWT:

```http
401 Unauthorized
```

Không trả `404` hoặc `200` với dữ liệu rỗng để che giấu thiếu quyền trong các luồng thông thường.

---

## 27. Trạng thái khi gói trả phí hết hạn

Khi subscription hết hạn:

- người dùng quay về quyền Free;
- dữ liệu Free vẫn còn;
- lịch sử do người dùng tạo không bị xóa;
- dữ liệu gói trả phí có thể xem ở chế độ chỉ đọc nếu nghiệp vụ cho phép;
- thao tác tạo mới hoặc chuyên biệt trả `403`;
- frontend refresh entitlement;
- hiển thị thông báo rõ ràng.

Ví dụ:

```text
Gói Office đã hết hạn

Bạn vẫn có thể xem dữ liệu trước đây.
Gia hạn để tiếp tục tạo kế hoạch Office mới.
```

---

## 28. Xử lý lỗi và fallback

### 28.1. Lỗi tải entitlement

- render Home Free;
- không hiện panel trả phí;
- cho phép retry;
- không đăng xuất người dùng.

### 28.2. Backend trả 403

- refresh entitlement;
- đóng màn hình trả phí nếu cần;
- đưa người dùng về trạng thái an toàn;
- hiển thị thông báo có thể hiểu được.

### 28.3. AI worker lỗi

- cho phép nhập thủ công;
- không làm mất ảnh hoặc dữ liệu đã nhập;
- cho phép thử lại.

### 28.4. Dữ liệu dinh dưỡng thiếu

- đánh dấu là ước tính;
- không hiển thị số liệu giả;
- cho phép người dùng chỉnh sửa nếu có quyền.

---

## 29. Khả năng truy cập và UI

- vùng bấm tối thiểu 48 × 48 logical pixels;
- hỗ trợ text scale lớn;
- nhãn tối đa hai dòng;
- không chỉ dùng màu để biểu thị trạng thái;
- có `Semantics` hoặc tooltip;
- thứ tự shortcut ổn định;
- bottom sheet có thể cuộn;
- màn hình hẹp không bị overflow;
- loading và empty state rõ ràng.

---

## 30. Kiểm thử đề xuất

### 30.1. Unit test backend

- tài khoản hợp lệ luôn có `free_features`;
- Free không có `casual_features`, `office_features`, `gym_features`;
- subscription hết hạn không cấp entitlement trả phí;
- nhiều subscription active được hợp quyền;
- dị ứng được áp dụng khi tìm và chọn món;
- calorie dashboard tính từ meal log thực tế;
- kế hoạch chưa đánh dấu ăn không tự tạo meal log.

### 30.2. Integration test

- không JWT gọi API Free nhận `401`;
- Free gọi API Free nhận `200`;
- Free gọi Casual/Office/Gym nhận `403`;
- Free tạo meal log thành công;
- Free tạo kế hoạch thủ công thành công;
- Free ghi cân nặng thành công;
- endpoint entitlement trả đúng `free_features`;
- AI lỗi vẫn có thể dùng luồng nhập thủ công.

### 30.3. Widget test Flutter

- Free thấy đúng shortcut Free;
- không thấy Lucky Wheel, Office panel hoặc GYMER VIP;
- `Cân nặng` mở `WeightLogSheet`;
- `Khác` mở danh sách đầy đủ;
- lỗi entitlement fallback về Free;
- Home không overflow ở màn hình 360 px;
- nhãn tiếng Việt hiển thị đúng;
- upsell nằm riêng, không trộn vào grid Free.

---

## 31. Tiêu chí hoàn thành

- Người dùng Free hoàn thành được vòng lặp ghi nhận và theo dõi dinh dưỡng.
- Không có tính năng Casual, Office hoặc Gym/PT bị mở chỉ vì mode giao diện.
- Free không bị biến thành bản demo chỉ có chức năng xem.
- Lucky Wheel, Daily Starter và game hóa không trùng vào Free.
- Kế hoạch Free là kế hoạch thủ công, không tự động hóa như Office hoặc Casual.
- Dữ liệu dị ứng được áp dụng nhất quán.
- Backend là nguồn sự thật về quyền.
- Lỗi API entitlement luôn fallback an toàn.
- Dữ liệu cá nhân không bị mất khi subscription hết hạn.
- Có unit test, integration test và widget test cho phạm vi Free.

---

## 32. Ma trận phân biệt cuối cùng

| Nhu cầu | Free | Casual | Office | Gym/PT |
|---|---|---|---|---|
| Tìm món | Tự tìm và lọc | Chủ động gợi ý | Theo ngữ cảnh cơm hộp | Theo mục tiêu tập |
| Ghi bữa ăn | Thủ công | Một chạm | Đồng bộ với kế hoạch Office | Đồng bộ với mục tiêu Gym |
| Kế hoạch ăn | Tự tạo | Áp dụng mẫu nhanh | 7 ngày, ngân sách | Ngày tập/nghỉ, chương trình |
| Quét calorie | Cơ bản | Có thể dùng cho ghi nhanh | Thêm vào cơm hộp | Đánh giá protein và Coach |
| Cân nặng | Theo dõi cơ bản | Có thể dùng cho động lực | Không phải giá trị chính | Check-in và hiệu chỉnh |
| Kiến thức | Thư viện chung | Cá nhân hóa + Quiz | Nội dung công sở nếu bật | Kiến thức theo luyện tập |
| Gamification | Tiến độ cơ bản | Streak, điểm, nhiệm vụ | Không phải giá trị chính | Milestone, huy hiệu, chứng nhận |
| Ngân sách | Không | Không | Có | Không |
| PT/Coach | Không | Không | Không | Có |

---

## 33. Kết luận

Nhóm Free của MenuGreen nên mang lại cảm giác:

> “Tôi có đầy đủ công cụ để tự quản lý ăn uống, theo dõi calorie và cân nặng mà không cần mua gói.”

Sự khác biệt với Casual không nằm ở việc Free không thể sử dụng ứng dụng, mà nằm ở mức độ chủ động:

```text
Free: Tôi tự tìm, tự chọn, tự ghi và tự lập kế hoạch.
Casual: Ứng dụng giúp tôi chọn nhanh, tự động hóa và tạo động lực.
```

Sự khác biệt với Office và Gym/PT nằm ở quy trình chuyên biệt:

```text
Office: tổ chức ăn uống theo tuần làm việc và ngân sách.
Gym/PT: quản lý dinh dưỡng theo mục tiêu hình thể, PT và chương trình.
```

Thiết kế theo ranh giới này giúp Free đủ tốt để giữ người dùng, đồng thời các gói trả phí vẫn có giá trị rõ ràng và không bị trùng chức năng.
