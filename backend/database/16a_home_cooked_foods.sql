-- =============================================================================
-- MenuGreen Seed Data - 80 home-cooked foods
-- Runs after 16_foods.sql and before recipes.
-- EstimatedPriceVnd is the estimated cost of one DefaultServingG portion.
-- The script is idempotent by Id and also avoids duplicate Vietnamese names.
-- =============================================================================
BEGIN;

ALTER TABLE foods ADD COLUMN IF NOT EXISTS "PreparationMinutes" integer NULL;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS "CookingMinutes" integer NULL;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS "DifficultyLevel" text NULL;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS "MealType" text NULL;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS "DietType" text NULL;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS "MainIngredient" text NULL;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS "CookingMethod" text NULL;

WITH seed (
    id, name_vi, name_en, category, description,
    calories, protein, carbs, fat, fiber,
    price_vnd, serving_g, region, preparation_minutes, cooking_minutes,
    difficulty_level, meal_type, diet_type, main_ingredient, cooking_method
) AS (
VALUES
-- 1. Chicken dishes
('fd110001-1000-4000-8000-000000000001', 'Gà kho gừng', 'Ginger braised chicken', 'Món mặn', 'Gà kho gừng ấm bụng, phù hợp bữa cơm gia đình.', 285, 27.0, 8.0, 16.0, 0.8, 38000, 220, 'nationwide', 15, 30, 'easy', 'lunch,dinner', 'high_protein', 'chicken', 'braised'),
('fd110002-1000-4000-8000-000000000002', 'Gà kho sả', 'Lemongrass braised chicken', 'Món mặn', 'Gà kho sả thơm đậm, dễ chuẩn bị tại nhà.', 300, 26.0, 9.0, 18.0, 1.0, 38000, 220, 'south', 15, 30, 'easy', 'lunch,dinner', 'high_protein', 'chicken', 'braised'),
('fd110003-1000-4000-8000-000000000003', 'Gà luộc lá chanh', 'Boiled chicken with lime leaves', 'Món mặn', 'Gà luộc lá chanh ít dầu mỡ, giàu protein.', 240, 30.0, 2.0, 12.0, 0.2, 42000, 200, 'north', 10, 30, 'easy', 'lunch,dinner', 'low_carb', 'chicken', 'boiled'),
('fd110004-1000-4000-8000-000000000004', 'Gà rang muối', 'Salt roasted chicken', 'Món mặn', 'Gà rang muối giòn thơm dùng cho bữa chính.', 390, 28.0, 18.0, 23.0, 1.0, 48000, 220, 'nationwide', 20, 30, 'medium', 'lunch,dinner', 'balanced', 'chicken', 'deep_fried'),
('fd110005-1000-4000-8000-000000000005', 'Gà hấp hành', 'Steamed chicken with scallions', 'Món mặn', 'Gà hấp hành mềm ngọt và hạn chế dầu.', 245, 29.0, 4.0, 13.0, 0.5, 42000, 210, 'nationwide', 15, 30, 'easy', 'lunch,dinner', 'high_protein', 'chicken', 'steamed'),
('fd110006-1000-4000-8000-000000000006', 'Gà xào nấm', 'Chicken stir-fried with mushrooms', 'Món mặn', 'Gà xào nấm cân bằng protein và rau.', 275, 27.0, 12.0, 14.0, 2.5, 45000, 250, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'high_protein', 'chicken', 'stir_fry'),
('fd110007-1000-4000-8000-000000000007', 'Gà xào rau củ', 'Chicken and vegetable stir-fry', 'Món mặn', 'Gà xào rau củ nhiều màu, phù hợp cơm hộp.', 290, 26.0, 18.0, 13.0, 4.0, 42000, 280, 'nationwide', 20, 15, 'easy', 'lunch,dinner', 'balanced', 'chicken', 'stir_fry'),
('fd110008-1000-4000-8000-000000000008', 'Gà nướng ngũ vị', 'Five-spice grilled chicken', 'Món mặn', 'Gà ướp ngũ vị nướng thơm, thích hợp chuẩn bị trước.', 330, 29.0, 10.0, 20.0, 0.7, 48000, 220, 'nationwide', 30, 35, 'medium', 'lunch,dinner', 'high_protein', 'chicken', 'grilled'),
('fd110009-1000-4000-8000-000000000009', 'Cánh gà sốt nước mắm', 'Fish sauce glazed chicken wings', 'Món mặn', 'Cánh gà sốt nước mắm đậm vị cho bữa gia đình.', 410, 25.0, 20.0, 26.0, 0.3, 45000, 230, 'south', 20, 25, 'medium', 'lunch,dinner', 'balanced', 'chicken', 'pan_fried'),
('fd110010-1000-4000-8000-000000000010', 'Ức gà sốt tiêu đen', 'Black pepper chicken breast', 'Món mặn', 'Ức gà sốt tiêu đen giàu đạm, tiện mang đi làm.', 260, 34.0, 11.0, 9.0, 1.2, 42000, 210, 'nationwide', 15, 20, 'easy', 'lunch,dinner', 'high_protein', 'chicken', 'pan_fried'),

-- 2. Pork dishes
('fd110011-1000-4000-8000-000000000011', 'Thịt kho trứng', 'Braised pork with eggs', 'Món mặn', 'Thịt kho trứng truyền thống, dùng cùng cơm.', 420, 24.0, 12.0, 31.0, 0.5, 45000, 250, 'south', 20, 60, 'medium', 'lunch,dinner', 'balanced', 'pork', 'braised'),
('fd110012-1000-4000-8000-000000000012', 'Thịt kho tiêu', 'Pepper braised pork', 'Món mặn', 'Thịt kho tiêu đậm đà, nguyên liệu dễ tìm.', 370, 25.0, 7.0, 27.0, 0.5, 38000, 210, 'south', 15, 35, 'easy', 'lunch,dinner', 'balanced', 'pork', 'braised'),
('fd110013-1000-4000-8000-000000000013', 'Thịt rang cháy cạnh', 'Caramelized pork', 'Món mặn', 'Thịt rang cháy cạnh nhanh gọn cho bữa cơm.', 395, 24.0, 10.0, 29.0, 0.4, 40000, 210, 'north', 15, 20, 'easy', 'lunch,dinner', 'balanced', 'pork', 'pan_fried'),
('fd110014-1000-4000-8000-000000000014', 'Sườn xào chua ngọt', 'Sweet and sour pork ribs', 'Món mặn', 'Sườn xào chua ngọt kết hợp thịt và rau củ.', 430, 24.0, 28.0, 25.0, 2.0, 60000, 260, 'nationwide', 25, 35, 'medium', 'lunch,dinner', 'balanced', 'pork_ribs', 'stir_fry'),
('fd110015-1000-4000-8000-000000000015', 'Sườn non kho tiêu', 'Pepper braised baby ribs', 'Món mặn', 'Sườn non kho tiêu mềm và đậm vị.', 405, 25.0, 9.0, 29.0, 0.4, 58000, 230, 'south', 20, 40, 'medium', 'lunch,dinner', 'balanced', 'pork_ribs', 'braised'),
('fd110016-1000-4000-8000-000000000016', 'Sườn nướng mật ong', 'Honey grilled pork ribs', 'Món mặn', 'Sườn nướng mật ong thơm ngọt, phù hợp cuối tuần.', 455, 27.0, 24.0, 28.0, 0.5, 65000, 250, 'nationwide', 35, 40, 'medium', 'lunch,dinner', 'balanced', 'pork_ribs', 'grilled'),
('fd110017-1000-4000-8000-000000000017', 'Thịt heo xào hành tây', 'Pork stir-fried with onion', 'Món mặn', 'Thịt heo xào hành tây chế biến nhanh.', 315, 25.0, 13.0, 18.0, 1.8, 38000, 240, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'balanced', 'pork', 'stir_fry'),
('fd110018-1000-4000-8000-000000000018', 'Thịt heo xào rau cải', 'Pork and greens stir-fry', 'Món mặn', 'Thịt heo xào rau cải cân bằng cho cơm hộp.', 300, 25.0, 12.0, 17.0, 3.5, 38000, 270, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'balanced', 'pork', 'stir_fry'),
('fd110019-1000-4000-8000-000000000019', 'Thịt viên sốt cà chua', 'Pork meatballs in tomato sauce', 'Món mặn', 'Thịt viên sốt cà chua mềm, dễ chia khẩu phần.', 340, 24.0, 18.0, 20.0, 2.2, 40000, 250, 'nationwide', 25, 25, 'medium', 'lunch,dinner', 'balanced', 'pork', 'stewed'),
('fd110020-1000-4000-8000-000000000020', 'Ba chỉ cuộn nấm kim châm', 'Pork belly enoki rolls', 'Món mặn', 'Ba chỉ cuộn nấm kim châm áp chảo tại nhà.', 390, 20.0, 12.0, 30.0, 2.0, 50000, 220, 'nationwide', 25, 20, 'medium', 'lunch,dinner', 'low_carb', 'pork', 'pan_fried'),

-- 3. Beef dishes
('fd110021-1000-4000-8000-000000000021', 'Bò xào cần tây', 'Beef and celery stir-fry', 'Món mặn', 'Bò xào cần tây thơm, giàu protein.', 290, 29.0, 11.0, 15.0, 2.5, 58000, 240, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'high_protein', 'beef', 'stir_fry'),
('fd110022-1000-4000-8000-000000000022', 'Bò xào hành tây', 'Beef and onion stir-fry', 'Món mặn', 'Bò xào hành tây nhanh gọn cho ngày bận rộn.', 310, 29.0, 14.0, 16.0, 1.8, 58000, 240, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'high_protein', 'beef', 'stir_fry'),
('fd110023-1000-4000-8000-000000000023', 'Bò xào giá đỗ', 'Beef and bean sprout stir-fry', 'Món mặn', 'Bò xào giá đỗ ít tinh bột, nhiều đạm.', 270, 28.0, 10.0, 14.0, 2.2, 55000, 250, 'nationwide', 15, 12, 'easy', 'lunch,dinner', 'low_carb', 'beef', 'stir_fry'),
('fd110024-1000-4000-8000-000000000024', 'Bò sốt vang', 'Vietnamese beef stew with wine', 'Món mặn', 'Bò sốt vang hầm mềm dùng cùng bánh mì hoặc cơm.', 410, 31.0, 24.0, 23.0, 3.0, 70000, 300, 'north', 30, 90, 'hard', 'lunch,dinner', 'high_protein', 'beef', 'stewed'),
('fd110025-1000-4000-8000-000000000025', 'Bò kho cà rốt', 'Braised beef with carrots', 'Món mặn', 'Bò kho cà rốt giàu đạm và rau củ.', 390, 31.0, 22.0, 21.0, 3.5, 68000, 300, 'south', 25, 75, 'medium', 'lunch,dinner', 'balanced', 'beef', 'braised'),
('fd110026-1000-4000-8000-000000000026', 'Bò hầm khoai tây', 'Beef and potato stew', 'Món mặn', 'Bò hầm khoai tây là bữa chính đủ năng lượng.', 445, 31.0, 34.0, 21.0, 4.0, 70000, 320, 'nationwide', 25, 90, 'medium', 'lunch,dinner', 'balanced', 'beef', 'stewed'),
('fd110027-1000-4000-8000-000000000027', 'Bò cuộn rau củ', 'Beef vegetable rolls', 'Món mặn', 'Bò cuộn rau củ ít carb và dễ chia phần.', 300, 30.0, 13.0, 15.0, 3.0, 65000, 240, 'nationwide', 30, 20, 'medium', 'lunch,dinner', 'low_carb', 'beef', 'pan_fried'),
('fd110028-1000-4000-8000-000000000028', 'Bò xào nấm', 'Beef and mushroom stir-fry', 'Món mặn', 'Bò xào nấm giàu protein, vị thanh.', 295, 30.0, 12.0, 15.0, 2.8, 62000, 250, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'high_protein', 'beef', 'stir_fry'),
('fd110029-1000-4000-8000-000000000029', 'Bò sốt tiêu đen', 'Black pepper beef', 'Món mặn', 'Bò sốt tiêu đen đậm vị, dùng cho cơm hộp.', 345, 30.0, 17.0, 19.0, 1.5, 65000, 240, 'nationwide', 20, 20, 'medium', 'lunch,dinner', 'high_protein', 'beef', 'stir_fry'),
('fd110030-1000-4000-8000-000000000030', 'Canh kim chi thịt bò', 'Kimchi beef soup', 'Món canh', 'Canh kim chi thịt bò cay nhẹ và giàu đạm.', 260, 23.0, 16.0, 12.0, 3.5, 55000, 350, 'nationwide', 20, 30, 'easy', 'lunch,dinner', 'high_protein', 'beef', 'soup'),

-- 4. Fish and seafood dishes
('fd110031-1000-4000-8000-000000000031', 'Cá lóc kho tộ', 'Clay pot braised snakehead fish', 'Món mặn', 'Cá lóc kho tộ đậm vị miền Nam.', 315, 31.0, 9.0, 17.0, 0.5, 50000, 230, 'south', 20, 40, 'medium', 'lunch,dinner', 'high_protein', 'snakehead_fish', 'braised'),
('fd110032-1000-4000-8000-000000000032', 'Cá nục kho cà chua', 'Braised mackerel with tomato', 'Món mặn', 'Cá nục kho cà chua dễ nấu và giàu omega-3.', 300, 28.0, 10.0, 17.0, 1.5, 38000, 230, 'central', 15, 35, 'easy', 'lunch,dinner', 'high_protein', 'mackerel', 'braised'),
('fd110033-1000-4000-8000-000000000033', 'Cá basa chiên sả', 'Lemongrass fried basa fish', 'Món mặn', 'Cá basa chiên sả thơm giòn, nguyên liệu phổ biến.', 380, 27.0, 15.0, 24.0, 0.8, 40000, 220, 'south', 20, 20, 'easy', 'lunch,dinner', 'balanced', 'basa_fish', 'pan_fried'),
('fd110034-1000-4000-8000-000000000034', 'Cá hồi nướng giấy bạc', 'Foil-baked salmon', 'Món mặn', 'Cá hồi nướng giấy bạc giữ độ ẩm và dinh dưỡng.', 360, 32.0, 8.0, 23.0, 2.0, 95000, 220, 'nationwide', 20, 30, 'medium', 'lunch,dinner', 'high_protein', 'salmon', 'baked'),
('fd110035-1000-4000-8000-000000000035', 'Cá thu sốt cà chua', 'Mackerel in tomato sauce', 'Món mặn', 'Cá thu sốt cà chua dễ ăn cùng cơm.', 330, 29.0, 12.0, 19.0, 1.8, 55000, 230, 'nationwide', 20, 30, 'easy', 'lunch,dinner', 'high_protein', 'mackerel', 'stewed'),
('fd110036-1000-4000-8000-000000000036', 'Cá rô phi chiên giòn', 'Crispy fried tilapia', 'Món mặn', 'Cá rô phi chiên giòn cho bữa cơm gia đình.', 400, 30.0, 14.0, 25.0, 0.5, 42000, 230, 'nationwide', 15, 25, 'easy', 'lunch,dinner', 'balanced', 'tilapia', 'deep_fried'),
('fd110037-1000-4000-8000-000000000037', 'Cá hấp hành gừng', 'Steamed fish with ginger and scallion', 'Món mặn', 'Cá hấp hành gừng ít dầu, vị thanh.', 235, 31.0, 6.0, 9.0, 0.8, 55000, 230, 'nationwide', 20, 25, 'easy', 'lunch,dinner', 'low_calorie', 'white_fish', 'steamed'),
('fd110038-1000-4000-8000-000000000038', 'Tôm rang thịt', 'Caramelized shrimp with pork', 'Món mặn', 'Tôm rang thịt đậm đà, phù hợp bữa chính.', 360, 27.0, 12.0, 23.0, 0.4, 60000, 220, 'north', 20, 25, 'medium', 'lunch,dinner', 'high_protein', 'shrimp', 'pan_fried'),
('fd110039-1000-4000-8000-000000000039', 'Tôm rim nước dừa', 'Coconut braised shrimp', 'Món mặn', 'Tôm rim nước dừa vị ngọt tự nhiên.', 300, 28.0, 17.0, 13.0, 0.5, 60000, 220, 'south', 20, 25, 'easy', 'lunch,dinner', 'high_protein', 'shrimp', 'braised'),
('fd110040-1000-4000-8000-000000000040', 'Mực xào dứa', 'Squid stir-fried with pineapple', 'Món mặn', 'Mực xào dứa chua ngọt, thêm nhiều rau.', 270, 25.0, 20.0, 10.0, 2.8, 58000, 260, 'nationwide', 20, 15, 'easy', 'lunch,dinner', 'low_calorie', 'squid', 'stir_fry'),

-- 5. Egg dishes
('fd110041-1000-4000-8000-000000000041', 'Trứng chiên hành', 'Scallion omelette', 'Món sáng', 'Trứng chiên hành nhanh gọn cho bữa sáng.', 220, 14.0, 4.0, 16.0, 0.5, 12000, 140, 'nationwide', 5, 8, 'easy', 'breakfast,lunch', 'vegetarian', 'egg', 'pan_fried'),
('fd110042-1000-4000-8000-000000000042', 'Trứng chiên cà chua', 'Tomato omelette', 'Món sáng', 'Trứng chiên cà chua mềm, dễ chuẩn bị.', 230, 14.0, 9.0, 16.0, 1.8, 15000, 180, 'nationwide', 10, 10, 'easy', 'breakfast,lunch', 'vegetarian', 'egg', 'pan_fried'),
('fd110043-1000-4000-8000-000000000043', 'Trứng hấp thịt bằm', 'Steamed egg with minced pork', 'Món mặn', 'Trứng hấp thịt bằm mềm và giàu đạm.', 260, 21.0, 6.0, 17.0, 0.3, 25000, 200, 'nationwide', 15, 20, 'easy', 'lunch,dinner', 'high_protein', 'egg', 'steamed'),
('fd110044-1000-4000-8000-000000000044', 'Trứng kho thịt', 'Braised egg with pork', 'Món mặn', 'Trứng kho thịt dùng với cơm cho bữa chính.', 350, 22.0, 10.0, 25.0, 0.3, 30000, 220, 'south', 15, 35, 'easy', 'lunch,dinner', 'balanced', 'egg', 'braised'),
('fd110045-1000-4000-8000-000000000045', 'Trứng sốt cà chua', 'Eggs in tomato sauce', 'Món sáng', 'Trứng sốt cà chua tiết kiệm và dễ nấu.', 225, 14.0, 11.0, 14.0, 2.0, 15000, 190, 'nationwide', 10, 12, 'easy', 'breakfast,lunch', 'vegetarian', 'egg', 'stewed'),
('fd110046-1000-4000-8000-000000000046', 'Trứng cuộn rong biển', 'Seaweed rolled omelette', 'Món sáng', 'Trứng cuộn rong biển tiện mang theo.', 240, 16.0, 8.0, 16.0, 1.5, 22000, 170, 'nationwide', 15, 12, 'medium', 'breakfast,lunch', 'high_protein', 'egg', 'pan_fried'),
('fd110047-1000-4000-8000-000000000047', 'Trứng chiên nấm', 'Mushroom omelette', 'Món sáng', 'Trứng chiên nấm bổ sung chất xơ cho bữa sáng.', 235, 16.0, 8.0, 16.0, 2.2, 20000, 190, 'nationwide', 10, 10, 'easy', 'breakfast,lunch', 'vegetarian', 'egg', 'pan_fried'),
('fd110048-1000-4000-8000-000000000048', 'Trứng hấp rau củ', 'Steamed egg with vegetables', 'Món sáng', 'Trứng hấp rau củ ít dầu, dễ tiêu hóa.', 190, 14.0, 10.0, 10.0, 2.5, 18000, 210, 'nationwide', 15, 18, 'easy', 'breakfast,lunch', 'low_calorie', 'egg', 'steamed'),
('fd110049-1000-4000-8000-000000000049', 'Trứng ngâm tương', 'Soy-marinated eggs', 'Món sáng', 'Trứng ngâm tương có thể chuẩn bị trước nhiều phần.', 210, 14.0, 8.0, 14.0, 0.4, 18000, 150, 'nationwide', 15, 15, 'easy', 'breakfast,lunch', 'high_protein', 'egg', 'boiled'),
('fd110050-1000-4000-8000-000000000050', 'Canh cà chua trứng', 'Tomato egg soup', 'Món canh', 'Canh cà chua trứng nhẹ bụng và nhanh nấu.', 150, 10.0, 12.0, 7.0, 2.0, 15000, 320, 'nationwide', 10, 12, 'easy', 'lunch,dinner', 'low_calorie', 'egg', 'soup'),

-- 6. Vegetable dishes
('fd110051-1000-4000-8000-000000000051', 'Bông cải xanh xào tỏi', 'Garlic broccoli', 'Món rau củ', 'Bông cải xanh xào tỏi giàu chất xơ.', 145, 6.0, 16.0, 7.0, 6.0, 22000, 220, 'nationwide', 10, 10, 'easy', 'lunch,dinner', 'vegan', 'broccoli', 'stir_fry'),
('fd110052-1000-4000-8000-000000000052', 'Cải thìa xào nấm', 'Bok choy with mushrooms', 'Món rau củ', 'Cải thìa xào nấm thanh nhẹ, dễ nấu.', 135, 6.0, 15.0, 6.0, 5.0, 25000, 240, 'nationwide', 15, 12, 'easy', 'lunch,dinner', 'vegan', 'bok_choy', 'stir_fry'),
('fd110053-1000-4000-8000-000000000053', 'Cải ngọt xào thịt bò', 'Mustard greens with beef', 'Món rau củ', 'Cải ngọt xào thịt bò cân bằng rau và đạm.', 255, 23.0, 13.0, 13.0, 4.0, 42000, 260, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'balanced', 'beef', 'stir_fry'),
('fd110054-1000-4000-8000-000000000054', 'Đậu que xào thịt', 'Green beans with pork', 'Món rau củ', 'Đậu que xào thịt phù hợp cơm hộp gia đình.', 270, 19.0, 18.0, 15.0, 5.0, 35000, 260, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'balanced', 'green_beans', 'stir_fry'),
('fd110055-1000-4000-8000-000000000055', 'Bí đỏ xào tỏi', 'Garlic pumpkin stir-fry', 'Món rau củ', 'Bí đỏ xào tỏi giàu beta-carotene.', 165, 4.0, 26.0, 6.0, 4.5, 18000, 240, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'vegan', 'pumpkin', 'stir_fry'),
('fd110056-1000-4000-8000-000000000056', 'Su su xào trứng', 'Chayote stir-fried with egg', 'Món rau củ', 'Su su xào trứng nhẹ và tiết kiệm.', 190, 11.0, 17.0, 9.0, 4.0, 20000, 260, 'north', 15, 15, 'easy', 'lunch,dinner', 'vegetarian', 'chayote', 'stir_fry'),
('fd110057-1000-4000-8000-000000000057', 'Cà tím nướng mỡ hành', 'Grilled eggplant with scallion oil', 'Món rau củ', 'Cà tím nướng mỡ hành mềm thơm.', 210, 5.0, 22.0, 12.0, 6.0, 22000, 240, 'south', 15, 25, 'easy', 'lunch,dinner', 'vegetarian', 'eggplant', 'grilled'),
('fd110058-1000-4000-8000-000000000058', 'Cà tím xào thịt bằm', 'Eggplant with minced pork', 'Món rau củ', 'Cà tím xào thịt bằm mềm và đủ đạm.', 285, 18.0, 19.0, 17.0, 5.0, 35000, 260, 'nationwide', 20, 20, 'easy', 'lunch,dinner', 'balanced', 'eggplant', 'stir_fry'),
('fd110059-1000-4000-8000-000000000059', 'Khổ qua xào trứng', 'Bitter melon with egg', 'Món rau củ', 'Khổ qua xào trứng ít carb và nhanh nấu.', 195, 12.0, 12.0, 11.0, 4.0, 22000, 230, 'south', 15, 12, 'easy', 'lunch,dinner', 'low_carb', 'bitter_melon', 'stir_fry'),
('fd110060-1000-4000-8000-000000000060', 'Giá đỗ xào hẹ', 'Bean sprouts with chives', 'Món rau củ', 'Giá đỗ xào hẹ giòn nhẹ, ít năng lượng.', 120, 7.0, 15.0, 4.0, 4.0, 15000, 250, 'nationwide', 10, 8, 'easy', 'lunch,dinner', 'low_calorie', 'bean_sprouts', 'stir_fry'),

-- 7. Soups
('fd110061-1000-4000-8000-000000000061', 'Canh chua tôm', 'Vietnamese sour shrimp soup', 'Món canh', 'Canh chua tôm nhiều rau, vị chua thanh.', 190, 18.0, 20.0, 5.0, 4.0, 38000, 380, 'south', 20, 25, 'easy', 'lunch,dinner', 'low_calorie', 'shrimp', 'soup'),
('fd110062-1000-4000-8000-000000000062', 'Canh cải thịt bằm', 'Mustard green soup with minced pork', 'Món canh', 'Canh cải thịt bằm đơn giản cho bữa hằng ngày.', 175, 15.0, 10.0, 8.0, 3.0, 25000, 350, 'nationwide', 15, 18, 'easy', 'lunch,dinner', 'low_calorie', 'pork', 'soup'),
('fd110063-1000-4000-8000-000000000063', 'Canh rau ngót thịt bằm', 'Sweet leaf soup with minced pork', 'Món canh', 'Canh rau ngót thịt bằm giàu rau xanh.', 180, 16.0, 11.0, 8.0, 4.0, 28000, 350, 'nationwide', 15, 18, 'easy', 'lunch,dinner', 'low_calorie', 'pork', 'soup'),
('fd110064-1000-4000-8000-000000000064', 'Canh mồng tơi nấu tôm', 'Malabar spinach shrimp soup', 'Món canh', 'Canh mồng tơi nấu tôm thanh mát.', 155, 15.0, 10.0, 6.0, 4.0, 30000, 350, 'north', 15, 18, 'easy', 'lunch,dinner', 'low_calorie', 'shrimp', 'soup'),
('fd110065-1000-4000-8000-000000000065', 'Canh khoai mỡ', 'Purple yam soup', 'Món canh', 'Canh khoai mỡ sánh nhẹ, giàu tinh bột.', 220, 11.0, 33.0, 6.0, 4.5, 28000, 380, 'south', 20, 25, 'easy', 'lunch,dinner', 'balanced', 'purple_yam', 'soup'),
('fd110066-1000-4000-8000-000000000066', 'Canh bí đỏ hầm xương', 'Pumpkin pork bone soup', 'Món canh', 'Canh bí đỏ hầm xương ngọt tự nhiên.', 245, 18.0, 24.0, 9.0, 4.0, 35000, 400, 'nationwide', 20, 50, 'medium', 'lunch,dinner', 'balanced', 'pumpkin', 'soup'),
('fd110067-1000-4000-8000-000000000067', 'Canh khổ qua nhồi thịt', 'Stuffed bitter melon soup', 'Món canh', 'Canh khổ qua nhồi thịt đủ rau và protein.', 260, 20.0, 17.0, 13.0, 4.0, 38000, 400, 'south', 30, 45, 'medium', 'lunch,dinner', 'balanced', 'bitter_melon', 'soup'),
('fd110068-1000-4000-8000-000000000068', 'Canh rong biển thịt bò', 'Seaweed beef soup', 'Món canh', 'Canh rong biển thịt bò giàu đạm và khoáng chất.', 210, 22.0, 10.0, 9.0, 3.0, 42000, 350, 'nationwide', 15, 20, 'easy', 'lunch,dinner', 'high_protein', 'beef', 'soup'),
('fd110069-1000-4000-8000-000000000069', 'Canh nấm đậu hũ', 'Mushroom tofu soup', 'Món canh', 'Canh nấm đậu hũ thanh nhẹ dành cho bữa chay.', 170, 12.0, 15.0, 7.0, 4.0, 28000, 360, 'nationwide', 20, 20, 'easy', 'lunch,dinner', 'vegan', 'tofu', 'soup'),
('fd110070-1000-4000-8000-000000000070', 'Canh bầu nấu tôm', 'Bottle gourd shrimp soup', 'Món canh', 'Canh bầu nấu tôm ít năng lượng, dễ ăn.', 145, 15.0, 11.0, 4.0, 3.0, 30000, 360, 'nationwide', 15, 18, 'easy', 'lunch,dinner', 'low_calorie', 'shrimp', 'soup'),

-- 8. Vegetarian dishes
('fd110071-1000-4000-8000-000000000071', 'Đậu hũ kho nấm', 'Braised tofu with mushrooms', 'Món chay', 'Đậu hũ kho nấm giàu đạm thực vật.', 240, 15.0, 18.0, 13.0, 4.0, 28000, 250, 'nationwide', 20, 25, 'easy', 'lunch,dinner', 'vegan', 'tofu', 'braised'),
('fd110072-1000-4000-8000-000000000072', 'Đậu hũ chiên sả', 'Lemongrass fried tofu', 'Món chay', 'Đậu hũ chiên sả thơm, dễ chuẩn bị.', 310, 16.0, 18.0, 20.0, 3.0, 25000, 220, 'nationwide', 15, 15, 'easy', 'lunch,dinner', 'vegan', 'tofu', 'pan_fried'),
('fd110073-1000-4000-8000-000000000073', 'Đậu hũ sốt nấm', 'Tofu with mushroom sauce', 'Món chay', 'Đậu hũ sốt nấm mềm và đậm vị.', 250, 15.0, 20.0, 13.0, 4.5, 30000, 260, 'nationwide', 20, 20, 'easy', 'lunch,dinner', 'vegan', 'tofu', 'stewed'),
('fd110074-1000-4000-8000-000000000074', 'Nấm kho tiêu', 'Pepper braised mushrooms', 'Món chay', 'Nấm kho tiêu ít năng lượng, vị đậm.', 180, 8.0, 22.0, 8.0, 6.0, 30000, 230, 'nationwide', 15, 20, 'easy', 'lunch,dinner', 'vegan', 'mushroom', 'braised'),
('fd110075-1000-4000-8000-000000000075', 'Nấm xào rau củ', 'Mushroom vegetable stir-fry', 'Món chay', 'Nấm xào rau củ đa dạng chất xơ.', 190, 8.0, 24.0, 8.0, 7.0, 32000, 280, 'nationwide', 20, 15, 'easy', 'lunch,dinner', 'vegan', 'mushroom', 'stir_fry'),
('fd110076-1000-4000-8000-000000000076', 'Cà ri rau củ', 'Vegetable curry', 'Món chay', 'Cà ri rau củ dùng cùng cơm hoặc bánh mì.', 330, 9.0, 42.0, 15.0, 7.0, 35000, 320, 'south', 25, 35, 'medium', 'lunch,dinner', 'vegan', 'mixed_vegetables', 'stewed'),
('fd110077-1000-4000-8000-000000000077', 'Miến xào chay', 'Vegetarian glass noodle stir-fry', 'Món chay', 'Miến xào chay là bữa chính nhanh gọn.', 360, 10.0, 57.0, 11.0, 6.0, 32000, 300, 'nationwide', 20, 15, 'easy', 'breakfast,lunch,dinner', 'vegan', 'glass_noodle', 'stir_fry'),
('fd110078-1000-4000-8000-000000000078', 'Bún xào chay', 'Vegetarian rice noodle stir-fry', 'Món chay', 'Bún xào chay nhiều rau, phù hợp bữa nhẹ.', 340, 10.0, 55.0, 10.0, 6.0, 30000, 300, 'nationwide', 20, 15, 'easy', 'breakfast,lunch,dinner', 'vegan', 'rice_noodle', 'stir_fry'),
('fd110079-1000-4000-8000-000000000079', 'Cơm chiên nấm', 'Mushroom fried rice', 'Món chay', 'Cơm chiên nấm tận dụng cơm nguội và rau củ.', 420, 12.0, 64.0, 13.0, 5.0, 32000, 300, 'nationwide', 15, 18, 'easy', 'breakfast,lunch,dinner', 'vegetarian', 'rice', 'stir_fry'),
('fd110080-1000-4000-8000-000000000080', 'Chả giò chay', 'Vegetarian spring rolls', 'Món chay', 'Chả giò chay giòn, dùng như món chính hoặc món phụ.', 350, 9.0, 44.0, 16.0, 5.0, 30000, 220, 'south', 30, 25, 'medium', 'lunch,dinner,snack', 'vegan', 'mixed_vegetables', 'deep_fried')
)
INSERT INTO foods (
    "Id", "NameVi", "NameEn", "Category", "Description",
    "CaloriesKcal", "ProteinG", "CarbsG", "FatG", "FiberG",
    "EstimatedPriceVnd", "DefaultServingG", "ImageUrl", "IsActive", "CreatedAt", "Region",
    "PreparationMinutes", "CookingMinutes", "DifficultyLevel", "MealType",
    "DietType", "MainIngredient", "CookingMethod"
)
SELECT
    seed.id::uuid, seed.name_vi, seed.name_en, seed.category, seed.description,
    seed.calories, seed.protein, seed.carbs, seed.fat, seed.fiber,
    seed.price_vnd, seed.serving_g, NULL, true, now(), seed.region,
    seed.preparation_minutes, seed.cooking_minutes, seed.difficulty_level, seed.meal_type,
    seed.diet_type, seed.main_ingredient, seed.cooking_method
