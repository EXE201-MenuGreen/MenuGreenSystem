-- Migration: Add Origin column to meal_plan_items
-- Date: 2026-07-22
-- Description: Add Origin column to meal_plan_items table for tracking item origin (user/gym)

BEGIN;

-- Add Origin column if not exists
ALTER TABLE meal_plan_items ADD COLUMN IF NOT EXISTS "Origin" character varying(50);

-- Update all existing rows to have Origin = 'user' (user-created items)
UPDATE meal_plan_items SET "Origin" = 'user' WHERE "Origin" IS NULL;

-- Add index for Origin column for better query performance
CREATE INDEX IF NOT EXISTS ix_meal_plan_items_origin ON meal_plan_items ("Origin");

COMMIT;
