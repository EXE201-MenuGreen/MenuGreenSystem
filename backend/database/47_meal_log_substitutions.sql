-- =============================================================================
-- MenuGreen Seed Data - Table: meal_log_substitutions
-- Sequence Number: 47
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_log_substitutions CASCADE;

CREATE TABLE meal_log_substitutions (
    "Id" uuid NOT NULL,
    "MealLogId" uuid NOT NULL,
    "OriginalIngredientId" uuid NOT NULL,
    "SubstituteIngredientId" uuid NOT NULL,
    "OriginalQuantity" double precision NOT NULL,
    "SubstituteQuantity" double precision NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_meal_log_substitutions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_log_substitutions_meal_logs_MealLogId" FOREIGN KEY ("MealLogId") REFERENCES meal_logs ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_log_substitutions_ingredients_OriginalIngredientId" FOREIGN KEY ("OriginalIngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_log_substitutions_ingredients_SubstituteIngredientId" FOREIGN KEY ("SubstituteIngredientId") REFERENCES ingredients ("Id") ON DELETE CASCADE
);

-- Seed Data for meal_log_substitutions
INSERT INTO meal_log_substitutions ("Id", "MealLogId", "OriginalIngredientId", "SubstituteIngredientId", "OriginalQuantity", "SubstituteQuantity", "CreatedAt")
VALUES
('33000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '73cb3e0a-5abc-5c6c-a7a2-7a9ac350f4cd', '01619128-a551-5bcb-84a9-5f7ddf562db4', 150.00, 180.00, now())
ON CONFLICT DO NOTHING;

COMMIT;