FROM seed
WHERE NOT EXISTS (
    SELECT 1
    FROM foods existing
    WHERE lower(trim(existing."NameVi")) = lower(trim(seed.name_vi))
)
ON CONFLICT ("Id") DO UPDATE SET
    "NameVi" = EXCLUDED."NameVi",
    "NameEn" = EXCLUDED."NameEn",
    "Category" = EXCLUDED."Category",
    "Description" = EXCLUDED."Description",
    "CaloriesKcal" = EXCLUDED."CaloriesKcal",
    "ProteinG" = EXCLUDED."ProteinG",
    "CarbsG" = EXCLUDED."CarbsG",
    "FatG" = EXCLUDED."FatG",
    "FiberG" = EXCLUDED."FiberG",
    "EstimatedPriceVnd" = EXCLUDED."EstimatedPriceVnd",
    "DefaultServingG" = EXCLUDED."DefaultServingG",
    "IsActive" = EXCLUDED."IsActive",
    "Region" = EXCLUDED."Region",
    "PreparationMinutes" = EXCLUDED."PreparationMinutes",
    "CookingMinutes" = EXCLUDED."CookingMinutes",
    "DifficultyLevel" = EXCLUDED."DifficultyLevel",
    "MealType" = EXCLUDED."MealType",
    "DietType" = EXCLUDED."DietType",
    "MainIngredient" = EXCLUDED."MainIngredient",
    "CookingMethod" = EXCLUDED."CookingMethod";

COMMIT;
