-- =============================================================================
-- Phase 8: Add PersonalProgramSupport
-- Adds PT -> Gymer direction to the quoted "PtReviewRequests" table.
-- Idempotent: safe to run multiple times.
-- =============================================================================
BEGIN;

-- 1. Add CreatedByRole column (default "Gymer" for existing rows).
ALTER TABLE "PtReviewRequests"
    ADD COLUMN IF NOT EXISTS "CreatedByRole" varchar(20) NOT NULL DEFAULT 'Gymer';

-- 2. Add AcceptedAt (Gymer accepts PersonalProgram).
ALTER TABLE "PtReviewRequests"
    ADD COLUMN IF NOT EXISTS "AcceptedAt" timestamptz NULL;

-- 3. Add AcceptedByUserId (audit: same as UserId in current model, kept separate for clarity).
ALTER TABLE "PtReviewRequests"
    ADD COLUMN IF NOT EXISTS "AcceptedByUserId" uuid NULL;

-- 4. Partial unique index to prevent >1 Pending PersonalProgram per Gymer.
CREATE UNIQUE INDEX IF NOT EXISTS "IX_PtReviewRequests_CreatedByRole_Status_Pending"
    ON "PtReviewRequests" ("UserId", "CreatedByRole")
    WHERE "Status" = 'Pending' AND "CreatedByRole" = 'Coach';

COMMIT;
