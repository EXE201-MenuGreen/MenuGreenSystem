-- =============================================================================
-- MenuGreen - Meal plan proposal tables + current mid-week proposal seed
-- Safe to run repeatedly: no DROP statements and all inserts are idempotent.
-- =============================================================================
BEGIN;

CREATE TABLE IF NOT EXISTS meal_plan_proposals (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "CoachId" uuid NOT NULL,
    "ReviewRequestId" uuid NOT NULL,
    "ProposalType" character varying(40) NOT NULL,
    "Status" character varying(20) NOT NULL,
    "PeriodStart" date NOT NULL,
    "PeriodEnd" date NOT NULL,
    "ExpiresAt" timestamp with time zone NULL,
    "SourcePlanVersion" timestamp with time zone NULL,
    "ReminderSentAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NULL,
    "SubmittedAt" timestamp with time zone NULL,
    "ActionedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_meal_plan_proposals" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_plan_proposals_PtReviewRequests_ReviewRequestId"
        FOREIGN KEY ("ReviewRequestId") REFERENCES "PtReviewRequests" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_plan_proposals_users_CoachId"
        FOREIGN KEY ("CoachId") REFERENCES users ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_meal_plan_proposals_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS meal_plan_proposal_items (
    "Id" uuid NOT NULL,
    "ProposalId" uuid NOT NULL,
    "Action" character varying(20) NOT NULL,
    "PlannedDate" date NOT NULL,
    "MealType" character varying(30) NOT NULL,
    "ExistingMealPlanItemId" uuid NULL,
    "FoodId" uuid NULL,
    "RecipeId" uuid NULL,
    "QuantityG" numeric(10,2) NULL,
    "TargetCalories" integer NULL,
    "SortOrder" integer NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_meal_plan_proposal_items" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_plan_proposal_items_foods_FoodId"
        FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_meal_plan_proposal_items_meal_plan_items_ExistingMealPlanItemId"
        FOREIGN KEY ("ExistingMealPlanItemId") REFERENCES meal_plan_items ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_meal_plan_proposal_items_meal_plan_proposals_ProposalId"
        FOREIGN KEY ("ProposalId") REFERENCES meal_plan_proposals ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_plan_proposal_items_recipes_RecipeId"
        FOREIGN KEY ("RecipeId") REFERENCES recipes ("Id") ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposal_items_ExistingMealPlanItemId"
    ON meal_plan_proposal_items ("ExistingMealPlanItemId");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposal_items_FoodId"
    ON meal_plan_proposal_items ("FoodId");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposal_items_PlannedDate"
    ON meal_plan_proposal_items ("PlannedDate");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposal_items_ProposalId"
    ON meal_plan_proposal_items ("ProposalId");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposal_items_RecipeId"
    ON meal_plan_proposal_items ("RecipeId");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposals_CoachId"
    ON meal_plan_proposals ("CoachId");
CREATE UNIQUE INDEX IF NOT EXISTS "IX_meal_plan_proposals_ReviewRequestId_ProposalType"
    ON meal_plan_proposals ("ReviewRequestId", "ProposalType");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposals_Status_ExpiresAt"
    ON meal_plan_proposals ("Status", "ExpiresAt");
CREATE INDEX IF NOT EXISTS "IX_meal_plan_proposals_UserId"
    ON meal_plan_proposals ("UserId");

-- Seed the reviewed mid-week proposal for 03/08/2026 - 09/08/2026 only when
-- its report and both users are present. Existing application history wins.
INSERT INTO meal_plan_proposals (
    "Id", "UserId", "CoachId", "ReviewRequestId", "ProposalType", "Status",
    "PeriodStart", "PeriodEnd", "ExpiresAt", "SourcePlanVersion",
    "ReminderSentAt", "CreatedAt", "UpdatedAt", "SubmittedAt", "ActionedAt"
)
SELECT
    '82957aa4-a3cc-4dee-9478-284e9fc8a1d0',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '77777777-7777-7777-7777-777777777777',
    '03409ac4-16c7-4c75-9cd4-5137d4958f01',
    'CurrentWeekAdjustment', 'Applied',
    DATE '2026-08-07', DATE '2026-08-09',
    TIMESTAMPTZ '2026-08-07 00:00:00+07',
    TIMESTAMPTZ '2026-08-05 18:38:49+07',
    NULL,
    TIMESTAMPTZ '2026-08-07 00:08:56+07',
    TIMESTAMPTZ '2026-08-07 00:39:15+07',
    TIMESTAMPTZ '2026-08-07 00:08:56+07',
    TIMESTAMPTZ '2026-08-07 00:39:15+07'
WHERE EXISTS (
    SELECT 1 FROM "PtReviewRequests"
    WHERE "Id" = '03409ac4-16c7-4c75-9cd4-5137d4958f01'
)
AND EXISTS (
    SELECT 1 FROM users
    WHERE "Id" = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
)
AND EXISTS (
    SELECT 1 FROM users
    WHERE "Id" = '77777777-7777-7777-7777-777777777777'
)
ON CONFLICT DO NOTHING;

INSERT INTO meal_plan_proposal_items (
    "Id", "ProposalId", "Action", "PlannedDate", "MealType",
    "ExistingMealPlanItemId", "FoodId", "RecipeId", "QuantityG",
    "TargetCalories", "SortOrder", "CreatedAt"
)
SELECT
    'aede1603-a003-4575-b2a0-40a6cdf7f242',
    '82957aa4-a3cc-4dee-9478-284e9fc8a1d0',
    'Add', DATE '2026-08-07', 'snack',
    NULL, 'fd000068-0000-0000-0000-000000000068', NULL, 100,
    280, 0, TIMESTAMPTZ '2026-08-07 00:08:56+07'
WHERE EXISTS (
    SELECT 1 FROM meal_plan_proposals
    WHERE "Id" = '82957aa4-a3cc-4dee-9478-284e9fc8a1d0'
)
ON CONFLICT DO NOTHING;

COMMIT;
