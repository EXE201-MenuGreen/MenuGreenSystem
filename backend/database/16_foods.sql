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
('fd000016-0000-0000-0000-000000000016', 'Hủ tiếu Nam Vang', 'Nam Vang noodle soup', 'Món nước', 'Sợi hủ tiếu dai dai lòng heo tôm thịt phong cách miền Nam', 450, 18.0, 58.0, 14.0, 1.0, 45000, 400, 'https://images.unsplash.com/photo-1569562211093-4ed0d0758f12?w=400', true, now(), 'south'),
-- =============================================================================
-- MenuGreen Seed Data - Extended Foods (Items 17-50)
-- Added: Vietnamese favorites, healthy options, snacks, breakfast items
-- =============================================================================
('fd000017-0000-0000-0000-000000000017', 'Bánh mì thịt', 'Vietnamese baguette with grilled pork', 'Món mặn', 'Bánh mì giòn bên ngoài, nhồi thịt nguội và rau thơm', 350, 15.0, 45.0, 12.0, 2.0, 25000, 150, 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400', true, now(), 'south'),
('fd000018-0000-0000-0000-000000000018', 'Gỏi cuốn tôm thịt', 'Fresh spring rolls with shrimp and pork', 'Salad', 'Cuốn bánh tráng trong mỏng nhân tôm thịt luộc và rau xanh', 180, 12.0, 25.0, 3.5, 2.5, 35000, 120, 'https://images.unsplash.com/photo-1562967916-eb82221dfb44?w=400', true, now(), 'south'),
('fd000019-0000-0000-0000-000000000019', 'Nem nướng Nha Trang', 'Nha Trang grilled pork rolls', 'Món mặn', 'Nem nướng dai ngon cuốn bánh tráng với rau sống', 320, 18.0, 35.0, 12.0, 2.0, 40000, 150, 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', true, now(), 'central'),
('fd000020-0000-0000-0000-000000000020', 'Cơm rang dưa bò', 'Fried rice with beef and pickles', 'Món mặn', 'Cơm rang khô rời với thịt bò xào và dưa cải chua', 480, 20.0, 60.0, 16.0, 1.5, 45000, 250, 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', true, now(), null),
('fd000021-0000-0000-0000-000000000021', 'Bún bò Huế', 'Hue beef noodle soup', 'Món nước', 'Món bún đậm đà cay nồng hương vị miền Trung', 510, 25.0, 55.0, 18.0, 1.0, 50000, 450, 'https://images.unsplash.com/photo-1625220194771-7ebedd0b40b8?w=400', true, now(), 'central'),
('fd000022-0000-0000-0000-000000000022', 'Bún chả Hà Nội', 'Hanoi bun cha', 'Món nước', 'Thịt nướng thơm lừng ăn kèm bún và nước mắm chua ngọt', 480, 22.0, 60.0, 15.0, 2.0, 40000, 350, 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400', true, now(), 'north'),
('fd000023-0000-0000-0000-000000000023', 'Bánh cuốn', 'Steamed rice rolls', 'Món nước', 'Bánh cuốn mỏng nhân thịt băm và nấm hương', 280, 12.0, 40.0, 6.0, 1.5, 30000, 200, 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=400', true, now(), 'north'),
('fd000024-0000-0000-0000-000000000024', 'Bánh gối', 'Vietnamese fried pastry', 'Món mặn', 'Bánh gối giòn rụm nhân thịt và rau củ', 320, 10.0, 38.0, 14.0, 2.0, 20000, 100, 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400', true, now(), 'south'),
('fd000025-0000-0000-0000-000000000025', 'Xôi xéo', 'Mung bean sticky rice', 'Tinh bột', 'Xôi nếp dẻo phủ nước xôi vàng ươm thơm mùi đậu xanh', 350, 8.0, 65.0, 6.0, 1.5, 25000, 200, 'https://images.unsplash.com/photo-1589115018-17b7b3da4d3a?w=400', true, now(), 'north'),
('fd000026-0000-0000-0000-000000000026', 'Xôi đậu phộng', 'Peanut sticky rice', 'Tinh bột', 'Xôi nếp dẻo rắc đậu phộng rang giã nhuyễn', 380, 9.0, 68.0, 8.0, 2.0, 20000, 180, 'https://images.unsplash.com/photo-1577633768713-879e2a8e83c0?w=400', true, now(), null),
('fd000027-0000-0000-0000-000000000027', 'Cháo lòng', 'Pork offal porridge', 'Món nước', 'Cháo loãng ăn kèm lòng heo và tim cật', 320, 15.0, 35.0, 12.0, 1.0, 35000, 300, 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400', true, now(), 'south'),
('fd000028-0000-0000-0000-000000000028', 'Bánh flan', 'Vietnamese caramel flan', 'Tráng miệng', 'Bánh flan mịn màng sốt caramel đằm thơm', 200, 5.0, 30.0, 6.0, 0.0, 15000, 120, 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400', true, now(), null),
('fd000029-0000-0000-0000-000000000029', 'Chè đậu xanh', 'Mung bean dessert soup', 'Tráng miệng', 'Chè đậu xanh nấu với nước cốt dừa béo ngậy', 180, 6.0, 30.0, 4.0, 1.0, 12000, 150, 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400', true, now(), null),
('fd000030-0000-0000-0000-000000000030', 'Chè thái đỏ', 'Thai red bean dessert', 'Tráng miệng', 'Chè thái sợi đỏ thẫm nước cốt dừa ngọt mát', 220, 4.0, 40.0, 5.0, 1.5, 15000, 180, 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400', true, now(), 'south'),
('fd000031-0000-0000-0000-000000000031', 'Sữa chua nếp cẩm', 'Purple sticky rice yogurt', 'Tráng miệng', 'Nếp cẩm dai bùi ăn cùng sữa chua trắng', 250, 6.0, 42.0, 5.0, 1.0, 20000, 150, 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400', true, now(), 'north'),
('fd000032-0000-0000-0000-000000000032', 'Overnight oats', 'Overnight oats with berries', 'Món nước', 'Yến mạch ngâm qua đêm với sữa chua và trái cây', 320, 12.0, 45.0, 8.0, 5.0, 35000, 200, 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?w=400', true, now(), null),
('fd000033-0000-0000-0000-000000000033', 'Grilled chicken breast', 'Grilled chicken breast with herbs', 'Món mặn', 'Ức gà nướng than thơm lừng với rau thơm', 200, 38.0, 2.0, 4.0, 1.0, 55000, 180, 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=400', true, now(), null),
('fd000034-0000-0000-0000-000000000034', 'Egg white omelette', 'Vegetable egg white omelette', 'Món mặn', 'Trứng tách lòng đỏ xào rau củ giòn ngon', 150, 18.0, 4.0, 6.0, 2.0, 25000, 120, 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400', true, now(), null),
('fd000035-0000-0000-0000-000000000035', 'Greek yogurt parfait', 'Greek yogurt with granola', 'Tráng miệng', 'Sữa chua Hy Lạp với granola giòn và mật ong', 280, 15.0, 35.0, 8.0, 3.0, 40000, 180, 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400', true, now(), null),
('fd000036-0000-0000-0000-000000000036', 'Quinoa salad', 'Quinoa salad with vegetables', 'Salad', 'Quinoa trắng xanh cùng rau củ tươi và sốt dầu giấm', 250, 8.0, 35.0, 8.0, 6.0, 45000, 200, 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', true, now(), null),
('fd000037-0000-0000-0000-000000000037', 'Smoothie bowl', 'Acai smoothie bowl', 'Thức uống', 'Bát sinh tố đông đặc với trái cây và topping', 350, 6.0, 55.0, 10.0, 8.0, 55000, 300, 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400', true, now(), null),
('fd000038-0000-0000-0000-000000000038', 'Nước ép rau má', 'Pennywort juice', 'Thức uống', 'Nước ép rau má tươi mát lành giải nhiệt', 80, 2.0, 15.0, 1.0, 2.0, 15000, 250, 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400', true, now(), null),
('fd000039-0000-0000-0000-000000000039', 'Nước chanh đường', 'Lemonade', 'Thức uống', 'Nước chanh tươi pha đường giải khát', 100, 0.0, 25.0, 0.0, 0.0, 10000, 250, 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400', true, now(), null),
('fd000040-0000-0000-0000-000000000040', 'Trà đá', 'Iced tea', 'Thức uống', 'Trà đá thanh mát giải khát ngày hè', 50, 0.0, 12.0, 0.0, 0.0, 5000, 250, 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', true, now(), null),
('fd000041-0000-0000-0000-000000000041', 'Cà phê sữa đá', 'Vietnamese iced coffee', 'Thức uống', 'Cà phê phin pha sữa đặc đá xay', 150, 2.0, 25.0, 3.0, 0.0, 25000, 200, 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400', true, now(), null),
('fd000042-0000-0000-0000-000000000042', 'Trà sữa trân châu', 'Bubble tea with tapioca pearls', 'Thức uống', 'Trà sữa ngọt béo kèm trân châu dai giòn', 280, 2.0, 50.0, 6.0, 0.0, 30000, 350, 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=400', true, now(), null),
('fd000043-0000-0000-0000-000000000043', 'Bún mắm', 'Fermented shrimp paste noodle', 'Món nước', 'Bún ăn với mắm nổi tiếng miền Nam', 450, 18.0, 55.0, 16.0, 2.0, 35000, 350, 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400', true, now(), 'south'),
('fd000044-0000-0000-0000-000000000044', 'Mì quảng gà', 'Quang noodles with chicken', 'Món nước', 'Sợi mì quảng dai vàng sốt đậm đà từ miền Trung cát trắng', 420, 24.0, 50.0, 12.0, 2.5, 45000, 380, 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400', true, now(), 'central'),
('fd000045-0000-0000-0000-000000000045', 'Bánh canh cua', 'Crab noodle soup', 'Món nước', 'Bánh canh nước lèo đậm đà với thịt cua thơm phức', 380, 22.0, 45.0, 12.0, 1.5, 50000, 350, 'https://images.unsplash.com/photo-1625220194771-7ebedd0b40b8?w=400', true, now(), 'south'),
('fd000046-0000-0000-0000-000000000046', 'Bánh tráng trộn', 'Mixed rice paper salad', 'Salad', 'Bánh tráng phiến trộn xoài khô tôm khứa đủ vị', 320, 10.0, 50.0, 8.0, 2.0, 20000, 150, 'https://images.unsplash.com/photo-1562967916-eb82221dfb44?w=400', true, now(), 'south'),
('fd000047-0000-0000-0000-000000000047', 'Gỏi đu đủ', 'Green papaya salad', 'Salad', 'Đu đủ xanh bào sợi trộn khô bò giòn rụm', 250, 12.0, 30.0, 10.0, 4.0, 30000, 200, 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=400', true, now(), 'central'),
('fd000048-0000-0000-0000-000000000048', 'Cơm tấm sườn bì chả', 'Broken rice with grilled pork', 'Món mặn', 'Món cơm tấm đặc sản miền Nam thơm nức mũi', 620, 28.0, 75.0, 22.0, 3.0, 45000, 350, 'https://images.unsplash.com/photo-1625372227556-2fd8c2bd3642?w=400', true, now(), 'south'),
('fd000049-0000-0000-0000-000000000049', 'Cơm gà Hainan', 'Hainan chicken rice', 'Món mặn', 'Cơm trắng thơm mềm ăn với gà luộc và nước mắm gừng', 500, 30.0, 55.0, 16.0, 1.0, 55000, 350, 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400', true, now(), 'south'),
('fd000050-0000-0000-0000-000000000050', 'Vịt quay Bắc Kinh', 'Peking duck', 'Món mặn', 'Thịt vịt quay giòn da nhồi hành phi thơm lừng', 550, 35.0, 25.0, 35.0, 0.5, 180000, 200, 'https://images.unsplash.com/photo-1518492104633-130d0cc84637?w=400', true, now(), null)
ON CONFLICT DO NOTHING;

COMMIT;