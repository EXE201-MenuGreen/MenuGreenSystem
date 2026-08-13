-- =============================================================================
-- MenuGreen - Gymer meal data for the current mid-week report demo
-- Target account: gymer@menugreen.app (ffffffff-ffff-ffff-ffff-ffffffffffff)
-- Report week: Monday 10/08/2026 through Sunday 16/08/2026
-- Actual meal data: Monday 10/08 through Wednesday 12/08/2026
--
-- This seed intentionally replaces meal logs only inside the three-day demo
-- window for the target account. It is safe to run repeatedly.
-- =============================================================================
BEGIN;

-- Keep the report deterministic by replacing only the target user's logs in
-- the Monday-Wednesday test window. Other users and dates are untouched.
DELETE FROM meal_logs
WHERE "UserId" = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
  AND ("LoggedAt" AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
      BETWEEN DATE '2026-08-10' AND DATE '2026-08-12';

INSERT INTO meal_plan_headers (
    "Id", "UserId", "Title", "PlanType", "StartDate", "EndDate",
    "TargetCalories", "GeneratedBy", "IsActive", "CreatedAt", "UpdatedAt",
    "Status", "ApprovedAt", "MinCalories", "MaxCalories", "CoachNotes"
)
SELECT
    '70aa0000-0000-4000-8000-202608100001',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Dữ liệu test báo cáo giữa tuần 10-12/08/2026',
    'WEEKLY', DATE '2026-08-10', DATE '2026-08-12',
    2038, 'DEMO_SEED', true,
    TIMESTAMPTZ '2026-08-13 09:00:00+07',
    TIMESTAMPTZ '2026-08-13 09:00:00+07',
    'Approved', TIMESTAMPTZ '2026-08-13 09:00:00+07',
    1850, 2200, 'Dữ liệu mẫu để kiểm thử báo cáo giữa tuần.'
WHERE EXISTS (
    SELECT 1 FROM users
    WHERE "Id" = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
)
ON CONFLICT ("Id") DO UPDATE SET
    "Title" = EXCLUDED."Title",
    "StartDate" = EXCLUDED."StartDate",
    "EndDate" = EXCLUDED."EndDate",
    "TargetCalories" = EXCLUDED."TargetCalories",
    "IsActive" = EXCLUDED."IsActive",
    "UpdatedAt" = EXCLUDED."UpdatedAt",
    "Status" = EXCLUDED."Status",
    "ApprovedAt" = EXCLUDED."ApprovedAt",
    "MinCalories" = EXCLUDED."MinCalories",
    "MaxCalories" = EXCLUDED."MaxCalories",
    "CoachNotes" = EXCLUDED."CoachNotes";

-- Reset only items owned by this demo plan before recreating them.
DELETE FROM meal_plan_items
WHERE "MealPlanId" = '70aa0000-0000-4000-8000-202608100001';

INSERT INTO meal_plan_items (
    "Id", "MealPlanId", "MealType", "FoodId", "RecipeId", "PlannedDate",
    "ScheduledTime", "TargetCalories", "QuantityG", "ProteinG", "CarbsG",
    "FatG", "SourceType", "CustomName", "IngredientSnapshotJson",
    "IsCompleted", "CreatedAt", "Origin"
)
VALUES
-- Monday 10/08/2026
('71aa0001-0000-4000-8000-202608100001', '70aa0000-0000-4000-8000-202608100001', 'breakfast', 'fd000008-0000-0000-0000-000000000008', NULL, DATE '2026-08-10', TIME '07:15:00', 400, 300, 18, 45, 12, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-10 06:00:00+07', 'demo_midweek'),
('71aa0001-0000-4000-8000-202608100002', '70aa0000-0000-4000-8000-202608100001', 'lunch',     'fd000001-0000-0000-0000-000000000001', NULL, DATE '2026-08-10', TIME '12:10:00', 650, 280, 58, 70, 15, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-10 06:00:00+07', 'demo_midweek'),
('71aa0001-0000-4000-8000-202608100003', '70aa0000-0000-4000-8000-202608100001', 'snack',     'fd000004-0000-0000-0000-000000000004', NULL, DATE '2026-08-10', TIME '15:45:00', 250, 250,  5, 55,  2, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-10 06:00:00+07', 'demo_midweek'),
('71aa0001-0000-4000-8000-202608100004', '70aa0000-0000-4000-8000-202608100001', 'dinner',    'fd110034-1000-4000-8000-000000000034', NULL, DATE '2026-08-10', TIME '19:00:00', 700, 300, 52, 65, 25, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-10 06:00:00+07', 'demo_midweek'),
-- Tuesday 11/08/2026
('71aa0002-0000-4000-8000-202608110001', '70aa0000-0000-4000-8000-202608100001', 'breakfast', 'fd110041-1000-4000-8000-000000000041', NULL, DATE '2026-08-11', TIME '07:20:00', 420, 220, 28, 30, 20, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-11 06:00:00+07', 'demo_midweek'),
('71aa0002-0000-4000-8000-202608110002', '70aa0000-0000-4000-8000-202608100001', 'lunch',     'fd000006-0000-0000-0000-000000000006', NULL, DATE '2026-08-11', TIME '12:05:00', 680, 320, 55, 75, 18, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-11 06:00:00+07', 'demo_midweek'),
('71aa0002-0000-4000-8000-202608110003', '70aa0000-0000-4000-8000-202608100001', 'snack',     'fd000004-0000-0000-0000-000000000004', NULL, DATE '2026-08-11', TIME '16:00:00', 240, 240,  4, 55,  1, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-11 06:00:00+07', 'demo_midweek'),
('71aa0002-0000-4000-8000-202608110004', '70aa0000-0000-4000-8000-202608100001', 'dinner',    'fd110010-1000-4000-8000-000000000010', NULL, DATE '2026-08-11', TIME '18:50:00', 610, 280, 55, 60, 16, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-11 06:00:00+07', 'demo_midweek'),
-- Wednesday 12/08/2026
('71aa0003-0000-4000-8000-202608120001', '70aa0000-0000-4000-8000-202608100001', 'breakfast', 'fd000008-0000-0000-0000-000000000008', NULL, DATE '2026-08-12', TIME '07:10:00', 410, 310, 19, 50, 11, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-12 06:00:00+07', 'demo_midweek'),
('71aa0003-0000-4000-8000-202608120002', '70aa0000-0000-4000-8000-202608100001', 'lunch',     'fd000001-0000-0000-0000-000000000001', NULL, DATE '2026-08-12', TIME '12:15:00', 690, 300, 60, 76, 14, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-12 06:00:00+07', 'demo_midweek'),
('71aa0003-0000-4000-8000-202608120003', '70aa0000-0000-4000-8000-202608100001', 'snack',     'fd000005-0000-0000-0000-000000000005', NULL, DATE '2026-08-12', TIME '15:40:00', 330, 260, 12, 42, 12, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-12 06:00:00+07', 'demo_midweek'),
('71aa0003-0000-4000-8000-202608120004', '70aa0000-0000-4000-8000-202608100001', 'dinner',    'fd110034-1000-4000-8000-000000000034', NULL, DATE '2026-08-12', TIME '19:10:00', 620, 270, 48, 45, 24, 'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-12 06:00:00+07', 'demo_midweek');

INSERT INTO meal_logs (
    "Id", "UserId", "FoodId", "RecipeId", "MealType", "QuantityG",
    "CaloriesKcal", "ProteinG", "CarbsG", "FatG", "SourceType",
    "CustomName", "Notes", "LoggedAt", "MealPlanItemId", "IsFromMealPlan",
    "ConsumptionRatio"
)
VALUES
-- Monday 10/08/2026: 2,000 kcal / 133 g protein
('72aa0001-0000-4000-8000-202608100001', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000008-0000-0000-0000-000000000008', NULL, 'breakfast', 300, 400, 18, 45, 12, 'Food', NULL, 'Bữa sáng trước ngày tập thân trên', TIMESTAMPTZ '2026-08-10 07:18:00+07', '71aa0001-0000-4000-8000-202608100001', true, 1.0000),
('72aa0001-0000-4000-8000-202608100002', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000001-0000-0000-0000-000000000001', NULL, 'lunch',     280, 650, 58, 70, 15, 'Food', NULL, 'Bữa trưa giàu đạm sau tập',             TIMESTAMPTZ '2026-08-10 12:12:00+07', '71aa0001-0000-4000-8000-202608100002', true, 1.0000),
('72aa0001-0000-4000-8000-202608100003', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000004-0000-0000-0000-000000000004', NULL, 'snack',     250, 250,  5, 55,  2, 'Food', NULL, 'Bữa phụ trước tập',                    TIMESTAMPTZ '2026-08-10 15:48:00+07', '71aa0001-0000-4000-8000-202608100003', true, 1.0000),
('72aa0001-0000-4000-8000-202608100004', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd110034-1000-4000-8000-000000000034', NULL, 'dinner',    300, 700, 52, 65, 25, 'Food', NULL, 'Bữa tối phục hồi sau tập',              TIMESTAMPTZ '2026-08-10 19:05:00+07', '71aa0001-0000-4000-8000-202608100004', true, 1.0000),
-- Tuesday 11/08/2026: 1,950 kcal / 142 g protein
('72aa0002-0000-4000-8000-202608110001', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd110041-1000-4000-8000-000000000041', NULL, 'breakfast', 220, 420, 28, 30, 20, 'Food', NULL, 'Bữa sáng ngày tập chân',                TIMESTAMPTZ '2026-08-11 07:22:00+07', '71aa0002-0000-4000-8000-202608110001', true, 1.0000),
('72aa0002-0000-4000-8000-202608110002', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000006-0000-0000-0000-000000000006', NULL, 'lunch',     320, 680, 55, 75, 18, 'Food', NULL, 'Bữa trưa đủ đạm và rau xanh',           TIMESTAMPTZ '2026-08-11 12:08:00+07', '71aa0002-0000-4000-8000-202608110002', true, 1.0000),
('72aa0002-0000-4000-8000-202608110003', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000004-0000-0000-0000-000000000004', NULL, 'snack',     240, 240,  4, 55,  1, 'Food', NULL, 'Bữa phụ bổ sung carb',                   TIMESTAMPTZ '2026-08-11 16:02:00+07', '71aa0002-0000-4000-8000-202608110003', true, 1.0000),
('72aa0002-0000-4000-8000-202608110004', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd110010-1000-4000-8000-000000000010', NULL, 'dinner',    280, 610, 55, 60, 16, 'Food', NULL, 'Bữa tối kiểm soát chất béo',             TIMESTAMPTZ '2026-08-11 18:55:00+07', '71aa0002-0000-4000-8000-202608110004', true, 1.0000),
-- Wednesday 12/08/2026: 2,050 kcal / 139 g protein
('72aa0003-0000-4000-8000-202608120001', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000008-0000-0000-0000-000000000008', NULL, 'breakfast', 310, 410, 19, 50, 11, 'Food', NULL, 'Bữa sáng ngày tập nhẹ',                  TIMESTAMPTZ '2026-08-12 07:13:00+07', '71aa0003-0000-4000-8000-202608120001', true, 1.0000),
('72aa0003-0000-4000-8000-202608120002', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000001-0000-0000-0000-000000000001', NULL, 'lunch',     300, 690, 60, 76, 14, 'Food', NULL, 'Bữa trưa đạt mục tiêu protein',           TIMESTAMPTZ '2026-08-12 12:18:00+07', '71aa0003-0000-4000-8000-202608120002', true, 1.0000),
('72aa0003-0000-4000-8000-202608120003', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd000005-0000-0000-0000-000000000005', NULL, 'snack',     260, 330, 12, 42, 12, 'Food', NULL, 'Bữa phụ sau tập',                        TIMESTAMPTZ '2026-08-12 15:43:00+07', '71aa0003-0000-4000-8000-202608120003', true, 1.0000),
('72aa0003-0000-4000-8000-202608120004', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'fd110034-1000-4000-8000-000000000034', NULL, 'dinner',    270, 620, 48, 45, 24, 'Food', NULL, 'Bữa tối hoàn tất báo cáo giữa tuần',      TIMESTAMPTZ '2026-08-12 19:14:00+07', '71aa0003-0000-4000-8000-202608120004', true, 1.0000);

COMMIT;
