-- =============================================================================
-- MenuGreen Seed Data - Table: food_allergies
-- Sequence Number: 22
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS food_allergies CASCADE;

CREATE TABLE food_allergies (
    "FoodId" uuid NOT NULL,
    "AllergyId" uuid NOT NULL,
    CONSTRAINT "PK_food_allergies" PRIMARY KEY ("FoodId", "AllergyId"),
    CONSTRAINT "FK_food_allergies_allergies_AllergyId" FOREIGN KEY ("AllergyId") REFERENCES allergies ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_food_allergies_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE
);

INSERT INTO food_allergies ("FoodId", "AllergyId")
VALUES
('fd000007-0000-0000-0000-000000000007', 'f738b00b-67f6-4ba9-9edf-23d4107d09d3'),
('fd000010-0000-0000-0000-000000000010', 'f738b00b-67f6-4ba9-9edf-23d4107d09d3'),
('fd000005-0000-0000-0000-000000000005', 'f3f478e9-810f-4be2-bf95-d445bcafa07a')
ON CONFLICT DO NOTHING;

COMMIT;