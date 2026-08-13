-- =============================================================================
-- MenuGreen - Ingredients commonly returned by the Office ingredient scanner
-- Nutrition values are stored per 100 g, matching the existing catalog.
-- Idempotent by both stable Id and Vietnamese display name.
-- =============================================================================
BEGIN;

INSERT INTO ingredients (
    "Id", "NameVi", "NameEn", "Category",
    "CaloriesKcal", "ProteinG", "CarbsG", "FatG",
    "EstimatedPriceVnd", "UnitDefault", "ImageUrl", "IsActive", "CreatedAt"
)
SELECT *
FROM (VALUES
    ('ea000056-1111-2222-3333-444444444444'::uuid, 'Thịt bò tươi', 'Fresh beef', 'Thịt/Cá', 143::numeric, 26.0::numeric, 0.0::numeric, 3.8::numeric, 280000, 'g', NULL::text, true, now()),
    ('ea000057-1111-2222-3333-444444444444'::uuid, 'Bò viên', 'Beef meatballs', 'Thịt/Cá', 200::numeric, 12.0::numeric, 8.0::numeric, 13.0::numeric, 180000, 'g', NULL::text, true, now()),
    ('ea000058-1111-2222-3333-444444444444'::uuid, 'Bánh phở tươi', 'Fresh pho noodles', 'Tinh bột', 110::numeric, 1.7::numeric, 25.6::numeric, 0.1::numeric, 25000, 'g', NULL::text, true, now()),
    ('ea000059-1111-2222-3333-444444444444'::uuid, 'Rau thơm (Húng quế, ngò gai)', 'Vietnamese mixed herbs', 'Rau củ', 25::numeric, 2.7::numeric, 4.5::numeric, 0.5::numeric, 40000, 'g', NULL::text, true, now()),
    ('ea000060-1111-2222-3333-444444444444'::uuid, 'Giá đỗ', 'Bean sprouts', 'Rau củ', 30::numeric, 3.0::numeric, 5.9::numeric, 0.2::numeric, 18000, 'g', NULL::text, true, now())
) AS source(
    "Id", "NameVi", "NameEn", "Category",
    "CaloriesKcal", "ProteinG", "CarbsG", "FatG",
    "EstimatedPriceVnd", "UnitDefault", "ImageUrl", "IsActive", "CreatedAt"
)
WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients existing
    WHERE lower(existing."NameVi") = lower(source."NameVi")
)
ON CONFLICT ("Id") DO UPDATE SET
    "NameVi" = EXCLUDED."NameVi",
    "NameEn" = EXCLUDED."NameEn",
    "Category" = EXCLUDED."Category",
    "CaloriesKcal" = EXCLUDED."CaloriesKcal",
    "ProteinG" = EXCLUDED."ProteinG",
    "CarbsG" = EXCLUDED."CarbsG",
    "FatG" = EXCLUDED."FatG",
    "EstimatedPriceVnd" = EXCLUDED."EstimatedPriceVnd",
    "UnitDefault" = EXCLUDED."UnitDefault",
    "IsActive" = true;

COMMIT;
