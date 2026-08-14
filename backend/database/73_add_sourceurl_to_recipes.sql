-- =============================================================================
-- MenuGreen Migration - Add SourceUrl column to recipes table
-- Sequence Number: 73
-- Purpose: Add SourceUrl column to track recipe source URL (e.g., external links)
-- =============================================================================
BEGIN;

-- Add SourceUrl column if not exists
ALTER TABLE recipes
    ADD COLUMN IF NOT EXISTS "SourceUrl" character varying(2048) NULL;

COMMENT ON COLUMN recipes."SourceUrl" IS 'URL source of the recipe (e.g., external reference link)';

COMMIT;
