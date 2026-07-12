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
ON CONFLICT DO NOTHING;

COMMIT;