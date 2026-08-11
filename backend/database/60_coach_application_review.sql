-- PT application onboarding, Admin review workflow and profile seed.
-- This script never creates a Coach account. It only completes coach_profiles
-- for users that already have the Coach role.
BEGIN;

ALTER TABLE coach_profiles
    ADD COLUMN IF NOT EXISTS "Headline" character varying(120) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "PhoneNumber" character varying(30) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "City" character varying(120) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "LanguagesJson" text NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS "CoachingStylesJson" text NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS "ClientLevelsJson" text NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS "CertificatesJson" text NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS "GalleryUrlsJson" text NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS "Achievements" text NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "IdentityDocumentUrl" character varying(1000) NULL,
    ADD COLUMN IF NOT EXISTS "ApplicationStatus" character varying(30) NOT NULL DEFAULT 'Draft',
    ADD COLUMN IF NOT EXISTS "ReviewNote" character varying(1000) NULL,
    ADD COLUMN IF NOT EXISTS "SubmittedAt" timestamp with time zone NULL,
    ADD COLUMN IF NOT EXISTS "ReviewedAt" timestamp with time zone NULL,
    ADD COLUMN IF NOT EXISTS "ReviewedByUserId" uuid NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "IX_coach_profiles_UserId"
    ON coach_profiles ("UserId");

CREATE INDEX IF NOT EXISTS "IX_coach_profiles_ApplicationStatus"
    ON coach_profiles ("ApplicationStatus");

-- Remove the temporary PT account created by the previous seed version.
DELETE FROM users
WHERE "Id" = '88888888-8888-8888-8888-888888888888'
  AND "Email" = 'pt.pending@menugreen.app';

-- Undo the temporary rename from the previous seed version without touching
-- accounts whose owner has already edited their own name.
UPDATE profiles
SET "FullName" = 'Huấn luyện viên Coach (PT)',
    "AvatarUrl" = 'https://i.pravatar.cc/150?u=77777777-7777-7777-7777-777777777777',
    "UpdatedAt" = now()
WHERE "UserId" = '77777777-7777-7777-7777-777777777777'
  AND "FullName" = 'Nguyễn Minh Khôi';

-- Keep Coach accounts that had already been approved before this workflow.
UPDATE coach_profiles
SET "ApplicationStatus" = 'Approved',
    "ReviewedAt" = COALESCE("ReviewedAt", "UpdatedAt")
WHERE "IsActive" = true
  AND "ApplicationStatus" = 'Draft';

