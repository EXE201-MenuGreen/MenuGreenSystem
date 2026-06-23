-- =============================================================================
-- MenuGreen - PostgreSQL seed data (pgAdmin / Render SQL shell / psql)
-- =============================================================================
-- Prerequisites:
--   1. Database created (local MenuGreenDb or Render menugreendb)
--   2. Schema from EF migration (NOT this file):
--        cd backend
--        dotnet ef database update --project MenuGreen.DataAccessLayer --startup-project MenuGreen.API
--   3. If Render DB has old partial schema, reset first: backend/reset_database.sql
--      then run database update again, then run this seed file.
--   4. If DB predates Premium Program feature, run first:
--        backend/fix_premium_program_schema.sql
--
-- Demo accounts (password for all): Demo@123
--   demo@menugreen.app  -> role Free   (free-tier demo, meal tracking ~1250 kcal today + DAILY meal plan)
--   pro@menugreen.app   -> role Pro    (active yearly subscription + transaction history)
--   admin@menugreen.app -> role Admin  (admin web panel)
--
-- Health profile values use API/Flutter canonical strings:
--   ActivityLevel: sedentary | lightly active | moderately active | very active
--   Goal: lose weight | maintain weight | gain weight | build muscle
--
-- Safe to re-run: fixed UUIDs + ON CONFLICT DO NOTHING
-- To reset demo user data only, uncomment the DELETE block below.
-- =============================================================================

