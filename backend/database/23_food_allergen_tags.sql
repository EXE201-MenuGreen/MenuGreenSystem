-- =============================================================================
-- MenuGreen Seed Data - Table: food_allergen_tags
-- Sequence Number: 23
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS food_allergen_tags CASCADE;

CREATE TABLE food_allergen_tags (
    "FoodId" uuid NOT NULL,
    "AllergenKey" character varying(64) NOT NULL,
    CONSTRAINT "PK_food_allergen_tags" PRIMARY KEY ("FoodId", "AllergenKey"),
    CONSTRAINT "FK_food_allergen_tags_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE
);

INSERT INTO food_allergen_tags ("FoodId", "AllergenKey")
VALUES
('fd000007-0000-0000-0000-000000000007', 'seafood'),
('fd000010-0000-0000-0000-000000000010', 'seafood'),
('fd000005-0000-0000-0000-000000000005', 'dairy')
ON CONFLICT DO NOTHING;

COMMIT;