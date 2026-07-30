-- =============================================================================
-- MenuGreen Seed Data - Table: meal_plan_headers
-- Sequence Number: 24
-- Phase 8: merged from 24 + 57 (MealPlan Approval Lifecycle + Coach fields)
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_plan_headers CASCADE;

CREATE TABLE meal_plan_headers (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Title" character varying(255) NULL,
    "PlanType" character varying(50) NULL,
    "StartDate" date NULL,
    "EndDate" date NULL,
    "TargetCalories" integer NULL,
    "GeneratedBy" character varying(50) NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NULL,
    "UpdatedAt" timestamp with time zone NULL,
    -- Phase 8: Coach meal plan approval lifecycle
    "Status" character varying(20) NOT NULL DEFAULT 'Active',
    "ApprovedAt" timestamp with time zone NULL,
    -- Phase 8: Coach configuration fields
    "MinCalories" integer NULL,
    "MaxCalories" integer NULL,
    "CoachNotes" character varying(2000) NULL,
    CONSTRAINT "PK_meal_plan_headers" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_plan_headers_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_meal_plan_headers_Status"
    ON meal_plan_headers ("Status");

-- Seed Data for meal_plan_headers
INSERT INTO meal_plan_headers (
    "Id", "UserId", "Title", "PlanType", "StartDate", "EndDate",
    "TargetCalories", "GeneratedBy", "IsActive", "CreatedAt", "UpdatedAt",
    "Status", "ApprovedAt", "MinCalories", "MaxCalories", "CoachNotes"
)
VALUES
-- ============================================================
-- AI / System plans (existing seed, no Status/Min/Max/CoachNotes)
-- ============================================================
(
    'f22fed1c-b548-4fc7-a4db-9dc571e61d74',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'd677be5c-3bf9-45a0-838e-be2013c93934',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'dacdeef2-185a-49e1-8d10-aae4d507cb22',
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'e95a2ac3-cbb8-427b-b433-3de2ea447729',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'ee8bb747-45d4-41bf-a522-2384ef74e18c',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '43bd57bf-06ff-4391-a8f1-202e9248e7ed',
    '885810e8-168f-4608-a72e-e23a20dfd258',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '128cae5c-6edc-4ea3-b8ac-af67c4952f6e',
    '48069bd5-f29a-417d-bdeb-c00797968aca',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '44c0c107-5c01-4dc9-8cfc-e69a50ec83d7',
    '9afb13a5-e5a1-4342-9ce1-33bf7cc1de70',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'c1b905f7-c948-4506-87b3-cb1f359e9cbc',
    '081b4669-b97f-4e75-b089-4c8de0151653',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '07fbdd58-1b92-441b-ad7d-1f01c9cf1e63',
    '586209d0-d3c4-43a4-bba7-5d4c73b37bc1',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '457cbba7-31e6-4e56-8073-5e8067640cdc',
    'b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'd67fd2c9-bb6b-4216-a5eb-c62b189285d0',
    '453681f7-f489-47ed-842c-bc3ffd220423',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '471293e8-4b51-413c-a739-9aabc9cdfbc9',
    '396f9dff-6c2a-422f-b0cc-8eb451168ed3',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    'ed136f5e-f381-4e17-8aa7-5db67bd34146',
    '5dc50160-db9e-447a-ba33-9026d8800ab5',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
(
    '401f123d-9dc9-40dd-ad44-11dea7dfbe3a',
    '212ea8ea-749e-44a1-92d2-636bd617cbc8',
    'Kế hoạch dinh dưỡng tuần mới',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 7,
    1800, 'AI', true, now(), now(),
    'Active', NULL, NULL, NULL, NULL
),
-- ============================================================
-- Coach plans (Phase 8 seed)
-- ============================================================
(
    -- Plan 1: Coach Draft — not yet submitted, hidden from Gymer
    'a0000000-0000-0000-0000-000000000001',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Thực đơn Gym tăng cơ - Bản nháp',
    'WEEKLY', CURRENT_DATE, CURRENT_DATE + 6,
    1850, 'Coach', true,
    now() - interval '2 days', now() - interval '2 days',
    'Draft', NULL, 1700, 2000,
    'Tuần đầu: Tập trung tăng cơ, ăn đủ đạm 140g/ngày. Bổ sung carbs phức hợp trước buổi tập.'
),
(
    -- Plan 2: Coach Approved — submitted, visible to Gymer
    'a0000000-0000-0000-0000-000000000002',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Thực đơn Gym giảm mỡ - Đã duyệt',
    'WEEKLY', CURRENT_DATE - 7, CURRENT_DATE - 1,
    1750, 'Coach', true,
    now() - interval '10 days', now() - interval '8 days',
    'Approved', now() - interval '8 days', 1600, 1850,
    'Tuần vừa qua: Duy trì calo 1750, tăng rau xanh, giảm đồ chiên rán.'
)
ON CONFLICT DO NOTHING;

-- Backfill Coach plans that were already submitted before Status existed.
-- Uses matching meal_plan_approved notification as proof of submission.
UPDATE meal_plan_headers AS plan
SET
    "Status" = 'Approved',
    "ApprovedAt" = approval."ApprovedAt"
FROM (
    SELECT
        plan_inner."Id" AS "PlanId",
        MAX(notification."CreatedAt") AS "ApprovedAt"
    FROM meal_plan_headers AS plan_inner
    JOIN notifications AS notification
      ON notification."UserId" = plan_inner."UserId"
     AND LOWER(notification."Type") = 'meal_plan_approved'
     AND notification."CreatedAt" >= COALESCE(
         plan_inner."CreatedAt",
         '-infinity'::timestamptz
     )
    WHERE UPPER(COALESCE(plan_inner."GeneratedBy", '')) = 'COACH'
    GROUP BY plan_inner."Id"
) AS approval
WHERE plan."Id" = approval."PlanId"
  AND plan."Status" <> 'Approved';

-- Keep Gymer-facing "Tôi gửi PT" status in sync.
-- When a Coach meal plan is approved, the matching PtReviewRequest should move
-- from Pending -> Reviewed so the Gymer card shows "Đã duyệt".
WITH matching_requests AS (
    SELECT
        request."Id",
        plan."ApprovedAt",
        plan."TargetCalories",
        ROW_NUMBER() OVER (
            PARTITION BY request."UserId"
            ORDER BY request."CreatedAt" DESC
        ) AS row_number
    FROM "PtReviewRequests" AS request
    JOIN meal_plan_headers AS plan
      ON plan."UserId" = request."UserId"
     AND plan."Status" = 'Approved'
     AND COALESCE(plan."StartDate", plan."EndDate")
         <= request."WeekStartDate" + 6
     AND COALESCE(plan."EndDate", plan."StartDate")
         >= request."WeekStartDate"
    WHERE request."Status" = 'Pending'
      AND request."CreatedByRole" <> 'Coach'
      AND (
          COALESCE(request."ReportDataJson", '') = ''
          OR COALESCE(
              request."ReportDataJson"::jsonb ->> 'requestType',
              'RouteApproval'
          ) = 'RouteApproval'
      )
)
UPDATE "PtReviewRequests" AS request
SET
    "Status" = 'Reviewed',
    "ReviewedAt" = matching."ApprovedAt",
    "PtComment" = COALESCE(
        NULLIF(request."PtComment", ''),
        'PT đã duyệt và gửi lộ trình dinh dưỡng.'
    ),
    "SuggestedCalorieTarget" = COALESCE(
        request."SuggestedCalorieTarget",
        matching."TargetCalories"
    )
FROM matching_requests AS matching
WHERE request."Id" = matching."Id"
  AND matching.row_number = 1;

COMMIT;