-- DELETE FROM subscription_transactions WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM user_subscriptions WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM sepay_transactions WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM user_program_milestones WHERE "UserProgramId" IN (SELECT "Id" FROM user_premium_programs WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app'));
-- DELETE FROM user_premium_programs WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM payments WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM premium_programs WHERE "Id" NOT IN ('f1000000-0000-0000-0000-000000000001','f1000000-0000-0000-0000-000000000002');
-- DELETE FROM subscriptions WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM recommendation_feedbacks WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM recommendation_history WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM ai_messages WHERE "ConversationId" IN (SELECT "Id" FROM ai_conversations WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app'));
-- DELETE FROM ai_conversations WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM meal_logs WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM meal_plan_items WHERE "MealPlanId" IN (SELECT "Id" FROM meal_plan_headers WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app') OR "UserId" = '00000000-0000-0000-0000-000000000000');
-- DELETE FROM meal_plan_headers WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app') OR "UserId" = '00000000-0000-0000-0000-000000000000';
-- DELETE FROM nutrition_snapshots WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM weight_logs WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM favorite_foods WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM food_allergies WHERE "FoodId" IN (SELECT "Id" FROM foods WHERE "Id"::text LIKE '40000000%')
--   OR "AllergyId" IN ('20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000003');
-- DELETE FROM user_allergies WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM allergies WHERE "Id" IN ('20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000003');
-- DELETE FROM recipe_ingredients WHERE "RecipeId" IN (SELECT "Id" FROM recipes);
-- DELETE FROM recipes;
-- DELETE FROM "NotificationSettings" WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM "Notifications" WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM activity_logs WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM budget_requests WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM user_ai_profile WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM email_verifications WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM password_reset_tokens WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM sessions WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM health_profiles WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM profiles WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM users WHERE "Email" LIKE '%@menugreen.app';
-- (reference tables: foods, ingredients, subscription_plans, roles are kept)

BEGIN;

-- BCrypt hash for password: Demo@123 (BCrypt.Net-Next compatible)

-- =========================
-- Roles
-- =========================
INSERT INTO roles ("Id", "Name", "Description", "CreatedAt", "UpdatedAt")
VALUES
  ('00000000-0000-0000-0000-000000000001', 'Free',  'Gói miễn phí', now(), now()),
  ('00000000-0000-0000-0000-000000000002', 'Pro',   'Gói Pro / Premium', now(), now()),
  ('00000000-0000-0000-0000-000000000003', 'User',  'Standard user (auto-created on register)', now(), now()),
  ('00000000-0000-0000-0000-000000000004', 'Admin', 'Quản trị hệ thống', now(), now())
ON CONFLICT ("Name") DO NOTHING;

-- =========================
-- Subscription plans (matches Upgrade Plan UI)
-- =========================
INSERT INTO subscription_plans ("Id", "Name", "Description", "DurationDays", "PriceVnd", "FeatureGroup", "IsActive")
VALUES
  (
    '10000000-0000-0000-0000-000000000001',
    'Cơ bản',
    'Quản lý thực đơn cơ bản, tính calo theo chuẩn',
    NULL, 0, 'basic', true
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Pro Tháng/GYM',
    'Thực đơn nâng cao, phân tích dinh dưỡng, hỗ trợ AI 24/7',
    30, 99000, 'pro', true
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'Pro Năm',
    'Tất cả tính năng Pro, tiết kiệm 20%, offline, xuất PDF',
    365, 790000, 'pro', true
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Ingredients
-- =========================
INSERT INTO ingredients (
  "Id","NameVi","NameEn","Category","CaloriesKcal","ProteinG","CarbsG","FatG",
  "EstimatedPriceVnd","UnitDefault","ImageUrl","IsActive","CreatedAt"
)
VALUES
  ('30000000-0000-0000-0000-000000000001','Ức gà','Chicken breast','Protein',165,31,0,3.6,35000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000002','Xà lách','Lettuce','Vegetable',15,1.4,2.9,0.2,12000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000003','Cà chua','Tomato','Vegetable',18,0.9,3.9,0.2,10000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000004','Dầu olive','Olive oil','Fat',884,0,0,100,70000,'ml',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000005','Chanh','Lime','Fruit',30,0.7,10.5,0.2,8000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000006','Bơ','Avocado','Fruit',160,2,9,15,25000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000007','Chuối','Banana','Fruit',89,1.1,23,0.3,8000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000008','Gạo lứt','Brown rice','Carb',111,2.6,23,0.9,15000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000009','Đậu hũ','Tofu','Protein',76,8,1.9,4.8,12000,'g',NULL,true,now()),
  ('30000000-0000-0000-0000-000000000010','Bơ đậu phộng','Peanut butter','Fat',588,25,20,50,45000,'g',NULL,true,now())
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Foods (aligned with Home screen cards)
-- =========================
INSERT INTO foods (
  "Id","NameVi","NameEn","Category","Description",
  "CaloriesKcal","ProteinG","CarbsG","FatG","FiberG",
  "EstimatedPriceVnd","DefaultServingG","ImageUrl","IsActive","CreatedAt"
)
VALUES
  (
    '40000000-0000-0000-0000-000000000001',
    'Salad Ức Gà Áp Chảo','Pan-seared Chicken Salad','Salad',
    'Giàu protein chất lượng cao và chất xơ tự nhiên, giúp duy trì năng lượng suốt buổi chiều.',
    450,40,20,18,6,65000,350,NULL,true,now()
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    'Smoothie Bơ Hạt','Nut Butter Smoothie','Snack',
    'Bữa phụ nhanh, năng lượng vừa phải.',
    220,8,22,10,4,30000,300,NULL,true,now()
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    'Poke Chay Cầu Vồng','Rainbow Veggie Poke','Ăn chay',
    'Bát poke chay đủ màu, giàu vitamin và chất xơ.',
    380,12,55,12,8,55000,400,NULL,true,now()
  ),
  (
    '40000000-0000-0000-0000-000000000004',
    'Salad Đậu Hũ','Tofu Salad','Thuần chay',
    'Salad nhẹ, phù hợp bữa tối thanh đạm.',
    250,14,18,12,5,40000,300,NULL,true,now()
  ),
  (
    '40000000-0000-0000-0000-000000000005',
    'Yến mạch sữa chua','Yogurt Oats Bowl','Bữa sáng',
    'Bữa sáng giàu carb chậm và protein.',
    330,12,48,8,6,25000,280,NULL,true,now()
  ),
  (
    '40000000-0000-0000-0000-000000000006',
    'Phở bò tái','Beef Pho','Món Việt',
    'Món Việt phổ biến, phù hợp bữa trưa nhanh.',
    420,28,52,10,3,45000,500,NULL,true,now()
  ),
  (
    '40000000-0000-0000-0000-000000000007',
    'Cơm gà Hải Nam','Hainanese Chicken Rice','Món Việt',
    'Cơm gà đầy đủ năng lượng cho ngày tập luyện.',
    520,32,58,16,2,55000,450,NULL,true,now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Recipes
-- =========================
INSERT INTO recipes (
  "Id","FoodId","Title","Description",
  "PrepTimeMin","CookTimeMin","TotalTimeMin","Servings",
  "Difficulty","MealType","EstimatedPriceVnd",
  "Instructions","ImageUrl","VideoUrl","IsActive","CreatedAt"
)
VALUES
  (
    '50000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'Salad Ức Gà Áp Chảo',
    'Salad giàu protein với sốt chanh dầu olive.',
    10,10,20,1,'Easy','Lunch',65000,
    '["Ướp ức gà với muối/tiêu.","Áp chảo 2 mặt đến chín.","Trộn rau + cà chua.","Pha sốt dầu olive + chanh, rưới lên salad."]'::json,
    NULL,NULL,true,now()
  ),
  (
    '50000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000002',
    'Smoothie Bơ Hạt',
    'Smoothie bơ chuối bổ sung năng lượng buổi sáng hoặc bữa phụ.',
    5,0,5,1,'Easy','Snack',30000,
    '["Cho bơ, chuối, bơ đậu phộng vào máy xay.","Xay mịn, thêm đá nếu thích.","Đổ ra ly và dùng ngay."]'::json,
    NULL,NULL,true,now()
  ),
  (
    '50000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000003',
    'Poke Chay Cầu Vồng',
    'Poke bowl chay với gạo lứt và rau củ.',
    15,0,15,1,'Easy','Lunch',55000,
    '["Nấu gạo lứt.","Thái rau củ và đậu hũ.","Xếp lớp vào bát, rưới sốt tương ớt hoặc tương hột."]'::json,
    NULL,NULL,true,now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Recipe ingredients
-- =========================
INSERT INTO recipe_ingredients ("Id","RecipeId","IngredientId","Quantity","Unit","Notes")
VALUES
  ('60000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',200,'g','Ức gà bỏ da'),
  ('60000000-0000-0000-0000-000000000002','50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002',120,'g',NULL),
  ('60000000-0000-0000-0000-000000000003','50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000003',80,'g',NULL),
  ('60000000-0000-0000-0000-000000000004','50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000004',15,'ml','Dùng làm sốt'),
  ('60000000-0000-0000-0000-000000000005','50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000005',10,'g','Vắt lấy nước'),
  ('60000000-0000-0000-0000-000000000006','50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000006',80,'g',NULL),
  ('60000000-0000-0000-0000-000000000007','50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000007',100,'g',NULL),
  ('60000000-0000-0000-0000-000000000008','50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000010',20,'g',NULL),
  ('60000000-0000-0000-0000-000000000009','50000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000008',150,'g','Gạo lứt'),
  ('60000000-0000-0000-0000-000000000010','50000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000009',120,'g',NULL)
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Demo users (password: Demo@123)
-- =========================
INSERT INTO users (
  "Id","RoleId","Email","PasswordHash",
  "EmailConfirmed","IsActive","LastSignInAt","CreatedAt","UpdatedAt","DeletedAt"
)
VALUES
  (
    '70000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'demo@menugreen.app',
    '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey',
    true, true, now(), now() - interval '2 days', now(), NULL
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000002',
    'pro@menugreen.app',
    '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey',
    true, true, now(), now() - interval '30 days', now(), NULL
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000004',
    'admin@menugreen.app',
    '$2b$12$zcokeEBiEkl4iukyN0j6nev0lINFlC8ol8dje1O/JfY2yOHM0arey',
    true, true, now(), now() - interval '1 day', now(), NULL
  )
ON CONFLICT ("Email") DO NOTHING;

-- =========================
-- Profiles
-- =========================
INSERT INTO profiles (
  "UserId","FullName","AvatarUrl","DateOfBirth","Gender","PreferredCuisine",
  "CreatedAt","UpdatedAt"
)
VALUES
  (
    '70000000-0000-0000-0000-000000000001',
    'Minh Demo',
    'https://i.pravatar.cc/150?img=5',
    '1998-05-15',
    'Male',
    'Việt Nam',
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    'Lan Pro',
    'https://i.pravatar.cc/150?img=11',
    '1996-08-20',
    'Female',
    'Healthy / Gym',
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    'Admin MenuGreen',
    'https://i.pravatar.cc/150?img=3',
    '1990-01-01',
    'Male',
    NULL,
    now(), now()
  )
ON CONFLICT ("UserId") DO NOTHING;

-- =========================
-- Health profiles (canonical ActivityLevel / Goal for API + Flutter)
-- =========================
INSERT INTO health_profiles (
  "UserId","HeightCm","WeightKg","BodyFatPercent","ActivityLevel","Goal",
  "Bmi","BmrKcal","TdeeKcal","TargetCalories","TargetProteinG","TargetCarbsG","TargetFatG",
  "CreatedAt","UpdatedAt"
)
VALUES
  (
    '70000000-0000-0000-0000-000000000001',
    170.00, 65.00, 18.00, 'moderately active', 'lose weight',
    22.49, 1583, 2454, 1954, 146, 195, 65,
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    165.00, 58.00, 22.00, 'very active', 'maintain weight',
    21.30, 1420, 2449, 2449, 183, 245, 82,
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    175.00, 72.00, NULL, 'lightly active', 'maintain weight',
    23.51, 1680, 2306, 2306, 173, 231, 77,
    now(), now()
  )
ON CONFLICT ("UserId") DO NOTHING;

-- =========================
-- Allergies (AllergyService / GET api/allergy)
-- =========================
INSERT INTO allergies ("Id", "UserId", "Name", "Notes", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
  (
    '20000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'Peanut',
    'Dị ứng đậu phộng',
    true, now(), now()
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000001',
    'Lactose',
    'Không dung nạp lactose / sản phẩm từ sữa',
    true, now(), now()
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '70000000-0000-0000-0000-000000000002',
    'Lactose',
    'Không dung nạp lactose / sản phẩm từ sữa',
    true, now(), now()
  )
ON CONFLICT ("UserId", "Name") DO NOTHING;

-- =========================
-- Food allergies (Smoothie Bơ Hạt — peanut + lactose for demo user)
-- =========================
INSERT INTO food_allergies ("FoodId", "AllergyId")
VALUES
  ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001'),
  ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002')
ON CONFLICT ("FoodId", "AllergyId") DO NOTHING;

CREATE TABLE IF NOT EXISTS food_allergen_tags (
    "FoodId" uuid NOT NULL,
    "AllergenKey" character varying(64) NOT NULL,
    CONSTRAINT "PK_food_allergen_tags" PRIMARY KEY ("FoodId", "AllergenKey"),
    CONSTRAINT "FK_food_allergen_tags_foods_FoodId" FOREIGN KEY ("FoodId")
        REFERENCES foods ("Id") ON DELETE CASCADE
);

INSERT INTO food_allergen_tags ("FoodId", "AllergenKey")
VALUES
  ('40000000-0000-0000-0000-000000000002', 'peanut'),
  ('40000000-0000-0000-0000-000000000002', 'dairy')
ON CONFLICT ("FoodId", "AllergenKey") DO NOTHING;

-- =========================
-- Premium Programs (lộ trình dinh dưỡng có phí)
-- =========================
INSERT INTO premium_programs (
  "Id","Title","Description","DurationWeeks","TargetCaloriesDaily",
  "GoalType","PriceVnd","SampleMenu","IsActive","CreatedAt"
)
VALUES
  (
    'f1000000-0000-0000-0000-000000000001',
    'Chương trình Siết Cơ Giảm Mỡ 8 Tuần',
    'Chương trình luyện tập và dinh dưỡng cường độ cao dành cho người muốn giảm mỡ hiệu quả trong 8 tuần.',
    8, 1600, 'LoseWeight', 299000,
    'Ức gà áp chảo | Sinh tố bơ chuối | Gạo lứt thịt bò thăn',
    true, now()
  ),
  (
    'f1000000-0000-0000-0000-000000000002',
    'Ăn Sạch Sống Khỏe 12 Tuần',
    'Học cách thiết lập thói quen ăn uống lành mạnh tự nhiên không áp lực.',
    12, 1800, 'HealthyEating', 399000,
    'Yến mạch ngâm sữa chua | Đậu hũ sốt cà chua | Cá hồi nướng súp lơ',
    true, now()
  ),
  (
    'f1000000-0000-0000-0000-000000000003',
    'Lộ trình tăng cơ 12 tuần (Muscle Building Accelerator)',
    'Lộ trình giàu protein chất lượng cao và carb phức hợp giúp tối ưu hóa quá trình phục hồi, phát triển cơ bắp tối đa và nâng cao thể lực tập luyện.',
    12, 2500, 'GainMuscle', 499000,
    'Bữa sáng: 3 trứng ốp la, 2 lát bánh mì đen và quả bơ | Bữa trưa: Bò lúc lắc ăn kèm cơm gạo lứt | Bữa tối: Tôm áp chảo sốt bơ tỏi và khoai lang luộc',
    true, now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- User Premium Programs (đăng ký chương trình của user)
-- =========================
INSERT INTO user_premium_programs (
  "Id","UserId","ProgramId","StartDate","Status","CurrentWeek","CreatedAt","UpdatedAt"
)
VALUES
  (
    'f2000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000002',
    'f1000000-0000-0000-0000-000000000001',
    CURRENT_DATE - 10,
    'Active',
    2,
    now(), now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- User Program Milestones (cột mốc tuần của user_premium_programs)
-- =========================
INSERT INTO user_program_milestones (
  "Id","UserProgramId","WeekNumber","IsUnlocked","IsCheckedIn",
  "WeightKg","BodyFatPercent","UnlockedAt","CheckedInDate","CreatedAt"
)
VALUES
  (
    'f3000000-0000-0000-0000-000000000001',
    'f2000000-0000-0000-0000-000000000001',
    1, true, true, 58.5, 22.5,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  ),
  (
    'f3000000-0000-0000-0000-000000000002',
    'f2000000-0000-0000-0000-000000000001',
    2, true, false, NULL, NULL,
    now() - interval '7 days',
    NULL,
    now() - interval '7 days'
  ),
  (
    'f3000000-0000-0000-0000-000000000003',
    'f2000000-0000-0000-0000-000000000001',
    3, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000004',
    'f2000000-0000-0000-0000-000000000001',
    4, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000005',
    'f2000000-0000-0000-0000-000000000001',
    5, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000006',
    'f2000000-0000-0000-0000-000000000001',
    6, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000007',
    'f2000000-0000-0000-0000-000000000001',
    7, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000008',
    'f2000000-0000-0000-0000-000000000001',
    8, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000009',
    'f2000000-0000-0000-0000-000000000001',
    9, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000010',
    'f2000000-0000-0000-0000-000000000001',
    10, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000011',
    'f2000000-0000-0000-0000-000000000001',
    11, false, false, NULL, NULL, NULL, NULL, now()
  ),
  (
    'f3000000-0000-0000-0000-000000000012',
    'f2000000-0000-0000-0000-000000000001',
    12, false, false, NULL, NULL, NULL, NULL, now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- User subscriptions (Pro user — UserSubscriptionService)
-- =========================
INSERT INTO user_subscriptions (
  "Id", "UserId", "SubscriptionPlanId", "Status",
  "StartDate", "EndDate", "CancelledAt", "RenewedAt",
  "CreatedAt", "UpdatedAt"
)
VALUES
  (
    '80000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003',
    'Active',
    now() - interval '60 days',
    '2026-12-31 23:59:59+00'::timestamptz,
    NULL,
    now() - interval '60 days',
    now() - interval '60 days',
    now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Subscription transactions (Upgrade Plan history tab)
-- =========================
INSERT INTO subscription_transactions (
  "Id", "UserId", "UserSubscriptionId", "TransactionType",
  "Amount", "Status", "Note", "TransactionDate", "CreatedAt"
)
VALUES
  (
    '81000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000002',
    '80000000-0000-0000-0000-000000000001',
    'Subscribe',
    790000,
    'Success',
    'Đăng ký gói Pro Năm (demo seed)',
    now() - interval '60 days',
    now() - interval '60 days'
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Payments (Subscription payments — Pro user)
-- NOTE: UserPremiumProgramId column is included for Premium Program payment flow
-- =========================
INSERT INTO payments (
  "Id", "UserId", "UserSubscriptionId", "UserPremiumProgramId",
  "AmountVnd", "Status", "PaymentMethod", "Provider", "ProviderOrderCode",
  "CreatedAt", "UpdatedAt", "ExpiredAt", "PaidAt"
)
VALUES
  (
    '76378876-43df-47db-88d1-1bee4c82077d',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '97f4a742-cc44-4ab0-b2f4-bc260c245cdf',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_76378876',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    '17605d97-f2f4-422b-90cc-4999a5f1fec0',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '5091b2d7-a9e8-41ca-ad18-407bcee846f5',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_17605d97',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    '0e6db154-5c4f-435a-95e3-937ef4092015',
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    '5e31bbfb-1c4c-4dde-9682-41c8b22a9418',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_0e6db154',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    '856a1f59-b430-4386-b3c9-ba5bd1ddbdd3',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    '00e3373b-a66f-4ae4-acf1-873d4f21e735',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_856a1f59',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'f30d1b92-6926-433f-b4c8-d2cbfd559dc6',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '5a589d0c-0879-4211-bcde-b80d8f872a2c',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_f30d1b92',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'ca3479ca-26f1-44db-a245-80371e7e2ce1',
    '885810e8-168f-4608-a72e-e23a20dfd258',
    '77332cff-478c-4926-9dc4-6fd86c688d88',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_ca3479ca',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'b771fc44-c0d1-4175-af76-49e5ff5d64fb',
    '48069bd5-f29a-417d-bdeb-c00797968aca',
    '4cb9db51-734f-4710-8500-9cd449938d3c',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_b771fc44',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'e2ae9d11-6e00-4f88-9b37-a5f5d3c0d5df',
    '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70',
    'ca5ba96d-0c13-457f-9833-439817647424',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_e2ae9d11',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    '9236bd02-6f32-44b1-80a6-df311178ea2b',
    '081b4669-b97f-4e75-b089-4c8de0151653',
    '7158db3e-9416-463a-9158-c5cbdf0aa202',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_9236bd02',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'cca940d2-f4ad-432b-b6b2-99c504fb71f5',
    '586209d0-d3c4-43a4-bba7-5d4c73b37bc1',
    '137a2257-8c0b-4b56-b4fa-be8da55e7c14',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_cca940d2',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'ee658c09-f558-4414-a659-c113b55f4125',
    'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17',
    '4833465b-1140-4a40-b7cd-114acaabae31',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_ee658c09',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'aeb230f1-5560-4e4d-b462-4c704843cdb7',
    '453681f7-f489-47ed-842c-bc3ffd220423',
    '41837cb8-7232-444c-be01-417e376de8c0',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_aeb230f1',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    '5cf0a99a-134f-45a1-9fae-55dee3227308',
    '396f9dff-6c2a-422f-b0cc-8eb451168ed3',
    '26a8241f-a665-45c8-a083-aba9bfa8c008',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_5cf0a99a',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    '482b0243-65d5-4eae-adf6-5b5b04452fd7',
    '5dc50160-db9e-447a-ba33-9026d8800ab5',
    '6a54cb24-29ae-49ce-b950-628c76f85fb3',
    NULL,
    99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_482b0243',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  ),
  (
    'a8bccf2c-d4cb-4a4b-b6d2-7713d38ca525',
    '212ea8ea-749e-44a1-92d2-636bd617cbc8',
    'acbfd092-bc85-4b14-b509-d2da7f969903',
    NULL,
    790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_a8bccf2c',
    now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Favorite foods
-- =========================
INSERT INTO favorite_foods ("UserId", "FoodId", "CreatedAt")
VALUES
  ('70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001', now()),
  ('70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002', now()),
  ('70000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001', now()),
  ('70000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000007', now())
ON CONFLICT ("UserId", "FoodId") DO NOTHING;

-- =========================
-- Meal plans (admin template + demo user DAILY for today)
-- =========================

-- Admin web: mẫu thực đơn (UserId empty = template)
INSERT INTO meal_plan_headers (
  "Id","UserId","Title","PlanType","StartDate","EndDate",
  "TargetCalories","GeneratedBy","IsActive","CreatedAt","UpdatedAt"
)
VALUES
  (
    'e0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'Mẫu thực đơn tuần (admin)',
    'WEEKLY',
    CURRENT_DATE,
    CURRENT_DATE + 6,
    1954, 'ADMIN', true, now(), now()
  )
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO meal_plan_items (
  "Id","MealPlanId","MealType","FoodId","RecipeId","PlannedDate",
  "ScheduledTime","TargetCalories","IsCompleted","CreatedAt"
)
VALUES
  (
    'f0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001',
    'lunch',
    NULL,
    '50000000-0000-0000-0000-000000000001',
    CURRENT_DATE,
    '12:00', 450, false, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000002',
    'e0000000-0000-0000-0000-000000000001',
    'snack',
    NULL,
    '50000000-0000-0000-0000-000000000002',
    CURRENT_DATE,
    '15:00', 220, false, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000003',
    'e0000000-0000-0000-0000-000000000001',
    'dinner',
    '40000000-0000-0000-0000-000000000006',
    NULL,
    CURRENT_DATE + 1,
    '18:30', 420, false, now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- demo@menugreen.app: kế hoạch DAILY hôm nay
INSERT INTO meal_plan_headers (
  "Id","UserId","Title","PlanType","StartDate","EndDate",
  "TargetCalories","GeneratedBy","IsActive","CreatedAt","UpdatedAt"
)
VALUES
  (
    'e0000000-0000-0000-0000-000000000010',
    '70000000-0000-0000-0000-000000000001',
    'Kế hoạch ăn hôm nay (demo)',
    'DAILY',
    CURRENT_DATE,
    CURRENT_DATE,
    1954, 'USER', true, now(), now()
  )
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO meal_plan_items (
  "Id","MealPlanId","MealType","FoodId","RecipeId","PlannedDate",
  "ScheduledTime","TargetCalories","IsCompleted","CreatedAt"
)
VALUES
  (
    'f0000000-0000-0000-0000-000000000010',
    'e0000000-0000-0000-0000-000000000010',
    'breakfast',
    '40000000-0000-0000-0000-000000000005',
    NULL,
    CURRENT_DATE,
    '07:30', 330, true, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000011',
    'e0000000-0000-0000-0000-000000000010',
    'lunch',
    NULL,
    '50000000-0000-0000-0000-000000000001',
    CURRENT_DATE,
    '12:00', 450, true, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000012',
    'e0000000-0000-0000-0000-000000000010',
    'snack',
    NULL,
    '50000000-0000-0000-0000-000000000002',
    CURRENT_DATE,
    '15:00', 220, false, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000013',
    'e0000000-0000-0000-0000-000000000010',
    'dinner',
    '40000000-0000-0000-0000-000000000004',
    NULL,
    CURRENT_DATE,
    '18:30', 250, false, now()
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Meal logs (demo user today — total 1250 kcal vs target 1954)
-- =========================
INSERT INTO meal_logs (
  "Id","UserId","FoodId","RecipeId","MealType","QuantityG",
  "CaloriesKcal","ProteinG","CarbsG","FatG","SourceType","Notes","LoggedAt",
  "MealPlanItemId","IsFromMealPlan"
)
VALUES
  (
    '90000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000005',
    NULL,
    'breakfast', 280,
    330, 12, 48, 8, 'Food', 'Logged from meal plan.',
    date_trunc('day', now()) + interval '7 hours 30 minutes',
    'f0000000-0000-0000-0000-000000000010', true
  ),
  (
    '90000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000001',
    NULL,
    '50000000-0000-0000-0000-000000000001',
    'lunch', 350,
    450, 40, 20, 18, 'Recipe', 'Logged from meal plan.',
    date_trunc('day', now()) + interval '12 hours',
    'f0000000-0000-0000-0000-000000000011', true
  ),
  (
    '90000000-0000-0000-0000-000000000003',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000002',
    NULL,
    'snack', 300,
    220, 8, 22, 10, 'Food', 'Smoothie bơ hạt (manual log)',
    date_trunc('day', now()) + interval '15 hours',
    NULL, false
  ),
  (
    '90000000-0000-0000-0000-000000000004',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000004',
    NULL,
    'dinner', 300,
    250, 14, 18, 12, 'Food', 'Salad đậu hũ nhẹ (manual log)',
    date_trunc('day', now()) + interval '18 hours 30 minutes',
    NULL, false
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Nutrition snapshot (today)
-- =========================
INSERT INTO nutrition_snapshots (
  "Id","UserId","SnapshotDate",
  "TotalCalories","TotalProteinG","TotalCarbsG","TotalFatG","GoalCompletionPercent"
)
VALUES
  (
    'a0000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    CURRENT_DATE,
    1250, 74, 108, 48, 64.0
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000002',
    CURRENT_DATE,
    980, 55, 110, 32, 40.0
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Weight logs
-- =========================
INSERT INTO weight_logs ("Id", "UserId", "WeightKg", "BodyFatPercent", "RecordedAt")
VALUES
  ('c0000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001', 66.2, 19.0, now() - interval '14 days'),
  ('c0000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001', 65.0, 18.0, now() - interval '7 days'),
  ('c0000000-0000-0000-0000-000000000003','70000000-0000-0000-0000-000000000002', 58.5, 22.5, now() - interval '7 days')
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Notification settings
-- =========================
INSERT INTO "NotificationSettings" (
  "Id", "UserId",
  "MealReminderEnabled", "MealReminderOffsetMinutes",
  "PrepReminderEnabled", "PrepReminderOffsetMinutes",
  "InAppEnabled", "PushEnabled",
  "CreatedAt", "UpdatedAt"
)
VALUES
  (
    '11000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    true, 30, true, 20, true, false, now(), now()
  ),
  (
    '11000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000002',
    true, 30, true, 20, true, false, now(), now()
  ),
  (
    '11000000-0000-0000-0000-000000000003',
    '70000000-0000-0000-0000-000000000003',
    true, 30, false, 20, true, false, now(), now()
  )
ON CONFLICT ("UserId") DO NOTHING;

-- =========================
-- Notifications
-- =========================
INSERT INTO "Notifications" ("Id", "UserId", "Title", "Body", "Type", "IsRead", "CreatedAt")
VALUES
  (
    'd0000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'Chào buổi sáng!',
    'Bạn còn khoảng 704 kcal cho hôm nay. Thử Salad ức gà cho bữa trưa nhé.',
    'reminder', false, now() - interval '2 hours'
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000002',
    'Gói Pro đang hoạt động',
    'Gói Pro Năm của bạn có hiệu lực đến 31/12/2026.',
    'subscription', true, now() - interval '1 day'
  )
ON CONFLICT ("Id") DO NOTHING;

COMMIT;

-- =========================
-- Quick verification (optional — run after COMMIT)
-- =========================
-- SELECT u."Email", r."Name" AS role, p."FullName", hp."TargetCalories", hp."ActivityLevel", hp."Goal"
-- FROM users u
-- JOIN roles r ON r."Id" = u."RoleId"
-- LEFT JOIN profiles p ON p."UserId" = u."Id"
-- LEFT JOIN health_profiles hp ON hp."UserId" = u."Id"
-- WHERE u."Email" LIKE '%@menugreen.app';
--
-- SELECT us."Status", sp."Name", st."TransactionType", st."Amount"
-- FROM user_subscriptions us
-- JOIN subscription_plans sp ON sp."Id" = us."SubscriptionPlanId"
-- LEFT JOIN subscription_transactions st ON st."UserSubscriptionId" = us."Id"
-- WHERE us."UserId" = '70000000-0000-0000-0000-000000000002';
--
-- SELECT pp."Title", upp."Status", upp."CurrentWeek", pm."WeekNumber", pm."IsUnlocked", pm."IsCheckedIn"
-- FROM user_premium_programs upp
-- JOIN premium_programs pp ON pp."Id" = upp."ProgramId"
-- LEFT JOIN user_program_milestones pm ON pm."UserProgramId" = upp."Id"
-- WHERE upp."UserId" = '70000000-0000-0000-0000-000000000002';
--
-- SELECT h."Title", h."PlanType", h."StartDate", i."MealType", i."IsCompleted", i."ScheduledTime"
-- FROM meal_plan_headers h
-- JOIN meal_plan_items i ON i."MealPlanId" = h."Id"
-- WHERE h."UserId" = '70000000-0000-0000-0000-000000000001' AND h."PlanType" = 'DAILY';
--
-- SELECT ml."MealType", ml."IsFromMealPlan", ml."MealPlanItemId", ml."CaloriesKcal"
-- FROM meal_logs ml
-- WHERE ml."UserId" = '70000000-0000-0000-0000-000000000001'
--   AND ml."LoggedAt"::date = CURRENT_DATE;
