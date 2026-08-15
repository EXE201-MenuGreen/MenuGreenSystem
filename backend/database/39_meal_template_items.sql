-- =============================================================================
-- MenuGreen Seed Data - Table: meal_template_items
-- Sequence Number: 39
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS meal_template_items CASCADE;

CREATE TABLE meal_template_items (
    "Id" uuid NOT NULL,
    "MealTemplateId" uuid NOT NULL,
    "FoodId" uuid NULL,
    "RecipeId" uuid NULL,
    "CustomName" character varying(200) NULL,
    "SourceType" character varying(50) NULL,
    "MealType" character varying(50) NOT NULL DEFAULT 'Snack',
    "QuantityG" numeric(18,2) NOT NULL,
    "CaloriesKcal" numeric(18,2) NULL,
    "ProteinG" numeric(18,2) NULL,
    "CarbsG" numeric(18,2) NULL,
    "FatG" numeric(18,2) NULL,
    "IngredientSnapshotJson" jsonb NULL,
    "Notes" character varying(1000) NULL,
    "SortOrder" integer NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_meal_template_items" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_meal_template_items_meal_templates_MealTemplateId" FOREIGN KEY ("MealTemplateId") REFERENCES meal_templates ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_template_items_foods_FoodId" FOREIGN KEY ("FoodId") REFERENCES foods ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_meal_template_items_recipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES recipes ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_meal_template_items_MealTemplateId" ON meal_template_items ("MealTemplateId");

-- Seed Data for meal_template_items
INSERT INTO meal_template_items ("Id", "MealTemplateId", "FoodId", "RecipeId", "MealType", "QuantityG", "Notes", "SortOrder", "CreatedAt")
VALUES
('bbbbbbbb-1111-1111-1111-bbbbbbbbbb01', '99999999-9999-9999-9999-999999999901', 'fd000004-0000-0000-0000-000000000004', NULL, 'Snack', 150.00, 'Ăn nguội hoặc quay nóng lại', 1, now() - interval '5 days'),
('bbbbbbbb-2222-2222-2222-bbbbbbbbbb02', '99999999-9999-9999-9999-999999999902', 'fd000001-0000-0000-0000-000000000001', NULL, 'Lunch', 180.00, 'Ức gà nạc không da', 1, now() - interval '3 days'),
('bbbbbbbb-2222-2222-2222-bbbbbbbbbb03', '99999999-9999-9999-9999-999999999902', 'fd000002-0000-0000-0000-000000000002', NULL, 'Lunch', 150.00, 'Gạo lứt đỏ', 2, now() - interval '3 days')
ON CONFLICT DO NOTHING;

COMMIT;
