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
('ec000004-0000-0000-0000-000000000004', 'fd000008-0000-0000-0000-000000000008', 'Cháo yến mạch trứng gà ăn sáng', 'Cháo yến mạch ấm nóng cung cấp năng lượng nhanh cho buổi sáng', 5, 10, 15, 1, 'Easy', 'Breakfast', 15000, '["Bước 1: Ngâm yến mạch với nước ấm khoảng 5 phút.", "Bước 2: Cho yến mạch vào nồi nhỏ đun sôi, khuấy đều tay.", "Bước 3: Đập 1 quả trứng gà vào nồi cháo, khuấy nhanh tay để trứng tan.", "Bước 4: Nêm chút nước mắm hoặc hạt nêm gia vị, đun thêm 2 phút rồi tắt bếp."]', 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=400', NULL, true, now())
ON CONFLICT DO NOTHING;

COMMIT;