-- =============================================================================
-- MenuGreen Seed Data - Table: ingredients
-- Sequence Number: 15
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS ingredients CASCADE;

CREATE TABLE ingredients (
    "Id" uuid NOT NULL,
    "NameVi" text NOT NULL,
    "NameEn" text NULL,
    "Category" text NULL,
    "CaloriesKcal" numeric NULL,
    "ProteinG" numeric NULL,
    "CarbsG" numeric NULL,
    "FatG" numeric NULL,
    "EstimatedPriceVnd" integer NULL,
    "UnitDefault" text NULL,
    "ImageUrl" text NULL,
    "IsActive" boolean NULL,
    "CreatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_ingredients" PRIMARY KEY ("Id")
);

INSERT INTO ingredients ("Id", "NameVi", "NameEn", "Category", "CaloriesKcal", "ProteinG", "CarbsG", "FatG", "EstimatedPriceVnd", "UnitDefault", "ImageUrl", "IsActive", "CreatedAt")
VALUES
('73cb3e0a-5abc-5c6c-a7a2-7a9ac350f4cd', 'Ức gà', 'Chicken breast', 'Thịt/Cá', 120, 26.0, 0.0, 1.5, 80000, 'g', 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=150', true, now()),
('81d8c5d5-4bc9-5c71-86a5-70672e7764b4', 'Xà lách', 'Lettuce', 'Rau củ', 15, 1.3, 2.8, 0.2, 25000, 'g', 'https://images.unsplash.com/photo-1556801712-74c73693f110?w=150', true, now()),
('6c224f0b-9b70-5342-8487-c7a49e2aaed4', 'Cà chua', 'Tomato', 'Rau củ', 18, 0.9, 3.9, 0.2, 20000, 'g', 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=150', true, now()),
('1ddf13c6-e4f7-5042-a801-62cb588e2dbd', 'Dầu olive', 'Olive oil', 'Gia vị/Dầu', 884, 0.0, 0.0, 100.0, 250000, 'ml', 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=150', true, now()),
('5824249f-4a90-5eb8-ab3e-fe00ffdbf0bb', 'Chanh', 'Lime', 'Rau củ', 30, 0.7, 10.5, 0.2, 15000, 'g', 'https://images.unsplash.com/photo-1590502593747-42a996133562?w=150', true, now()),
('36d9374a-4dc9-5066-bf57-ded98b96a211', 'Bơ quả', 'Avocado', 'Trái cây', 160, 2.0, 8.5, 14.7, 60000, 'g', 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=150', true, now()),
('9c5cd032-5b23-5f98-b8e3-db420837a526', 'Chuối', 'Banana', 'Trái cây', 89, 1.1, 22.8, 0.3, 18000, 'g', 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=150', true, now()),
('2c01232c-01f1-57e7-a8ef-d19a140ca266', 'Gạo lứt', 'Brown rice', 'Tinh bột', 111, 2.6, 23.0, 0.9, 35000, 'g', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=150', true, now()),
('01619128-a551-5bcb-84a9-5f7ddf562db4', 'Đậu hũ', 'Tofu', 'Đậu/Hạt', 76, 8.0, 1.9, 4.8, 15000, 'g', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=150', true, now()),
('53aa2eb8-e5c5-525a-a1bf-0f697cb5f048', 'Bơ đậu phộng', 'Peanut butter', 'Đậu/Hạt', 588, 25.0, 20.0, 50.0, 85000, 'g', 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=150', true, now()),
('ea000001-1111-2222-3333-444444444444', 'Thịt bò thăn', 'Beef tenderloin', 'Thịt/Cá', 143, 26.0, 0.0, 3.8, 280000, 'g', 'https://images.unsplash.com/photo-1544025162-d76694265947?w=150', true, now()),
('ea000002-1111-2222-3333-444444444444', 'Cá hồi phi lê', 'Salmon fillet', 'Thịt/Cá', 208, 20.0, 0.0, 13.0, 420000, 'g', 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=150', true, now()),
('ea000003-1111-2222-3333-444444444444', 'Yến mạch nguyên cám', 'Rolled oats', 'Tinh bột', 389, 16.9, 66.3, 6.9, 60000, 'g', 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=150', true, now()),
('ea000004-1111-2222-3333-444444444444', 'Trứng gà', 'Egg', 'Trứng/Sữa', 143, 13.0, 1.1, 11.0, 4000, 'quả', 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=150', true, now()),
('ea000005-1111-2222-3333-444444444444', 'Sữa tươi không đường', 'Unsweetened milk', 'Trứng/Sữa', 60, 3.2, 4.7, 3.3, 30000, 'ml', 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=150', true, now()),
('ea000006-1111-2222-3333-444444444444', 'Khoai lang', 'Sweet potato', 'Tinh bột', 86, 1.6, 20.1, 0.1, 20000, 'g', 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=150', true, now()),
('ea000007-1111-2222-3333-444444444444', 'Bông cải xanh', 'Broccoli', 'Rau củ', 34, 2.8, 6.6, 0.4, 30000, 'g', 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=150', true, now()),
('ea000008-1111-2222-3333-444444444444', 'Mật ong', 'Honey', 'Gia vị/Dầu', 304, 0.3, 82.4, 0.0, 180000, 'g', 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=150', true, now()),
('ea000009-1111-2222-3333-444444444444', 'Hạt hạnh nhân', 'Almonds', 'Đậu/Hạt', 579, 21.0, 22.0, 49.0, 350000, 'g', 'https://images.unsplash.com/photo-1508061263366-f7e9f45a7b81?w=150', true, now()),
('ea000010-1111-2222-3333-444444444444', 'Nấm đùi gà', 'King oyster mushroom', 'Rau củ', 35, 2.5, 6.0, 0.3, 65000, 'g', 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=150', true, now())
-- =============================================================================
-- MenuGreen Seed Data - Extended Ingredients (Items 21-55)
-- Added for extended recipes (ec000011-020) and skeleton recipes for popular
-- Vietnamese dishes (Phở, Bún chả, Bún bò Huế, Mì quảng, Cơm tấm, ...)
-- Idempotent: ON CONFLICT (Id) DO NOTHING via separate insert below.
-- =============================================================================
,('ea000021-1111-2222-3333-444444444444', 'Bánh mì Việt Nam', 'Vietnamese baguette', 'Tinh bột', 280, 9.0, 52.0, 4.5, 8000, 'ổ', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=150', true, now())
,('ea000022-1111-2222-3333-444444444444', 'Thịt nguội', 'Vietnamese cold cuts', 'Thịt/Cá', 250, 22.0, 2.0, 17.0, 12000, 'g', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc7f2?w=150', true, now())
,('ea000023-1111-2222-3333-444444444444', 'Dưa leo', 'Cucumber', 'Rau củ', 16, 0.7, 3.6, 0.1, 8000, 'g', 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=150', true, now())
,('ea000024-1111-2222-3333-444444444444', 'Rau răm', 'Vietnamese coriander', 'Rau củ', 23, 2.0, 4.0, 0.5, 30000, 'g', 'https://images.unsplash.com/photo-1628776279912-7b79b3ad9d2f?w=150', true, now())
,('ea000025-1111-2222-3333-444444444444', 'Hành tây', 'Onion', 'Rau củ', 40, 1.1, 9.3, 0.1, 15000, 'g', 'https://images.unsplash.com/photo-1620574387735-3624d75b2dbc?w=150', true, now())
,('ea000026-1111-2222-3333-444444444444', 'Bánh tráng', 'Rice paper', 'Tinh bột', 330, 0.5, 82.0, 0.2, 5000, 'tờ', 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=150', true, now())
,('ea000027-1111-2222-3333-444444444444', 'Tôm sú', 'Tiger shrimp', 'Thịt/Cá', 99, 24.0, 0.2, 0.3, 220000, 'g', 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=150', true, now())
,('ea000028-1111-2222-3333-444444444444', 'Thịt heo nạc', 'Lean pork', 'Thịt/Cá', 242, 26.0, 0.0, 15.0, 95000, 'g', 'https://images.unsplash.com/photo-1606851094291-6efae152bb87?w=150', true, now())
,('ea000029-1111-2222-3333-444444444444', 'Bún tươi', 'Fresh rice vermicelli', 'Tinh bột', 109, 1.8, 24.9, 0.2, 18000, 'g', 'https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=150', true, now())
,('ea000030-1111-2222-3333-444444444444', 'Rau thơm (húng quế)', 'Thai basil', 'Rau củ', 23, 3.2, 2.7, 0.6, 40000, 'g', 'https://images.unsplash.com/photo-1597714026720-8f74c62310ba?w=150', true, now())
,('ea000031-1111-2222-3333-444444444444', 'Gạo nếp', 'Sticky rice', 'Tinh bột', 97, 3.0, 21.0, 0.3, 25000, 'g', 'https://images.unsplash.com/photo-1626078442495-7f3a9b9c8b0c?w=150', true, now())
,('ea000032-1111-2222-3333-444444444444', 'Đậu xanh', 'Mung bean', 'Đậu/Hạt', 347, 21.0, 63.0, 1.2, 22000, 'g', 'https://images.unsplash.com/photo-1611599537845-1c7aca0091c0?w=150', true, now())
,('ea000033-1111-2222-3333-444444444444', 'Giò lụa', 'Vietnamese pork sausage', 'Thịt/Cá', 195, 19.0, 3.0, 12.0, 90000, 'g', 'https://images.unsplash.com/photo-1606851094291-6efae152bb87?w=150', true, now())
,('ea000034-1111-2222-3333-444444444444', 'Hành tím', 'Shallot', 'Rau củ', 72, 2.5, 16.8, 0.1, 20000, 'g', 'https://images.unsplash.com/photo-1615477550927-65f7d4b5f3b0?w=150', true, now())
,('ea000035-1111-2222-3333-444444444444', 'Sữa hạnh nhân', 'Almond milk', 'Trứng/Sữa', 17, 0.6, 0.6, 1.5, 55000, 'ml', 'https://images.unsplash.com/photo-1605684954998-685c79d6a018?w=150', true, now())
,('ea000036-1111-2222-3333-444444444444', 'Sữa chua Hy Lạp', 'Greek yogurt', 'Trứng/Sữa', 59, 10.0, 3.6, 0.4, 28000, 'g', 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=150', true, now())
,('ea000037-1111-2222-3333-444444444444', 'Hạt chia', 'Chia seeds', 'Đậu/Hạt', 486, 17.0, 42.0, 31.0, 220000, 'g', 'https://images.unsplash.com/photo-1518671532528-7b2f5b2f0c1c?w=150', true, now())
,('ea000038-1111-2222-3333-444444444444', 'Granola', 'Granola', 'Tinh bột', 489, 13.0, 64.0, 24.0, 120000, 'g', 'https://images.unsplash.com/photo-1517686469429-8bdb88b9f907?w=150', true, now())
,('ea000039-1111-2222-3333-444444444444', 'Berries đông lạnh', 'Mixed berries', 'Trái cây', 50, 0.7, 12.0, 0.3, 95000, 'g', 'https://images.unsplash.com/photo-1488900128323-21503983a07e?w=150', true, now())
,('ea000040-1111-2222-3333-444444444444', 'Rosemary', 'Rosemary', 'Gia vị/Dầu', 131, 3.3, 20.7, 5.9, 80000, 'g', 'https://images.unsplash.com/photo-1515586000433-45406d8e6662?w=150', true, now())
,('ea000041-1111-2222-3333-444444444444', 'Ớt chuông', 'Bell pepper', 'Rau củ', 31, 1.0, 6.0, 0.3, 28000, 'g', 'https://images.unsplash.com/photo-1525607551316-4a8e16d1f9ba?w=150', true, now())
,('ea000042-1111-2222-3333-444444444444', 'Cà rốt', 'Carrot', 'Rau củ', 41, 0.9, 9.6, 0.2, 12000, 'g', 'https://images.unsplash.com/photo-1582515073490-39981397c445?w=150', true, now())
,('ea000043-1111-2222-3333-444444444444', 'Quinoa', 'Quinoa', 'Tinh bột', 120, 4.4, 21.3, 1.9, 180000, 'g', 'https://images.unsplash.com/photo-1612257999691-c2c69c2e3f1b?w=150', true, now())
,('ea000044-1111-2222-3333-444444444444', 'Rau mầm', 'Bean sprouts', 'Rau củ', 30, 3.0, 5.9, 0.2, 18000, 'g', 'https://images.unsplash.com/photo-1602081115853-59c92b1b1f6e?w=150', true, now())
,('ea000045-1111-2222-3333-444444444444', 'Tahini', 'Tahini', 'Gia vị/Dầu', 595, 17.0, 21.0, 54.0, 220000, 'g', 'https://images.unsplash.com/photo-1593011951972-bd9ad65c1d0d?w=150', true, now())
,('ea000046-1111-2222-3333-444444444444', 'Hạt é', 'Basil seeds', 'Đậu/Hạt', 23, 0.8, 2.0, 0.4, 180000, 'g', 'https://images.unsplash.com/photo-1622480916113-9000ae6426f3?w=150', true, now())
,('ea000047-1111-2222-3333-444444444444', 'Bột Acai', 'Acai powder', 'Trái cây', 533, 8.0, 52.0, 32.0, 450000, 'g', 'https://images.unsplash.com/photo-1610276198568-eb6d0ff53e48?w=150', true, now())
,('ea000048-1111-2222-3333-444444444444', 'Sữa dừa', 'Coconut milk', 'Trứng/Sữa', 230, 2.3, 5.5, 24.0, 45000, 'ml', 'https://images.unsplash.com/photo-1612181027931-c4f2e6d2a3f3?w=150', true, now())
,('ea000049-1111-2222-3333-444444444444', 'Dừa nạo', 'Shredded coconut', 'Trái cây', 660, 7.0, 24.0, 64.0, 80000, 'g', 'https://images.unsplash.com/photo-1581235720704-06d3acfcb36f?w=150', true, now())
,('ea000050-1111-2222-3333-444444444444', 'Gừng tươi', 'Fresh ginger', 'Gia vị/Dầu', 80, 1.8, 18.0, 0.8, 60000, 'g', 'https://images.unsplash.com/photo-1608032077018-c9aad9565d29?w=150', true, now())
,('ea000051-1111-2222-3333-444444444444', 'Gạo tẻ', 'Long-grain rice', 'Tinh bột', 130, 2.7, 28.0, 0.3, 18000, 'g', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=150', true, now())
,('ea000052-1111-2222-3333-444444444444', 'Dưa cải muối', 'Pickled mustard greens', 'Rau củ', 25, 1.5, 4.5, 0.3, 25000, 'g', 'https://images.unsplash.com/photo-1626197031507-cd0a0a9c2d3f?w=150', true, now())
,('ea000053-1111-2222-3333-444444444444', 'Đu đủ xanh', 'Green papaya', 'Trái cây', 43, 0.5, 10.8, 0.3, 15000, 'g', 'https://images.unsplash.com/photo-1626197031507-cd0a0a9c2d3f?w=150', true, now())
,('ea000054-1111-2222-3333-444444444444', 'Khô bò', 'Beef jerky', 'Thịt/Cá', 410, 33.0, 11.0, 25.0, 280000, 'g', 'https://images.unsplash.com/photo-1606851094291-6efae152bb87?w=150', true, now())
,('ea000055-1111-2222-3333-444444444444', 'Đậu phộng rang', 'Roasted peanuts', 'Đậu/Hạt', 567, 26.0, 16.0, 49.0, 90000, 'g', 'https://images.unsplash.com/photo-1567892745478-b5d4d3a9b3e8?w=150', true, now())
ON CONFLICT ("Id") DO NOTHING;

COMMIT;
