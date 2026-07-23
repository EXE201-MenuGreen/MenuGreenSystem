-- =============================================================================
-- MenuGreen Seed Data - Migration: Add CoachId to meal_plan_headers
-- Sequence Number: 26
--
-- Idempotent migration: safe to run multiple times.
-- Goal: track which meal plans were created by a Coach on behalf of a Gymer.
-- =============================================================================
BEGIN;

-- 1. Add column if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'meal_plan_headers'
          AND column_name = 'CoachId'
    ) THEN
        ALTER TABLE meal_plan_headers
        ADD COLUMN "CoachId" uuid NULL;
    END IF;
END $$;

-- 2. Add foreign key constraint if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'FK_meal_plan_headers_users_CoachId'
    ) THEN
        ALTER TABLE meal_plan_headers
        ADD CONSTRAINT "FK_meal_plan_headers_users_CoachId"
        FOREIGN KEY ("CoachId") REFERENCES users ("Id") ON DELETE SET NULL;
    END IF;
END $$;

-- 3. Add index for coach-side lookups if it does not exist
CREATE INDEX IF NOT EXISTS "IX_meal_plan_headers_CoachId"
ON meal_plan_headers ("CoachId");

COMMIT;