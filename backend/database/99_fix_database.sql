-- =============================================================================
-- MenuGreen - Database Fix Script
-- Description: Fix common database issues
-- Date: 2026-07-22
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. Add Origin column to meal_plan_items if not exists
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'meal_plan_items' AND column_name = 'Origin'
    ) THEN
        ALTER TABLE meal_plan_items ADD COLUMN "Origin" character varying(50);
        RAISE NOTICE 'Added Origin column to meal_plan_items';
    ELSE
        RAISE NOTICE 'Origin column already exists in meal_plan_items';
    END IF;
END $$;

-- Update existing rows to have Origin = 'user'
UPDATE meal_plan_items SET "Origin" = 'user' WHERE "Origin" IS NULL;

-- =============================================================================
-- 2. Check and create user_ai_profile table if not exists
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'user_ai_profile'
    ) THEN
        CREATE TABLE user_ai_profile (
            "UserId" uuid NOT NULL,
            "Preferences" jsonb NULL,
            "DislikedFoods" jsonb NULL,
            "EatingPattern" jsonb NULL,
            "UpdatedAt" timestamp with time zone NULL,
            CONSTRAINT "PK_user_ai_profile" PRIMARY KEY ("UserId"),
            CONSTRAINT "FK_user_ai_profile_users_UserId" 
                FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
        );
        RAISE NOTICE 'Created user_ai_profile table';
    ELSE
        RAISE NOTICE 'user_ai_profile table already exists';
    END IF;
END $$;

-- =============================================================================
-- 3. Add index for Origin column
-- =============================================================================
CREATE INDEX IF NOT EXISTS ix_meal_plan_items_origin ON meal_plan_items ("Origin");

COMMIT;

-- =============================================================================
-- Verification queries (run separately)
-- =============================================================================
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'meal_plan_items';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_ai_profile';
