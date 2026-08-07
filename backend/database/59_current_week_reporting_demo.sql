-- =============================================================================
-- MenuGreen - Complete demo reporting data for the current week
-- Target account: gymer@menugreen.app (ffffffff-ffff-ffff-ffff-ffffffffffff)
-- Week: 03/08/2026 - 09/08/2026; actual data through 07/08/2026 00:53 +07.
--
-- Monday-Wednesday data already exists. This script fills Thursday, creates
-- Friday's planned meals (without future actual logs), and records weights at
-- the start of the week and at the current check-in.
-- Safe to run repeatedly.
-- =============================================================================
BEGIN;

-- The applied Friday adjustment uses a daily plan. Ensure it exists so this
-- seed also works after loading the numbered database scripts from scratch.
INSERT INTO meal_plan_headers (
    "Id", "UserId", "Title", "PlanType", "StartDate", "EndDate",
    "TargetCalories", "GeneratedBy", "IsActive", "CreatedAt", "UpdatedAt",
    "Status", "ApprovedAt", "MinCalories", "MaxCalories", "CoachNotes"
)
SELECT
    '801c5f80-5b29-4d5b-9c54-948c479f150f',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Lộ trình ngày 07/08/2026', 'DAILY',
    DATE '2026-08-07', DATE '2026-08-07',
    2000, 'PT_PROPOSAL', true,
    TIMESTAMPTZ '2026-08-07 00:39:15+07',
    TIMESTAMPTZ '2026-08-07 00:39:15+07',
    'Approved', TIMESTAMPTZ '2026-08-07 00:39:15+07',
    NULL, NULL, 'Điều chỉnh giữa tuần từ PT'
WHERE EXISTS (
    SELECT 1 FROM users
    WHERE "Id" = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
)
ON CONFLICT ("Id") DO NOTHING;

-- Thursday and Friday planned meals in the active weekly plan.
INSERT INTO meal_plan_items (
    "Id", "MealPlanId", "MealType", "FoodId", "RecipeId", "PlannedDate",
    "ScheduledTime", "TargetCalories", "QuantityG", "ProteinG", "CarbsG",
    "FatG", "SourceType", "CustomName", "IngredientSnapshotJson",
    "IsCompleted", "CreatedAt", "Origin"
)
VALUES
(
    '86000001-0000-4000-8000-000000000001',
    'ee8bb747-45d4-41bf-a522-2384ef74e18c',
    'breakfast', 'fd000008-0000-0000-0000-000000000008', NULL,
    DATE '2026-08-06', TIME '07:30:00', 450, 250, 20, 50, 12,
    'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-06 06:00:00+07', 'demo_current_week'
),
(
    '86000002-0000-4000-8000-000000000002',
    'ee8bb747-45d4-41bf-a522-2384ef74e18c',
    'lunch', 'fd000015-0000-0000-0000-000000000015', NULL,
    DATE '2026-08-06', TIME '12:00:00', 700, 350, 32, 78, 22,
    'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-06 06:00:00+07', 'demo_current_week'
),
(
    '86000003-0000-4000-8000-000000000003',
    'ee8bb747-45d4-41bf-a522-2384ef74e18c',
    'dinner', 'fd110034-1000-4000-8000-000000000034', NULL,
    DATE '2026-08-06', TIME '18:30:00', 650, 220, 56, 18, 28,
    'Food', NULL, NULL, true, TIMESTAMPTZ '2026-08-06 06:00:00+07', 'demo_current_week'
),
(
    '87000001-0000-4000-8000-000000000001',
    '801c5f80-5b29-4d5b-9c54-948c479f150f',
    'breakfast', 'fd000005-0000-0000-0000-000000000005', NULL,
    DATE '2026-08-07', TIME '07:30:00', 450, 350, 12, 52, 22,
    'Food', NULL, NULL, false, TIMESTAMPTZ '2026-08-07 00:45:00+07', 'demo_current_week'
),
(
    '87000002-0000-4000-8000-000000000002',
    '801c5f80-5b29-4d5b-9c54-948c479f150f',
    'lunch', 'fd000049-0000-0000-0000-000000000049', NULL,
    DATE '2026-08-07', TIME '12:00:00', 700, 350, 41, 70, 20,
    'Food', NULL, NULL, false, TIMESTAMPTZ '2026-08-07 00:45:00+07', 'demo_current_week'
),
(
    '87000003-0000-4000-8000-000000000003',
    '801c5f80-5b29-4d5b-9c54-948c479f150f',
    'dinner', 'fd110025-1000-4000-8000-000000000025', NULL,
    DATE '2026-08-07', TIME '18:30:00', 650, 300, 53, 32, 26,
    'Food', NULL, NULL, false, TIMESTAMPTZ '2026-08-07 00:45:00+07', 'demo_current_week'
)
ON CONFLICT ("Id") DO UPDATE SET
    "MealPlanId" = EXCLUDED."MealPlanId",
    "MealType" = EXCLUDED."MealType",
    "FoodId" = EXCLUDED."FoodId",
    "RecipeId" = EXCLUDED."RecipeId",
    "PlannedDate" = EXCLUDED."PlannedDate",
    "ScheduledTime" = EXCLUDED."ScheduledTime",
    "TargetCalories" = EXCLUDED."TargetCalories",
    "QuantityG" = EXCLUDED."QuantityG",
    "ProteinG" = EXCLUDED."ProteinG",
    "CarbsG" = EXCLUDED."CarbsG",
    "FatG" = EXCLUDED."FatG",
    "IsCompleted" = EXCLUDED."IsCompleted",
    "Origin" = EXCLUDED."Origin";

