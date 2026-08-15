-- =============================================================================
-- MenuGreen Migration - Add SourceName column to recipes table
-- Sequence Number: 72
-- Purpose: Add SourceName column to track recipe source (e.g., AI, Manual, etc.)
-- =============================================================================
BEGIN;

-- Add SourceName column if not exists
ALTER TABLE recipes
    ADD COLUMN IF NOT EXISTS "SourceName" character varying(255) NULL;

COMMENT ON COLUMN recipes."SourceName" IS 'Source of the recipe (e.g., AI, Manual, Import)';

COMMIT;
