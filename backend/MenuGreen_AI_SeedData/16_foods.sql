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
    "Region" text NULL,
    CONSTRAINT "PK_foods" PRIMARY KEY ("Id")
);

INSERT INTO foods ("Id", "NameVi", "NameEn", "Category", "Description", "CaloriesKcal", "ProteinG", "CarbsG", "FatG", "FiberG", "EstimatedPriceVnd", "DefaultServingG", "ImageUrl", "IsActive", "CreatedAt", "Region")
VALUES
('fd000001-0000-0000-0000-000000000001', 'Ức gà áp chảo', 'Pan-seared chicken breast', 'Món mặn', 'Món ăn giàu protein, ít chất béo cho người giảm cân', 165, 31.0, 0.0, 3.6, 0.0, 35000, 150, 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400', true, now(), null),
('fd000002-0000-0000-0000-000000000002', 'Cơm gạo lứt', 'Cooked brown rice', 'Tinh bột', 'Cơm nấu từ gạo lứt dẻo thơm, giàu chất xơ', 111, 2.6, 23.0, 0.9, 1.8, 10000, 100, 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400', true, now(), null),
('fd000003-0000-0000-0000-000000000003', 'Salad bơ ức gà', 'Avocado chicken salad', 'Salad', 'Salad tươi mát kèm ức gà xé và bơ sáp thơm ngậy', 320, 28.5, 12.0, 18.5, 5.2, 55000, 250, 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', true, now(), null),
('fd000004-0000-0000-0000-000000000004', 'Khoai lang hấp', 'Steamed sweet potato', 'Tinh bột', 'Khoai lang ngọt dịu, tinh bột hấp thụ chậm hoàn hảo', 86, 1.6, 20.1, 0.1, 3.0, 8000, 100, 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=400', true, now(), null),
('fd000005-0000-0000-0000-000000000005', 'Sinh tố chuối bơ đậu phộng', 'Peanut butter banana smoothie', 'Thức uống', 'Sinh tố tăng cân, cung cấp nhiều năng lượng và chất béo tốt', 450, 12.0, 52.0, 22.0, 4.5, 30000, 350, 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400', true, now(), null),
('fd000006-0000-0000-0000-000000000006', 'Bò áp chảo bông cải xanh', 'Beef steak with broccoli', 'Món mặn', 'Thịt bò thăn giàu sắt kết hợp bông cải xanh giòn ngon', 290, 32.0, 6.6, 14.5, 2.5, 95000, 200, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', true, now(), null),
('fd000007-0000-0000-0000-000000000007', 'Cá hồi áp chảo sốt chanh', 'Pan-seared salmon with lemon sauce', 'Món mặn', 'Cá hồi béo ngậy sốt chanh leo chua ngọt nhẹ', 350, 25.0, 5.0, 24.0, 0.5, 120000, 150, 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', true, now(), null),
('fd000008-0000-0000-0000-000000000008', 'Cháo yến mạch trứng gà', 'Oatmeal porridge with egg', 'Món nước', 'Món ăn sáng nhẹ bụng, dễ tiêu hóa và chế biến nhanh', 250, 11.5, 28.0, 8.5, 3.5, 15000, 250, 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=400', true, now(), null),
('fd000009-0000-0000-0000-000000000009', 'Đậu hũ sốt cà chua', 'Tofu in tomato sauce', 'Chay', 'Đậu hũ thanh đạm sốt cà chua tươi đậm đà', 180, 12.0, 8.5, 10.0, 2.0, 15000, 200, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', true, now(), null),
('fd000010-0000-0000-0000-000000000010', 'Salad cá hồi bơ', 'Salmon avocado salad', 'Salad', 'Salad hỗn hợp với bơ sáp và cá hồi phi lê nướng', 380, 23.0, 9.5, 28.0, 4.0, 85000, 250, 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', true, now(), null),
('fd000011-0000-0000-0000-000000000011', 'Phở bò Hà Nội', 'Hanoi beef pho', 'Món nước', 'Món phở truyền thống miền Bắc dẹt bánh nước dùng thanh', 350, 20.0, 45.0, 8.0, 1.5, 45000, 400, 'https://images.unsplash.com/photo-1583085314093-10c834952627?w=400', true, now(), 'north'),
('fd000012-0000-0000-0000-000000000012', 'Bún chả Hà Nội', 'Hanoi bun cha', 'Món nước', 'Thịt nướng thơm lừng ăn kèm bún và nước mắm chua ngọt', 480, 22.0, 60.0, 15.0, 2.0, 40000, 350, 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400', true, now(), 'north'),
('fd000013-0000-0000-0000-000000000013', 'Bún bò Huế', 'Hue beef noodle soup', 'Món nước', 'Món bún đậm đà cay nồng hương vị miền Trung', 510, 25.0, 55.0, 18.0, 1.0, 50000, 450, 'https://images.unsplash.com/photo-1625220194771-7ebedd0b40b8?w=400', true, now(), 'central'),
('fd000014-0000-0000-0000-000000000014', 'Mì quảng gà', 'Quang noodles with chicken', 'Món nước', 'Sợi mì quảng dai vàng sốt đậm đà từ miền Trung cát trắng', 420, 24.0, 50.0, 12.0, 2.5, 45000, 380, 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400', true, now(), 'central'),
('fd000015-0000-0000-0000-000000000015', 'Cơm tấm sườn bì chả', 'Broken rice with grilled pork', 'Món mặn', 'Món cơm tấm đặc sản miền Nam thơm nức mũi', 620, 28.0, 75.0, 22.0, 3.0, 45000, 350, 'https://images.unsplash.com/photo-1625372227556-2fd8c2bd3642?w=400', true, now(), 'south'),
('fd000016-0000-0000-0000-000000000016', 'Hủ tiếu Nam Vang', 'Nam Vang noodle soup', 'Món nước', 'Sợi hủ tiếu dai dai lòng heo tôm thịt phong cách miền Nam', 450, 18.0, 58.0, 14.0, 1.0, 45000, 400, 'https://images.unsplash.com/photo-1569562211093-4ed0d0758f12?w=400', true, now(), 'south')
ON CONFLICT DO NOTHING;

COMMIT;