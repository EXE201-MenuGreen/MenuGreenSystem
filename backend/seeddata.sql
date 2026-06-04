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
--
-- Demo accounts (password for all): Demo@123
--   demo@menugreen.app  -> role Free   (free-tier demo, meal tracking ~1250 kcal today)
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
-- DELETE FROM payments WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM subscriptions WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM recommendation_feedbacks WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM recommendation_history WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM ai_messages WHERE "ConversationId" IN (SELECT "Id" FROM ai_conversations WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app'));
-- DELETE FROM ai_conversations WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM meal_plan_items WHERE "MealPlanId" IN (SELECT "Id" FROM meal_plan_headers WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app'));
-- DELETE FROM meal_plan_headers WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM nutrition_snapshots WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
-- DELETE FROM meal_logs WHERE "UserId" IN (SELECT "Id" FROM users WHERE "Email" LIKE '%@menugreen.app');
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
-- Meal logs (demo user today — total 1250 kcal vs target 1954)
-- =========================
INSERT INTO meal_logs (
  "Id","UserId","FoodId","RecipeId","MealType","QuantityG",
  "CaloriesKcal","ProteinG","CarbsG","FatG","SourceType","Notes","LoggedAt"
)
VALUES
  (
    '90000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000005',
    NULL,
    'Breakfast', 280,
    330, 12, 48, 8, 'manual', 'Yến mạch sữa chua',
    date_trunc('day', now()) + interval '7 hours 30 minutes'
  ),
  (
    '90000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    'Lunch', 350,
    450, 40, 20, 18, 'manual', 'Salad ức gà - bữa trưa đề xuất',
    date_trunc('day', now()) + interval '12 hours'
  ),
  (
    '90000000-0000-0000-0000-000000000003',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    'Snack', 300,
    220, 8, 22, 10, 'manual', 'Smoothie bơ hạt',
    date_trunc('day', now()) + interval '15 hours'
  ),
  (
    '90000000-0000-0000-0000-000000000004',
    '70000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000004',
    NULL,
    'Dinner', 300,
    250, 14, 18, 12, 'manual', 'Salad đậu hũ nhẹ',
    date_trunc('day', now()) + interval '18 hours 30 minutes'
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Nutrition snapshot (today — aligned with meal_logs totals)
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
-- Notification settings (unique per UserId)
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

-- =========================
-- Meal plan (demo user — sample week)
-- =========================
INSERT INTO meal_plan_headers (
  "Id","UserId","Title","PlanType","StartDate","EndDate",
  "TargetCalories","GeneratedBy","IsActive","CreatedAt","UpdatedAt"
)
VALUES
  (
    'e0000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'Kế hoạch ăn tuần demo',
    'weekly',
    CURRENT_DATE,
    CURRENT_DATE + 6,
    1954, 'manual', true, now(), now()
  )
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO meal_plan_items (
  "Id","MealPlanId","MealType","FoodId","RecipeId","PlannedDate",
  "TargetCalories","IsCompleted","CreatedAt"
)
VALUES
  (
    'f0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001',
    'Lunch',
    '40000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    CURRENT_DATE,
    450, true, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000002',
    'e0000000-0000-0000-0000-000000000001',
    'Snack',
    '40000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    CURRENT_DATE,
    220, false, now()
  ),
  (
    'f0000000-0000-0000-0000-000000000003',
    'e0000000-0000-0000-0000-000000000001',
    'Dinner',
    '40000000-0000-0000-0000-000000000006',
    NULL,
    CURRENT_DATE + 1,
    420, false, now()
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
