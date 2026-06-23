-- =============================================================================
-- MenuGreen Seed Data - Table: health_profiles
-- Sequence Number: 05
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS health_profiles CASCADE;

CREATE TABLE health_profiles (
    "UserId" uuid NOT NULL,
    "HeightCm" numeric(5,2) NULL,
    "WeightKg" numeric(5,2) NULL,
    "BodyFatPercent" numeric(5,2) NULL,
    "ActivityLevel" character varying(50) NULL,
    "Goal" character varying(50) NULL,
    "Bmi" numeric(5,2) NULL,
    "BmrKcal" integer NULL,
    "TdeeKcal" integer NULL,
    "TargetCalories" integer NULL,
    "TargetProteinG" integer NULL,
    "TargetCarbsG" integer NULL,
    "TargetFatG" integer NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_health_profiles" PRIMARY KEY ("UserId"),
    CONSTRAINT "FK_health_profiles_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

INSERT INTO health_profiles ("UserId", "HeightCm", "WeightKg", "BodyFatPercent", "ActivityLevel", "Goal", "Bmi", "BmrKcal", "TdeeKcal", "TargetCalories", "TargetProteinG", "TargetCarbsG", "TargetFatG", "CreatedAt", "UpdatedAt")
VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 175.00, 71.50, 18.50, 'moderately active', 'gain muscle', 23.35, 1673, 2301, 2601, 195, 292, 72, now() - interval '30 days', now() - interval '30 days'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 160.00, 54.60, 24.50, 'moderately active', 'lose weight', 21.33, 1255, 1725, 1325, 99, 149, 36, now() - interval '30 days', now() - interval '30 days'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 175.00, 70.50, 18.50, 'moderately active', 'gain muscle', 23.02, 1663, 2287, 2587, 194, 291, 71, now() - interval '30 days', now() - interval '30 days'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 175.00, 70.00, 18.50, 'moderately active', 'lose weight', 22.86, 1658, 2280, 1880, 141, 211, 52, now() - interval '30 days', now() - interval '30 days'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 160.00, 55.50, 24.50, 'moderately active', 'gain muscle', 21.68, 1264, 1738, 2038, 152, 229, 56, now() - interval '30 days', now() - interval '30 days'),
('885810e8-168f-4608-a72e-e23a20dfd258', 175.00, 69.00, 18.50, 'moderately active', 'lose weight', 22.53, 1648, 2267, 1867, 140, 210, 51, now() - interval '30 days', now() - interval '30 days'),
('48069bd5-f29a-417d-bdeb-c00797968aca', 160.00, 56.10, 24.50, 'moderately active', 'gain muscle', 21.91, 1270, 1746, 2046, 153, 230, 56, now() - interval '30 days', now() - interval '30 days'),
('9afb13a5-e5a1-4342-9ce1-33bf7cc1de70', 175.00, 68.00, 18.50, 'moderately active', 'lose weight', 22.20, 1638, 2253, 1853, 138, 208, 51, now() - interval '30 days', now() - interval '30 days'),
('081b4669-b97f-4e75-b089-4c8de0151653', 160.00, 56.70, 24.50, 'moderately active', 'gain muscle', 22.15, 1276, 1754, 2054, 154, 231, 57, now() - interval '30 days', now() - interval '30 days'),
('586209d0-d3c4-43a4-bba7-5d4c73b37bc1', 175.00, 67.00, 18.50, 'moderately active', 'lose weight', 21.88, 1628, 2239, 1839, 137, 206, 51, now() - interval '30 days', now() - interval '30 days'),
('b022ccde-0aa6-4b11-bd7b-f76aaf2c2b17', 160.00, 57.30, 24.50, 'moderately active', 'gain muscle', 22.38, 1282, 1762, 2062, 154, 232, 57, now() - interval '30 days', now() - interval '30 days'),
('453681f7-f489-47ed-842c-bc3ffd220423', 175.00, 66.00, 18.50, 'moderately active', 'lose weight', 21.55, 1618, 2225, 1825, 136, 205, 50, now() - interval '30 days', now() - interval '30 days'),
('396f9dff-6c2a-422f-b0cc-8eb451168ed3', 160.00, 57.90, 24.50, 'moderately active', 'gain muscle', 22.62, 1288, 1771, 2071, 155, 232, 57, now() - interval '30 days', now() - interval '30 days'),
('5dc50160-db9e-447a-ba33-9026d8800ab5', 175.00, 65.00, 18.50, 'moderately active', 'lose weight', 21.22, 1608, 2212, 1812, 135, 203, 50, now() - interval '30 days', now() - interval '30 days'),
('212ea8ea-749e-44a1-92d2-636bd617cbc8', 160.00, 58.50, 24.50, 'moderately active', 'gain muscle', 22.85, 1294, 1779, 2079, 155, 233, 57, now() - interval '30 days', now() - interval '30 days')
ON CONFLICT DO NOTHING;

COMMIT;