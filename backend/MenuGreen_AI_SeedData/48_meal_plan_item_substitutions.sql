-- =============================================================================
-- MenuGreen Seed Data - Table: meal_plan_item_substitutions
-- Sequence Number: 48
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_plan_item_substitutions CASCADE;

CREATE TABLE meal_plan_item_substitutions (
    "Id" uuid NOT NULL,
    "MealPlanItemId" uuid NOT NULL,
    "OriginalIngredientId" uuid NOT NULL,
    "SubstituteIngredientId" uuid NOT NULL,
    "OriginalQuantity" double precision NOT NULL,
    "SubstituteQuantity" double precision NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_meal_plan_item_substitutions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_plan_item_substitutions_meal_plan_items_MealPlanItemId" FOREIGN KEY ("MealPlanItemId") REFERENCES meal_plan_items ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_plan_item_substitutions_ingredients_OriginalIngredientId" FOREIGN KEY ("OriginalIngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_plan_item_substitutions_ingredients_Sub_IngredientId" FOREIGN KEY ("SubstituteIngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE
);

-- Seed Data for meal_plan_item_substitutions
INSERT INTO meal_plan_item_substitutions ("Id", "MealPlanItemId", "OriginalIngredientId", "SubstituteIngredientId", "OriginalQuantity", "SubstituteQuantity", "CreatedAt")
VALUES
('22000000-0000-0000-0000-000000000001', 'cae386dd-3682-4e12-82a0-537df7a6461d', '73cb3e0a-5abc-5c6c-a7a2-7a9ac350f4cd', 'ea000002-1111-2222-3333-444444444444', 100.00, 120.00, now())
ON CONFLICT DO NOTHING;

COMMIT;