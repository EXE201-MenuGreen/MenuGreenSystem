-- =============================================================================
-- MenuGreen - PostgreSQL seed data (pgAdmin / psql)
-- =============================================================================
-- Prerequisites:
--   1. Database: MenuGreenDb
--   2. EF migration applied (tables exist)
--
-- Demo accounts (password for all): Demo@123
--   demo@menugreen.app  -> role Free  (basic user)
--   pro@menugreen.app   -> role Pro   (active yearly subscription)
--   admin@menugreen.app -> role Admin
--
-- Safe to re-run: fixed UUIDs + ON CONFLICT DO NOTHING
-- To reset demo data only, uncomment the DELETE block below.
-- =============================================================================

-- DELETE FROM sepay_transactions;
-- DELETE FROM payments;
-- DELETE FROM subscriptions;
-- DELETE FROM recommendation_feedbacks;
-- DELETE FROM recommendation_history;
-- DELETE FROM ai_messages;
-- DELETE FROM ai_conversations;
-- DELETE FROM meal_plan_items;
-- DELETE FROM meal_plan_headers;
-- DELETE FROM nutrition_snapshots;
-- DELETE FROM meal_logs;
-- DELETE FROM water_logs;
-- DELETE FROM weight_logs;
-- DELETE FROM favorite_foods;
-- DELETE FROM user_allergies;
-- DELETE FROM food_allergies;
-- DELETE FROM recipe_ingredients;
-- DELETE FROM recipes;
-- DELETE FROM fridge_items;
-- DELETE FROM notifications;
-- DELETE FROM activity_logs;
-- DELETE FROM budget_requests;
-- DELETE FROM user_ai_profile;
-- DELETE FROM email_verifications;
-- DELETE FROM password_reset_tokens;
-- DELETE FROM sessions;
-- DELETE FROM health_profiles;
-- DELETE FROM profiles;
-- DELETE FROM users WHERE "Email" LIKE '%@menugreen.app';
-- (reference tables: allergies, foods, ingredients, subscription_plans, roles are kept)

BEGIN;

-- BCrypt hash for password: Demo@123
-- Generated with BCrypt (compatible with BCrypt.Net-Next in API)

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
-- Allergies
-- =========================
INSERT INTO allergies ("Id", "Name", "Description")
VALUES
  ('20000000-0000-0000-0000-000000000001', 'Gluten',  'Dị ứng gluten / không dung nạp gluten'),
  ('20000000-0000-0000-0000-000000000002', 'Lactose', 'Không dung nạp lactose / sản phẩm từ sữa'),
  ('20000000-0000-0000-0000-000000000003', 'Peanut',  'Dị ứng đậu phộng'),
  ('20000000-0000-0000-0000-000000000004', 'Seafood', 'Dị ứng hải sản'),
  ('20000000-0000-0000-0000-000000000005', 'Đậu nành', 'Dị ứng đậu nành'),
  ('20000000-0000-0000-0000-000000000006', 'Trứng',   'Dị ứng trứng')
ON CONFLICT ("Name") DO NOTHING;

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
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Food allergies (reference links)
-- =========================
INSERT INTO food_allergies ("FoodId", "AllergyId")
VALUES
  ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000003'),
  ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002')
ON CONFLICT DO NOTHING;

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
    'male',
    'Việt Nam',
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    'Lan Pro',
    'https://i.pravatar.cc/150?img=11',
    '1996-08-20',
    'female',
    'Healthy / Gym',
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    'Admin MenuGreen',
    'https://i.pravatar.cc/150?img=3',
    '1990-01-01',
    'male',
    NULL,
    now(), now()
  )
ON CONFLICT ("UserId") DO NOTHING;

-- =========================
-- Health profiles (targets aligned with Home UI ~1850 kcal)
-- =========================
INSERT INTO health_profiles (
  "UserId","HeightCm","WeightKg","BodyFatPercent","ActivityLevel","Goal",
  "Bmi","BmrKcal","TdeeKcal","TargetCalories","TargetProteinG","TargetCarbsG","TargetFatG",
  "CreatedAt","UpdatedAt"
)
VALUES
  (
    '70000000-0000-0000-0000-000000000001',
    170.00, 65.00, 18.00, 'moderate', 'loseweight',
    22.49, 1583, 2454, 1850, 139, 185, 62,
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    165.00, 58.00, 22.00, 'active', 'maintain',
    21.30, 1420, 2449, 2450, 184, 245, 82,
    now(), now()
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    175.00, 72.00, NULL, 'light', 'maintain',
    23.51, 1680, 2310, 2310, 173, 231, 77,
    now(), now()
  )
ON CONFLICT ("UserId") DO NOTHING;

-- =========================
-- User allergies
-- =========================
INSERT INTO user_allergies ("UserId", "AllergyId", "CreatedAt")
VALUES
  ('70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000003', now()),
  ('70000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002', now())
ON CONFLICT DO NOTHING;

-- =========================
-- Subscriptions (Pro user - yearly plan)
-- =========================
INSERT INTO subscriptions (
  "Id","UserId","PlanId","Status","AutoRenew","StartedAt","ExpiresAt"
)
VALUES
  (
    '80000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003',
    'active',
    true,
    now() - interval '60 days',
    '2026-12-31 23:59:59+00'::timestamptz
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Favorite foods
-- =========================
INSERT INTO favorite_foods ("UserId", "FoodId", "CreatedAt")
VALUES
  ('70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001', now()),
  ('70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002', now()),
  ('70000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001', now())
ON CONFLICT DO NOTHING;

-- =========================
-- Meal logs (demo user today - total ~1200 kcal, matches Home UI)
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
    200, 11, 14, 10, 'manual', 'Salad đậu hũ nhẹ',
    date_trunc('day', now()) + interval '18 hours 30 minutes'
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
    1200, 71, 104, 46, 64.86
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    '70000000-0000-0000-0000-000000000002',
    CURRENT_DATE,
    980, 55, 110, 32, 40.00
  )
ON CONFLICT ("Id") DO NOTHING;

-- =========================
-- Water logs (today)
-- =========================
INSERT INTO water_logs ("Id", "UserId", "AmountMl", "LoggedAt")
VALUES
  ('b0000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001', 250, date_trunc('day', now()) + interval '8 hours'),
  ('b0000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001', 350, date_trunc('day', now()) + interval '10 hours'),
  ('b0000000-0000-0000-0000-000000000003','70000000-0000-0000-0000-000000000001', 500, date_trunc('day', now()) + interval '14 hours'),
  ('b0000000-0000-0000-0000-000000000004','70000000-0000-0000-0000-000000000002', 400, date_trunc('day', now()) + interval '9 hours')
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
-- Notifications
-- =========================
INSERT INTO notifications ("Id", "UserId", "Title", "Body", "Type", "IsRead", "CreatedAt")
VALUES
  (
    'd0000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'Chào buổi sáng!',
    'Bạn còn 650 kcal cho hôm nay. Thử Salad ức gà cho bữa trưa nhé.',
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
-- Meal plan (demo user - sample week)
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
    1850, 'manual', true, now(), now()
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
  )
ON CONFLICT ("Id") DO NOTHING;

COMMIT;

-- =========================
-- Quick verification (optional - run after COMMIT)
-- =========================
-- SELECT u."Email", r."Name" AS role, p."FullName", hp."TargetCalories"
-- FROM users u
-- JOIN roles r ON r."Id" = u."RoleId"
-- LEFT JOIN profiles p ON p."UserId" = u."Id"
-- LEFT JOIN health_profiles hp ON hp."UserId" = u."Id"
-- WHERE u."Email" LIKE '%@menugreen.app';
