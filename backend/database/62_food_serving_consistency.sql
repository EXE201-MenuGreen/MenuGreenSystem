-- Food nutrition values represent one default serving. Require a positive
-- gram basis so kcal/macros can always be scaled without assuming 100g.
BEGIN;

ALTER TABLE foods
    ALTER COLUMN "DefaultServingG" SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'CK_foods_DefaultServingG_Positive'
          AND conrelid = 'foods'::regclass
    ) THEN
        ALTER TABLE foods
            ADD CONSTRAINT "CK_foods_DefaultServingG_Positive"
            CHECK ("DefaultServingG" > 0);
    END IF;
END $$;

COMMIT;
