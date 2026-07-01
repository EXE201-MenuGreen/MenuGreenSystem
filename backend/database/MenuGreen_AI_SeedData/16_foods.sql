-- =============================================================================
-- MenuGreen Seed Data - Table: foods
-- Sequence Number: 16
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS foods CASCADE;

CREATE TABLE foods (
    "Id" uuid NOT NULL,
    "NameVi" text NOT NULL,
    "NameEn" text NULL,
    "Category" text NULL,
    "Description" text NULL,
    "CaloriesKcal" numeric NULL,
    "ProteinG" numeric NULL,
    "CarbsG" numeric NULL,
    "FatG" numeric NULL,
    "FiberG" numeric NULL,
    "EstimatedPriceVnd" integer NULL,
    "DefaultServingG" integer NULL,
    "ImageUrl" text NULL,
    "IsActive" boolean NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_foods" PRIMARY KEY ("Id")
);

INSERT INTO foods ("Id", "NameVi", "NameEn", "Category", "Description", "CaloriesKcal", "ProteinG", "CarbsG", "FatG", "FiberG", "EstimatedPriceVnd", "DefaultServingG", "ImageUrl", "IsActive", "CreatedAt")
VALUES
('fd000001-0000-0000-0000-000000000001', 'Ức gà áp chảo', 'Pan-seared chicken breast', 'Món mặn', 'Món ăn giàu protein, ít chất béo cho người giảm cân', 165, 31.0, 0.0, 3.6, 0.0, 35000, 150, 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400', true, now()),
('fd000002-0000-0000-0000-000000000002', 'Cơm gạo lứt', 'Cooked brown rice', 'Tinh bột', 'Cơm nấu từ gạo lứt dẻo thơm, giàu chất xơ', 111, 2.6, 23.0, 0.9, 1.8, 10000, 100, 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400', true, now()),
('fd000003-0000-0000-0000-000000000003', 'Salad bơ ức gà', 'Avocado chicken salad', 'Salad', 'Salad tươi mát kèm ức gà xé và bơ sáp thơm ngậy', 320, 28.5, 12.0, 18.5, 5.2, 55000, 250, 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', true, now()),
('fd000004-0000-0000-0000-000000000004', 'Khoai lang hấp', 'Steamed sweet potato', 'Tinh bột', 'Khoai lang ngọt dịu, tinh bột hấp thụ chậm hoàn hảo', 86, 1.6, 20.1, 0.1, 3.0, 8000, 100, 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=400', true, now()),
('fd000005-0000-0000-0000-000000000005', 'Sinh tố chuối bơ đậu phộng', 'Peanut butter banana smoothie', 'Thức uống', 'Sinh tố tăng cân, cung cấp nhiều năng lượng và chất béo tốt', 450, 12.0, 52.0, 22.0, 4.5, 30000, 350, 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400', true, now()),
('fd000006-0000-0000-0000-000000000006', 'Bò áp chảo bông cải xanh', 'Beef steak with broccoli', 'Món mặn', 'Thịt bò thăn giàu sắt kết hợp bông cải xanh giòn ngon', 290, 32.0, 6.6, 14.5, 2.5, 95000, 200, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', true, now()),
('fd000007-0000-0000-0000-000000000007', 'Cá hồi áp chảo sốt chanh', 'Pan-seared salmon with lemon sauce', 'Món mặn', 'Cá hồi béo ngậy sốt chanh leo chua ngọt nhẹ', 350, 25.0, 5.0, 24.0, 0.5, 120000, 150, 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', true, now()),
('fd000008-0000-0000-0000-000000000008', 'Cháo yến mạch trứng gà', 'Oatmeal porridge with egg', 'Món nước', 'Món ăn sáng nhẹ bụng, dễ tiêu hóa và chế biến nhanh', 250, 11.5, 28.0, 8.5, 3.5, 15000, 250, 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=400', true, now()),
('fd000009-0000-0000-0000-000000000009', 'Đậu hũ sốt cà chua', 'Tofu in tomato sauce', 'Chay', 'Đậu hũ thanh đạm sốt cà chua tươi đậm đà', 180, 12.0, 8.5, 10.0, 2.0, 15000, 200, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', true, now()),
('fd000010-0000-0000-0000-000000000010', 'Salad cá hồi bơ', 'Salmon avocado salad', 'Salad', 'Salad hỗn hợp với bơ sáp và cá hồi phi lê nướng', 380, 23.0, 9.5, 28.0, 4.0, 85000, 250, 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', true, now())
ON CONFLICT DO NOTHING;

COMMIT;