-- Complete a profile for every existing Coach account. The first and second
-- Coach receive different sample specialties/media so both profiles are easy
-- to distinguish in the Admin UI. Existing content is kept, while every blank
-- legacy field is backfilled even when the profile was already Approved.
WITH coach_accounts AS (
    SELECT
        u."Id" AS "UserId",
        u."CreatedAt",
        row_number() OVER (ORDER BY u."CreatedAt", u."Id") AS position
    FROM users u
    INNER JOIN roles r ON r."Id" = u."RoleId"
    WHERE lower(r."Name") = 'coach'
      AND u."DeletedAt" IS NULL
)
INSERT INTO coach_profiles (
    "Id", "UserId", "Specialty", "Headline", "Bio", "ExperienceYears",
    "CertificateUrl", "PhoneNumber", "City", "LanguagesJson",
    "CoachingStylesJson", "ClientLevelsJson", "CertificatesJson",
    "GalleryUrlsJson", "Achievements", "IdentityDocumentUrl",
    "ApplicationStatus", "ReviewNote", "SubmittedAt", "ReviewedAt",
    "ReviewedByUserId", "PriceVnd", "IsActive", "CreatedAt", "UpdatedAt"
)
SELECT
    ca."UserId",
    ca."UserId",
    CASE WHEN ca.position % 2 = 1
        THEN 'Giảm cân, giảm mỡ, Tăng cơ, Body recomposition'
        ELSE 'Giảm cân, Functional training, Cardio và sức bền'
    END,
    CASE WHEN ca.position % 2 = 1
        THEN 'PT tăng cơ và giảm mỡ dành cho người mới'
        ELSE 'PT đồng hành giảm mỡ và cải thiện sức bền'
    END,
    CASE WHEN ca.position % 2 = 1
        THEN 'Tôi là huấn luyện viên cá nhân với nhiều năm kinh nghiệm đồng hành cùng người mới bắt đầu. Phương pháp của tôi ưu tiên kỹ thuật an toàn, theo sát số liệu và xây dựng thói quen bền vững thay vì ép cân ngắn hạn.'
        ELSE 'Tôi là huấn luyện viên cá nhân chuyên hướng dẫn người mới và nhân viên văn phòng. Tôi tập trung vào kỹ thuật đúng, sức bền và những thay đổi nhỏ có thể duy trì lâu dài trong cuộc sống bận rộn.'
    END,
    CASE WHEN ca.position % 2 = 1 THEN 6 ELSE 4 END,
    CASE WHEN ca.position % 2 = 1
        THEN 'https://placehold.co/1200x800/EAF4EF/14532D?text=NASM-CPT'
        ELSE 'https://placehold.co/1200x800/FFF7ED/9A3412?text=ACE-CPT'
    END,
    CASE WHEN ca.position % 2 = 1 THEN '0901234567' ELSE '0912345678' END,
    CASE WHEN ca.position % 2 = 1 THEN 'TP. Hồ Chí Minh' ELSE 'Hà Nội' END,
    '["Tiếng Việt","English"]',
    CASE WHEN ca.position % 2 = 1
        THEN '["Theo sát số liệu","Nhẹ nhàng, động viên","Kỷ luật"]'
        ELSE '["Nhẹ nhàng, động viên","Linh hoạt theo lịch","Theo sát số liệu"]'
    END,
    '["Người mới","Trung cấp"]',
    CASE WHEN ca.position % 2 = 1
        THEN '[{"Name":"NASM Certified Personal Trainer","Issuer":"National Academy of Sports Medicine","CredentialNumber":"NASM-CPT-MG-2024-0188","IssuedDate":"2024-01-15","ExpiryDate":"2028-01-15","ImageUrl":"https://placehold.co/1200x800/EAF4EF/14532D?text=NASM-CPT"},{"Name":"CPR và AED","Issuer":"American Safety Training Institute","CredentialNumber":"CPR-AED-2025-771","IssuedDate":"2025-02-10","ExpiryDate":"2027-02-10","ImageUrl":"https://placehold.co/1200x800/EFF6FF/1D4ED8?text=CPR-AED"}]'
        ELSE '[{"Name":"ACE Certified Personal Trainer","Issuer":"American Council on Exercise","CredentialNumber":"ACE-MG-2023-0421","IssuedDate":"2023-06-20","ExpiryDate":"2027-06-20","ImageUrl":"https://placehold.co/1200x800/FFF7ED/9A3412?text=ACE-CPT"},{"Name":"First Aid và CPR","Issuer":"Vietnam Red Cross","CredentialNumber":"VNRC-CPR-2025-118","IssuedDate":"2025-03-12","ExpiryDate":"2027-03-12","ImageUrl":"https://placehold.co/1200x800/FEF2F2/B91C1C?text=First+Aid+CPR"}]'
    END,
    CASE WHEN ca.position % 2 = 1
        THEN '["https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200","https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=1200","https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200","https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=1200"]'
        ELSE '["https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200","https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=1200","https://images.unsplash.com/photo-1594737625785-a6cbdabd333c?w=1200"]'
    END,
    CASE WHEN ca.position % 2 = 1
        THEN 'Đã đồng hành cùng hơn 120 học viên và chuyên xây dựng lộ trình tăng cơ, giảm mỡ cho người mới.'
        ELSE 'Đã hướng dẫn hơn 70 học viên và hoàn thành chứng nhận huấn luyện nhóm, sơ cứu cơ bản.'
    END,
    CASE WHEN ca.position % 2 = 1
        THEN 'https://placehold.co/1200x800/F4F4F5/18181B?text=Identity+Coach+1'
        ELSE 'https://placehold.co/1200x800/F4F4F5/18181B?text=Identity+Coach+2'
    END,
    'PendingReview',
    NULL,
    now() - (ca.position * interval '1 hour'),
    NULL,
    NULL,
    0,
    false,
    ca."CreatedAt",
    now()