-- Thursday actual logs. Friday is intentionally omitted because the current
-- time is before breakfast; the weekly report will show Friday as planned only.
INSERT INTO meal_logs (
    "Id", "UserId", "FoodId", "RecipeId", "MealType", "QuantityG",
    "CaloriesKcal", "ProteinG", "CarbsG", "FatG", "SourceType",
    "CustomName", "Notes", "LoggedAt", "MealPlanItemId", "IsFromMealPlan"
)
VALUES
(
    '96000001-0000-4000-8000-000000000001',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'fd000008-0000-0000-0000-000000000008', NULL, 'breakfast', 250,
    440, 20, 48, 11, 'Food', NULL, 'Bữa sáng đúng kế hoạch',
    TIMESTAMPTZ '2026-08-06 07:25:00+07',
    '86000001-0000-4000-8000-000000000001', true
),
(
    '96000002-0000-4000-8000-000000000002',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'fd000015-0000-0000-0000-000000000015', NULL, 'lunch', 350,
    690, 31, 76, 21, 'Food', NULL, 'Bữa trưa đúng kế hoạch',
    TIMESTAMPTZ '2026-08-06 12:10:00+07',
    '86000002-0000-4000-8000-000000000002', true
),
(
    '96000003-0000-4000-8000-000000000003',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'fd110034-1000-4000-8000-000000000034', NULL, 'dinner', 220,
    640, 55, 17, 27, 'Food', NULL, 'Bữa tối đúng kế hoạch',
    TIMESTAMPTZ '2026-08-06 18:35:00+07',
    '86000003-0000-4000-8000-000000000003', true
)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO weight_logs (
    "Id", "UserId", "WeightKg", "BodyFatPercent", "RecordedAt"
)
VALUES
(
    '97000001-0000-4000-8000-000000000001',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    75.4, 20.3, TIMESTAMPTZ '2026-08-03 06:45:00+07'
),
(
    '97000002-0000-4000-8000-000000000002',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    75.0, 20.0, TIMESTAMPTZ '2026-08-07 00:45:00+07'
)
ON CONFLICT ("Id") DO NOTHING;

COMMIT;
