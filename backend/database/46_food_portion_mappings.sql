-- =============================================================================
-- MenuGreen Seed Data - Table: food_portion_mappings
-- Sequence Number: 46
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS food_portion_mappings CASCADE;

CREATE TABLE food_portion_mappings (
    "Id" uuid NOT NULL,
    "FoodId" uuid NOT NULL,
    "Unit" character varying(100) NOT NULL,
    "GramsPerUnit" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_food_portion_mappings" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_food_portion_mappings_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_food_portion_mappings_FoodId_Unit" ON food_portion_mappings ("FoodId", "Unit");

-- Seed Data for food_portion_mappings
INSERT INTO food_portion_mappings ("Id", "FoodId", "Unit", "GramsPerUnit", "CreatedAt")
VALUES
('44000000-0000-0000-0000-000000000001', 'fd000001-0000-0000-0000-000000000001', 'Chén', 150.00, now()),
('44000000-0000-0000-0000-000000000002', 'fd000001-0000-0000-0000-000000000001', 'Tô', 350.00, now()),
('44000000-0000-0000-0000-000000000003', 'fd000002-0000-0000-0000-000000000002', 'Đĩa', 200.00, now())
ON CONFLICT DO NOTHING;

COMMIT;