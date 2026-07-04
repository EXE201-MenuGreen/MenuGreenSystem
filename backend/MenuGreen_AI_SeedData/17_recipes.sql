-- =============================================================================
-- MenuGreen Seed Data - Table: recipes
-- Sequence Number: 17
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS recipes CASCADE;

CREATE TABLE recipes (
    "Id" uuid NOT NULL,
    "FoodId" uuid NULL,
    "Title" text NOT NULL,
    "Description" text NULL,
    "PrepTimeMin" integer NULL,
    "CookTimeMin" integer NULL,
    "TotalTimeMin" integer NULL,
    "Servings" integer NULL,
    "Difficulty" text NULL,
    "MealType" text NULL,
    "EstimatedPriceVnd" integer NULL,
    "Instructions" json NULL,
    "ImageUrl" text NULL,
    "VideoUrl" text NULL,
    "IsActive" boolean NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_recipes" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_recipes_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE
);

INSERT INTO recipes ("Id", "FoodId", "Title", "Description", "PrepTimeMin", "CookTimeMin", "TotalTimeMin", "Servings", "Difficulty", "MealType", "EstimatedPriceVnd", "Instructions", "ImageUrl", "VideoUrl", "IsActive", "CreatedAt")
VALUES
('ec000001-0000-0000-0000-000000000001', 'fd000001-0000-0000-0000-000000000001', 'Ức gà áp chảo sốt chanh', 'Cách làm ức gà mềm mọng không bị khô sốt chanh leo thơm ngon', 10, 15, 25, 1, 'Easy', 'Lunch', 35000, '["Bước 1: Rửa sạch ức gà, khía nhẹ bề mặt.", "Bước 2: Ướp với chút muối, tiêu và tỏi băm trong 10 phút.", "Bước 3: Cho 5ml dầu olive vào chảo, áp chảo mỗi mặt 5-6 phút đến khi chín vàng.", "Bước 4: Rưới nước cốt chanh leo pha mật ong lên trên và thưởng thức."]', 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400', NULL, true, now()),
('ec000002-0000-0000-0000-000000000002', 'fd000003-0000-0000-0000-000000000003', 'Salad bơ ức gà giảm cân', 'Salad dầu giấm ức gà kết hợp bơ quả thơm béo', 10, 10, 20, 1, 'Easy', 'Dinner', 55000, '["Bước 1: Luộc chín ức gà và xé nhỏ.", "Bước 2: Cắt hạt lựu bơ quả và cà chua, xà lách rửa sạch cắt khúc.", "Bước 3: Trộn nước sốt gồm dầu olive, nước cốt chanh, muối và chút tiêu.", "Bước 4: Trộn đều rau quả với gà xé và rưới nước sốt."]', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', NULL, true, now()),
('ec000003-0000-0000-0000-000000000003', 'fd000007-0000-0000-0000-000000000007', 'Cá hồi áp chảo sốt măng tây', 'Cá hồi áp chảo béo ngậy kèm măng tây giòn ngọt', 15, 10, 25, 1, 'Medium', 'Dinner', 120000, '["Bước 1: Thấm khô miếng cá hồi, ướp muối tiêu hai mặt.", "Bước 2: Làm nóng chảo, cho chút bơ hoặc dầu olive vào, áp chảo cá hồi mỗi bên 3 phút.", "Bước 3: Xào măng tây và tỏi băm trên chảo nóng.", "Bước 4: Bày cá ra đĩa kèm măng tây, rưới chanh tươi."]', 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', NULL, true, now()),
('ec000004-0000-0000-0000-000000000004', 'fd000008-0000-0000-0000-000000000008', 'Cháo yến mạch trứng gà ăn sáng', 'Cháo yến mạch ấm nóng cung cấp năng lượng nhanh cho buổi sáng', 5, 10, 15, 1, 'Easy', 'Breakfast', 15000, '["Bước 1: Ngâm yến mạch với nước ấm khoảng 5 phút.", "Bước 2: Cho yến mạch vào nồi nhỏ đun sôi, khuấy đều tay.", "Bước 3: Đập 1 quả trứng gà vào nồi cháo, khuấy nhanh tay để trứng tan.", "Bước 4: Nêm chút nước mắm hoặc hạt nêm gia vị, đun thêm 2 phút rồi tắt bếp."]', 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=400', NULL, true, now()),
('ec000005-0000-0000-0000-000000000005', 'fd000005-0000-0000-0000-000000000005', 'Sinh tố chuối bơ đậu phộng', 'Sinh tố thơm béo, nhiều năng lượng từ chuối, bơ và bơ đậu phộng', 5, 5, 10, 1, 'Easy', 'Snack', 30000, '["Bước 1: Chuẩn bị 1 quả chuối chín bóc vỏ, cắt khoanh.", "Bước 2: Chuẩn bị 50g bơ sáp chín.", "Bước 3: Cho chuối, bơ, 1 muỗng canh bơ đậu phộng, 150ml sữa tươi vào máy xay sinh tố.", "Bước 4: Xay mịn trong 30 giây rồi cho ra ly và thưởng thức."]', 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400', NULL, true, now()),
('ec000006-0000-0000-0000-000000000006', 'fd000006-0000-0000-0000-000000000006', 'Bò áp chảo bông cải xanh', 'Thịt bò thăn mềm mọng ăn kèm bông cải xanh xào tỏi', 10, 10, 20, 1, 'Easy', 'Lunch', 95000, '["Bước 1: Thịt bò thái miếng vừa ăn, ướp tỏi băm, muối, tiêu dầu hào trong 10 phút.", "Bước 2: Bông cải xanh rửa sạch, cắt miếng nhỏ, chần sơ qua nước sôi.", "Bước 3: Cho chút dầu ăn vào chảo, xào chín bông cải xanh với tỏi, trút ra đĩa.", "Bước 4: Dùng chảo đó, làm nóng dầu và áp chảo thịt bò nhanh tay với lửa lớn đến khi chín tái, trút ra đĩa bông cải xanh."]', 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', NULL, true, now()),
('ec000007-0000-0000-0000-000000000007', 'fd000010-0000-0000-0000-000000000010', 'Salad cá hồi bơ', 'Salad rau xanh trộn bơ sáp thơm ngậy và cá hồi nướng áp chảo', 10, 15, 25, 1, 'Easy', 'Dinner', 85000, '["Bước 1: Cá hồi áp chảo chín vàng hai mặt rồi xé miếng vừa ăn.", "Bước 2: Cắt nhỏ xà lách, cà chua bi, bơ sáp cắt hạt lựu.", "Bước 3: Pha sốt dầu giấm gồm giấm táo, dầu olive, chút đường, muối.", "Bước 4: Trộn đều rau củ quả với nước sốt, bày cá hồi lên trên và thưởng thức."]', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', NULL, true, now()),
('ec000008-0000-0000-0000-000000000008', 'fd000002-0000-0000-0000-000000000002', 'Cơm gạo lứt', 'Cơm gạo lứt bổ dưỡng dẻo thơm hấp cùng hạt sen bùi béo', 15, 45, 60, 2, 'Medium', 'Lunch', 20000, '["Bước 1: Vo sạch gạo lứt, ngâm trong nước ấm khoảng 2 tiếng trước khi nấu.", "Bước 2: Hạt sen tươi rửa sạch, thông tâm sen.", "Bước 3: Trộn gạo lứt với hạt sen, cho nước vào nồi cơm điện theo tỷ lệ 1 gạo : 1.5 nước.", "Bước 4: Nhấn nút nấu cơm, khi cơm chín ủ hơi thêm 15 phút cho hạt sen bùi dẻo."]', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400', NULL, true, now()),
('ec000009-0000-0000-0000-000000000009', 'fd000004-0000-0000-0000-000000000004', 'Khoai lang hấp', 'Khoai lang vàng hấp nước dừa ngọt thơm dịu', 5, 20, 25, 1, 'Easy', 'Snack', 10000, '["Bước 1: Rửa sạch khoai lang, cắt khúc hoặc để nguyên củ tùy ý.", "Bước 2: Xếp khoai lang vào xửng hấp.", "Bước 3: Đổ nước dừa tươi vào nồi hấp bên dưới xửng.", "Bước 4: Đậy nắp đun sôi hấp trong vòng 20 phút đến khi khoai mềm thơm mùi dừa."]', 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=400', NULL, true, now()),
('ec000010-0000-0000-0000-000000000010', 'fd000009-0000-0000-0000-000000000009', 'Đậu hũ sốt cà chua', 'Đậu hũ chiên vàng giòn sốt cùng cà chua đậm đà và hành lá', 5, 15, 20, 1, 'Easy', 'Lunch', 15000, '["Bước 1: Đậu hũ cắt miếng vuông nhỏ, rán vàng giòn các mặt.", "Bước 2: Cà chua rửa sạch thái múi cau, hành lá cắt khúc.", "Bước 3: Phi thơm hành khô băm nhỏ, cho cà chua vào xào nhuyễn thành nước sốt.", "Bước 4: Cho đậu hũ rán vào sốt cà chua, nêm mắm muối vừa ăn, rim nhỏ lửa 5 phút rồi cho hành lá vào."]', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', NULL, true, now())
ON CONFLICT ("Id") DO NOTHING;

COMMIT;