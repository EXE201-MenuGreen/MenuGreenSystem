-- Adjustable recipe portions are immutable snapshots attached to a proposal,
-- approved plan item and actual meal log. Catalog foods/recipes remain unchanged.
BEGIN;

ALTER TABLE meal_plan_proposal_items
    ADD COLUMN IF NOT EXISTS "ProteinG" numeric(10,2) NULL,
    ADD COLUMN IF NOT EXISTS "CarbsG" numeric(10,2) NULL,
    ADD COLUMN IF NOT EXISTS "FatG" numeric(10,2) NULL,
    ADD COLUMN IF NOT EXISTS "IngredientSnapshotJson" jsonb NULL;

ALTER TABLE meal_logs
    ADD COLUMN IF NOT EXISTS "IngredientSnapshotJson" jsonb NULL,
    ADD COLUMN IF NOT EXISTS "ConsumptionRatio" numeric(8,4) NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'CK_meal_logs_ConsumptionRatio_Positive'
          AND conrelid = 'meal_logs'::regclass
    ) THEN
        ALTER TABLE meal_logs
            ADD CONSTRAINT "CK_meal_logs_ConsumptionRatio_Positive"
            CHECK ("ConsumptionRatio" IS NULL OR "ConsumptionRatio" > 0);
    END IF;
END $$;

COMMIT;
