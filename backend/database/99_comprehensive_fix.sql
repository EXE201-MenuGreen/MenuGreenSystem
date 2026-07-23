-- =============================================================================
-- MenuGreen - Comprehensive Database Fix Script
-- Date: 2026-07-22
-- Description: Fix all common database issues
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. Fix meal_plan_items table - Add Origin column
-- =============================================================================
DO $$
BEGIN
    -- Add Origin column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'meal_plan_items' AND column_name = 'Origin'
    ) THEN
        ALTER TABLE meal_plan_items ADD COLUMN "Origin" character varying(50);
        RAISE NOTICE 'SUCCESS: Added Origin column to meal_plan_items';
    ELSE
        RAISE NOTICE 'INFO: Origin column already exists in meal_plan_items';
    END IF;
    
    -- Update existing NULL values to 'user'
    UPDATE meal_plan_items SET "Origin" = 'user' WHERE "Origin" IS NULL;
    
    -- Add index
    CREATE INDEX IF NOT EXISTS ix_meal_plan_items_origin ON meal_plan_items ("Origin");
END $$;

-- =============================================================================
-- 2. Fix user_ai_profile table
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
        RAISE NOTICE 'SUCCESS: Created user_ai_profile table';
    ELSE
        RAISE NOTICE 'INFO: user_ai_profile table already exists';
        
        -- Check if columns exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_ai_profile' AND column_name = 'Preferences'
        ) THEN
            ALTER TABLE user_ai_profile ADD COLUMN "Preferences" jsonb NULL;
            RAISE NOTICE 'SUCCESS: Added Preferences column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_ai_profile' AND column_name = 'DislikedFoods'
        ) THEN
            ALTER TABLE user_ai_profile ADD COLUMN "DislikedFoods" jsonb NULL;
            RAISE NOTICE 'SUCCESS: Added DislikedFoods column';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_ai_profile' AND column_name = 'EatingPattern'
        ) THEN
            ALTER TABLE user_ai_profile ADD COLUMN "EatingPattern" jsonb NULL;
            RAISE NOTICE 'SUCCESS: Added EatingPattern column';
        END IF;
    END IF;
END $$;

-- =============================================================================
-- 3. Verify database structure
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== DATABASE VERIFICATION ===';
    
    -- Check meal_plan_items
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'meal_plan_items' AND column_name = 'Origin'
    ) THEN
        RAISE NOTICE 'OK: meal_plan_items has Origin column';
    ELSE
        RAISE NOTICE 'ERROR: meal_plan_items missing Origin column!';
    END IF;
    
    -- Check user_ai_profile
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'user_ai_profile'
    ) THEN
        RAISE NOTICE 'OK: user_ai_profile table exists';
        
        -- Check all required columns
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_ai_profile' AND column_name = 'Preferences'
        ) THEN
            RAISE NOTICE 'OK: user_ai_profile has Preferences column';
        ELSE
            RAISE NOTICE 'ERROR: user_ai_profile missing Preferences column!';
        END IF;
    ELSE
        RAISE NOTICE 'ERROR: user_ai_profile table does not exist!';
    END IF;
    
    RAISE NOTICE '=== END VERIFICATION ===';
    RAISE NOTICE '';
END $$;

COMMIT;

-- =============================================================================
-- Sample test queries (run separately)
-- =============================================================================
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'meal_plan_items' ORDER BY ordinal_position;
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_ai_profile' ORDER BY ordinal_position;
-- SELECT "Origin", COUNT(*) FROM meal_plan_items GROUP BY "Origin";
