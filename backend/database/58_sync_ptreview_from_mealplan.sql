-- =============================================================================
-- MenuGreen Migration - Sync PtReviewRequests from meal_plan_headers
-- Sequence Number: 58
-- Purpose: Move PtReviewRequests UPDATE from 24_meal_plan_headers.sql
--          because PtReviewRequests table is created in migration 55
-- =============================================================================
BEGIN;

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
