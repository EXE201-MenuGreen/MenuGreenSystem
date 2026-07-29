-- =============================================================================
-- Add approval lifecycle to Coach-created meal plans.
-- Idempotent: safe to run multiple times.
-- Status values:
--   Active   - regular AI/User/System plan
--   Draft    - Coach is still editing; hidden from the Gymer
--   Approved - Coach submitted the plan; visible and cannot be submitted again
-- =============================================================================
BEGIN;

ALTER TABLE meal_plan_headers
    ADD COLUMN IF NOT EXISTS "Status" varchar(20) NOT NULL DEFAULT 'Active';

ALTER TABLE meal_plan_headers
    ADD COLUMN IF NOT EXISTS "ApprovedAt" timestamptz NULL;

CREATE INDEX IF NOT EXISTS "IX_meal_plan_headers_Status"
    ON meal_plan_headers ("Status");

-- Backfill Coach plans that were already submitted before Status existed.
-- A matching meal_plan_approved notification is durable evidence that submit
-- completed; drafts without that notification remain Active and can be sent.
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

-- Keep the Gymer-facing "Tôi gửi PT" status in sync. Before this fix,
-- submitting a Coach meal plan did not update PtReviewRequest, so the card
-- stayed at "Chờ phản hồi" even though an approval notification existed.
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