FROM coach_accounts ca
ON CONFLICT ("UserId") DO UPDATE SET
    "Specialty" = COALESCE(NULLIF(BTRIM(coach_profiles."Specialty"), ''), EXCLUDED."Specialty"),
    "Headline" = COALESCE(NULLIF(BTRIM(coach_profiles."Headline"), ''), EXCLUDED."Headline"),
    "Bio" = COALESCE(NULLIF(BTRIM(coach_profiles."Bio"), ''), EXCLUDED."Bio"),
    "ExperienceYears" = CASE WHEN coach_profiles."ExperienceYears" > 0 THEN coach_profiles."ExperienceYears" ELSE EXCLUDED."ExperienceYears" END,
    "CertificateUrl" = COALESCE(NULLIF(BTRIM(coach_profiles."CertificateUrl"), ''), EXCLUDED."CertificateUrl"),
    "PhoneNumber" = COALESCE(NULLIF(BTRIM(coach_profiles."PhoneNumber"), ''), EXCLUDED."PhoneNumber"),
    "City" = COALESCE(NULLIF(BTRIM(coach_profiles."City"), ''), EXCLUDED."City"),
    "LanguagesJson" = CASE WHEN COALESCE(NULLIF(BTRIM(coach_profiles."LanguagesJson"), ''), '[]') IN ('[]', 'null') THEN EXCLUDED."LanguagesJson" ELSE coach_profiles."LanguagesJson" END,
    "CoachingStylesJson" = CASE WHEN COALESCE(NULLIF(BTRIM(coach_profiles."CoachingStylesJson"), ''), '[]') IN ('[]', 'null') THEN EXCLUDED."CoachingStylesJson" ELSE coach_profiles."CoachingStylesJson" END,
    "ClientLevelsJson" = CASE WHEN COALESCE(NULLIF(BTRIM(coach_profiles."ClientLevelsJson"), ''), '[]') IN ('[]', 'null') THEN EXCLUDED."ClientLevelsJson" ELSE coach_profiles."ClientLevelsJson" END,
    "CertificatesJson" = CASE WHEN COALESCE(NULLIF(BTRIM(coach_profiles."CertificatesJson"), ''), '[]') IN ('[]', 'null') THEN EXCLUDED."CertificatesJson" ELSE coach_profiles."CertificatesJson" END,
    "GalleryUrlsJson" = CASE WHEN COALESCE(NULLIF(BTRIM(coach_profiles."GalleryUrlsJson"), ''), '[]') IN ('[]', 'null') THEN EXCLUDED."GalleryUrlsJson" ELSE coach_profiles."GalleryUrlsJson" END,
    "Achievements" = COALESCE(NULLIF(BTRIM(coach_profiles."Achievements"), ''), EXCLUDED."Achievements"),
    "IdentityDocumentUrl" = COALESCE(NULLIF(BTRIM(coach_profiles."IdentityDocumentUrl"), ''), EXCLUDED."IdentityDocumentUrl"),
    "ApplicationStatus" = CASE WHEN coach_profiles."ApplicationStatus" IN ('', 'Draft') THEN 'PendingReview' ELSE coach_profiles."ApplicationStatus" END,
    "ReviewNote" = coach_profiles."ReviewNote",
    "SubmittedAt" = COALESCE(coach_profiles."SubmittedAt", EXCLUDED."SubmittedAt"),
    "IsActive" = coach_profiles."IsActive",
    "UpdatedAt" = now()
WHERE COALESCE(BTRIM(coach_profiles."Specialty"), '') = ''
   OR COALESCE(BTRIM(coach_profiles."Headline"), '') = ''
   OR COALESCE(BTRIM(coach_profiles."Bio"), '') = ''
   OR coach_profiles."ExperienceYears" <= 0
   OR COALESCE(BTRIM(coach_profiles."CertificateUrl"), '') = ''
   OR COALESCE(BTRIM(coach_profiles."PhoneNumber"), '') = ''
   OR COALESCE(BTRIM(coach_profiles."City"), '') = ''
   OR COALESCE(NULLIF(BTRIM(coach_profiles."LanguagesJson"), ''), '[]') IN ('[]', 'null')
   OR COALESCE(NULLIF(BTRIM(coach_profiles."CoachingStylesJson"), ''), '[]') IN ('[]', 'null')
   OR COALESCE(NULLIF(BTRIM(coach_profiles."ClientLevelsJson"), ''), '[]') IN ('[]', 'null')
   OR COALESCE(NULLIF(BTRIM(coach_profiles."CertificatesJson"), ''), '[]') IN ('[]', 'null')
   OR COALESCE(NULLIF(BTRIM(coach_profiles."GalleryUrlsJson"), ''), '[]') IN ('[]', 'null')
   OR COALESCE(BTRIM(coach_profiles."Achievements"), '') = ''
   OR COALESCE(BTRIM(coach_profiles."IdentityDocumentUrl"), '') = ''
   OR coach_profiles."ApplicationStatus" IN ('', 'Draft')
   OR coach_profiles."SubmittedAt" IS NULL;

-- Public PT profiles read avatars from profiles, not coach_profiles. Only fill
-- missing avatars so a PT-uploaded photo is never replaced by this seed.
UPDATE profiles p
SET
    "AvatarUrl" = 'https://i.pravatar.cc/300?u=' || p."UserId"::text,
    "UpdatedAt" = now()
FROM users u
INNER JOIN roles r ON r."Id" = u."RoleId"
WHERE p."UserId" = u."Id"
  AND lower(r."Name") = 'coach'
  AND u."DeletedAt" IS NULL
  AND COALESCE(BTRIM(p."AvatarUrl"), '') = '';

COMMIT;
