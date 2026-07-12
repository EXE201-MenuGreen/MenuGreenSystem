-- =============================================================================
-- MenuGreen Seed Data - Table: PtReviewRequests
-- Sequence Number: 55
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS "PtReviewRequests" CASCADE;

CREATE TABLE "PtReviewRequests" (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "WeekStartDate" date NOT NULL,
    "ReviewToken" character varying(100) NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "Status" character varying(20) NOT NULL DEFAULT 'Pending',
    "CreatedAt" timestamp with time zone NOT NULL,
    "ReportDataJson" text NOT NULL,
    "PtComment" character varying(1000) NULL,
    "SuggestedCalorieTarget" integer NULL,
    "SuggestedProteinTarget" integer NULL,
    "SuggestedFatTarget" integer NULL,
    "SuggestedCarbsTarget" integer NULL,
    "SuggestedChangesJson" text NULL,
    "ReviewedAt" timestamp with time zone NULL,
    "ActionedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_PtReviewRequests" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PtReviewRequests_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

-- Seed Data for PtReviewRequests
INSERT INTO "PtReviewRequests" ("Id", "UserId", "WeekStartDate", "ReviewToken", "ExpiresAt", "Status", "CreatedAt", "ReportDataJson", "PtComment", "SuggestedCalorieTarget", "SuggestedProteinTarget", "SuggestedFatTarget", "SuggestedCarbsTarget", "SuggestedChangesJson", "ReviewedAt", "ActionedAt")
VALUES
('d1000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_DATE - 7, 'TOKEN_REVIEW_12345', now() + interval '5 days', 'Reviewed', now() - interval '2 days', '{"total_calories": 14000, "avg_weight": 71.2}', 'Tôi thấy bạn đang tập luyện tốt nhưng thiếu đạm. Hãy tăng cường ăn thêm lòng trắng trứng và ức gà vào bữa sáng nhé!', 1800, 130, 50, 200, '[]', now() - interval '1 day', NULL)
ON CONFLICT DO NOTHING;

COMMIT;