-- Keep databases recreated from the legacy seed scripts aligned with the
-- current EF model. This migration is additive and preserves existing data.
BEGIN;

ALTER TABLE meal_logs
    ADD COLUMN IF NOT EXISTS "CustomName" character varying(200) NULL;

ALTER TABLE meal_plan_items
    ADD COLUMN IF NOT EXISTS "QuantityG" numeric NULL,
    ADD COLUMN IF NOT EXISTS "ProteinG" numeric NULL,
    ADD COLUMN IF NOT EXISTS "CarbsG" numeric NULL,
    ADD COLUMN IF NOT EXISTS "FatG" numeric NULL,
    ADD COLUMN IF NOT EXISTS "SourceType" character varying(30) NULL,
    ADD COLUMN IF NOT EXISTS "CustomName" character varying(200) NULL,
    ADD COLUMN IF NOT EXISTS "IngredientSnapshotJson" jsonb NULL;

COMMIT;
