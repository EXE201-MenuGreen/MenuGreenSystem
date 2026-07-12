-- Seed default portion units (25 Vietnam traditional units)
INSERT INTO default_portion_units ("Id", "UnitName", "GramsEquivalent", "Description", "IsActive", "CreatedAt")
VALUES
    ('d0000001-0000-0000-0000-000000000001', 'chén', 150.00, 'Chén cơm, chén chấm gia vị thông thường (khoảng 150g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000002', 'bát', 200.00, 'Bát ăn canh hoặc bát cơm nhỡ (khoảng 200g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000003', 'tô', 500.00, 'Tô lớn đựng phở, bún, hủ tiếu (khoảng 500g-650g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000004', 'tô xe lửa', 800.00, 'Tô phở/bún siêu to khổng lồ', true, NOW()),
    ('d0000001-0000-0000-0000-000000000005', 'đĩa', 250.00, 'Đĩa thức ăn, đĩa rau luộc trung bình (khoảng 200g-250g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000006', 'đĩa lớn', 400.00, 'Đĩa thức ăn lớn dùng cho gia đình', true, NOW()),
    ('d0000001-0000-0000-0000-000000000007', 'muỗng', 5.00, 'Muỗng cà phê dầu ăn, gia vị nhỏ (khoảng 5g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000008', 'muỗng canh', 15.00, 'Muỗng canh lớn ăn cơm, muỗng ăn lẩu (khoảng 15g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000009', 'ly', 250.00, 'Ly uống nước lọc, nước ngọt tiêu chuẩn (khoảng 250ml)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000010', 'cốc', 240.00, 'Cốc uống trà đá, sữa đậu nành nhỡ (khoảng 240ml)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000011', 'trái', 100.00, 'Trái cây nhỡ như táo, cam, chuối quả (khoảng 80g-150g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000012', 'quả', 100.00, 'Trái quả nhỡ tiêu chuẩn (khoảng 100g)', true, NOW()),
    ('d0000001-0000-0000-0000-000000000013', 'hộp', 350.00, 'Hộp cơm văn phòng, hộp xôi hộp nhựa', true, NOW()),
    ('d0000001-0000-0000-0000-000000000014', 'gói', 80.00, 'Gói mì tôm ăn liền, bánh quy nhỏ', true, NOW()),
    ('d0000001-0000-0000-0000-000000000015', 'lon', 330.00, 'Lon nước ngọt, lon bia tiêu chuẩn', true, NOW()),
    ('d0000001-0000-0000-0000-000000000016', 'ổ', 120.00, 'Ổ bánh mì thịt, bánh mì ổ nhỡ Việt Nam', true, NOW()),
    ('d0000001-0000-0000-0000-000000000017', 'cuốn', 50.00, 'Cuốn gỏi cuốn, nem cuốn tiêu chuẩn', true, NOW()),
    ('d0000001-0000-0000-0000-000000000018', 'xiên', 60.00, 'Xiên thịt nướng, xiên cá viên chiên', true, NOW()),
    ('d0000001-0000-0000-0000-000000000019', 'củ', 120.00, 'Củ khoai lang, khoai tây, cà rốt nhỡ', true, NOW()),
    ('d0000001-0000-0000-0000-000000000020', 'lát', 30.00, 'Lát bánh mì sandwich, lát giò chả mỏng', true, NOW()),
    ('d0000001-0000-0000-0000-000000000021', 'nhúm', 10.00, 'Một nhúm nhỏ gia vị, rau thơm khoảng 10g', true, NOW()),
    ('d0000001-0000-0000-0000-000000000022', 'bánh', 150.00, 'Bánh chưng bánh tét nhỏ hoặc bánh trung thu', true, NOW()),
    ('d0000001-0000-0000-0000-000000000023', 'que', 50.00, 'Que kem, que kẹo hoặc xiên chả nhỏ', true, NOW()),
    ('d0000001-0000-0000-0000-000000000024', 'cái', 100.00, 'Đơn vị cái cho bánh bao, bánh giò, bánh chưng nhỏ', true, NOW()),
    ('d0000001-0000-0000-0000-000000000025', 'khoanh', 50.00, 'Khoanh giò, khoanh bánh tét, cá cắt khoanh', true, NOW())
ON CONFLICT ("UnitName") 
DO UPDATE SET 
    "GramsEquivalent" = EXCLUDED."GramsEquivalent",
    "Description" = EXCLUDED."Description",
    "IsActive" = EXCLUDED."IsActive";
