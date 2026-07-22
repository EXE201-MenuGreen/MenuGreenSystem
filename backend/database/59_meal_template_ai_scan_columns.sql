-- Allow user-owned meal templates to persist dishes returned by AI scan.
-- This extends meal_template_items only; no new table is created.
BEGIN;

ALTER TABLE meal_template_items
    ADD COLUMN IF NOT EXISTS "CustomName" character varying(200) NULL,
    ADD COLUMN IF NOT EXISTS "SourceType" character varying(50) NULL,
    ADD COLUMN IF NOT EXISTS "CaloriesKcal" numeric(18,2) NULL,
    ADD COLUMN IF NOT EXISTS "ProteinG" numeric(18,2) NULL,
    ADD COLUMN IF NOT EXISTS "CarbsG" numeric(18,2) NULL,
    ADD COLUMN IF NOT EXISTS "FatG" numeric(18,2) NULL,
    ADD COLUMN IF NOT EXISTS "IngredientSnapshotJson" jsonb NULL;

COMMIT;
