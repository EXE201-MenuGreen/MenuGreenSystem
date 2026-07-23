-- =============================================================================
-- MenuGreen Patch Script - Add Coach Role & Dedicated Coach Account
-- Sequence Number: 58
-- =============================================================================
BEGIN;

-- 1. Insert Coach Role
INSERT INTO roles ("Id", "Name", "Description", "CreatedAt", "UpdatedAt")
VALUES ('00000000-0000-0000-0000-000000000008', 'Coach', 'Personal trainer / Nutrition coach', now(), now())
ON CONFLICT ("Id") DO NOTHING;

-- 2. Insert Dedicated Coach User (Email: coach@menugreen.app, Password: Demo@123)
INSERT INTO users ("Id", "RoleId", "Email", "PasswordHash", "EmailConfirmed", "IsActive", "LastSignInAt", "CreatedAt", "UpdatedAt", "DeletedAt")
VALUES (
    '77777777-7777-7777-7777-777777777777',
    '00000000-0000-0000-0000-000000000008',
    'coach@menugreen.app',
    '$2a$12$9rfP3ktSdK.lDRXFTuHqCOR4EOG7zTZZLL8aD4R2UcBGwNTdSg1D2',
    true,
    true,
    now(),
    now(),
    now(),
    NULL
)
ON CONFLICT ("Id") DO UPDATE SET "PasswordHash" = EXCLUDED."PasswordHash";

-- 3. Insert Coach Profile
INSERT INTO profiles ("UserId", "FullName", "AvatarUrl", "DateOfBirth", "Gender", "PreferredCuisine", "CreatedAt", "UpdatedAt")
VALUES (
    '77777777-7777-7777-7777-777777777777',
    'Huấn luyện viên Coach (PT)',
    'https://i.pravatar.cc/150?u=77777777-7777-7777-7777-777777777777',
    '1992-05-15',
    'Male',
    'Việt Nam',
    now(),
    now()
)
ON CONFLICT ("UserId") DO NOTHING;

-- 4. Insert Coach Profile Details
INSERT INTO coach_profiles ("Id", "UserId", "Specialty", "Bio", "ExperienceYears", "CertificateUrl", "PriceVnd", "IsActive", "CreatedAt", "UpdatedAt")
VALUES (
    '90000000-0000-0000-0000-000000000002',
    '77777777-7777-7777-7777-777777777777',
    'Huấn luyện viên PT & Dinh dưỡng chuyên sâu',
    'Chào bạn, tôi là PT Coach MenuGreen với nhiều năm kinh nghiệm tư vấn thực đơn và lên kế hoạch luyện tập chuyên biệt.',
    6,
    'https://example.com/certificates/pt_coach.pdf',
    500000,
    true,
    now(),
    now()
)
ON CONFLICT ("Id") DO NOTHING;

COMMIT;
