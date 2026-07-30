-- =============================================================================
-- MenuGreen Seed Data - Table: PtReviewRequests
-- Sequence Number: 55
-- Phase 8: merged from 55 + 56 (PersonalProgramSupport)
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
    -- Phase 8: Coach -> Gymer PersonalProgram support
    "CreatedByRole" character varying(20) NOT NULL DEFAULT 'Gymer',
    "AcceptedAt" timestamp with time zone NULL,
    "AcceptedByUserId" uuid NULL,
    CONSTRAINT "PK_PtReviewRequests" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PtReviewRequests_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_PtReviewRequests_CreatedByRole_Status_Pending"
    ON "PtReviewRequests" ("UserId", "CreatedByRole")
    WHERE "Status" = 'Pending' AND "CreatedByRole" = 'Coach';

-- Seed Data for PtReviewRequests
INSERT INTO "PtReviewRequests" (
    "Id", "UserId", "WeekStartDate", "ReviewToken", "ExpiresAt",
    "Status", "CreatedAt", "ReportDataJson", "PtComment",
    "SuggestedCalorieTarget", "SuggestedProteinTarget",
    "SuggestedFatTarget", "SuggestedCarbsTarget",
    "SuggestedChangesJson", "ReviewedAt", "ActionedAt",
    "CreatedByRole", "AcceptedAt", "AcceptedByUserId"
)
VALUES
(
    -- Row 1: Gymer -> Coach: existing weekly review (bbbbbbbb = demo@menugreen.app, Free)
    -- This is the "Tôi gửi PT" flow: Gymer submits report, Coach reviews.
    'd1000000-0000-0000-0000-000000000001',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    CURRENT_DATE - 7,
    'TOKEN_REVIEW_12345',
    now() + interval '5 days',
    'Reviewed',
    now() - interval '2 days',
    '{"total_calories": 14000, "avg_weight": 71.2}',
    'Tôi thấy bạn đang tập luyện tốt nhưng thiếu đạm. Hãy tăng cường ăn thêm lòng trắng trứng và ức gà vào bữa sáng nhé!',
    1800,
    130,
    50,
    200,
    '[]',
    now() - interval '1 day',
    NULL,
    'Gymer',
    NULL,
    NULL
),
(
    -- Row 2: Coach -> Gymer: PersonalProgram sent to Gymer (ffffffff = gymer@menugreen.app, Gymer)
    -- This is the "PT tạo chương trình cho học viên" flow.
    'd1000000-0000-0000-0000-000000000002',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    CURRENT_DATE - 7,
    'TOKEN_PERSONAL_PROGRAM_67890',
    now() + interval '14 days',
    'Pending',
    now() - interval '3 days',
    '{"total_calories": 16500, "avg_weight": 68.5, "requestType": "PersonalProgram"}',
    NULL,
    1850,
    140,
    55,
    210,
    '[
        {"day": 1, "change": "Tăng protein bữa sáng thêm 20g"},
        {"day": 2, "change": "Thêm rau xanh vào bữa trưa"},
        {"day": 3, "change": "Giảm carbs bữa tối"}
    ]',
    NULL,
    NULL,
    'Coach',
    NULL,
    NULL
)
ON CONFLICT DO NOTHING;

COMMIT;
