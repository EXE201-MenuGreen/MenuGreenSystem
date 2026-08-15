-- =============================================================================
-- MenuGreen Seed Data - Table: coach_profiles
-- Sequence Number: 42
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS coach_profiles CASCADE;

CREATE TABLE coach_profiles (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "Specialty" character varying(255) NOT NULL,
    "Headline" character varying(120) NOT NULL DEFAULT '',
    "Bio" text NOT NULL,
    "ExperienceYears" integer NOT NULL,
    "CertificateUrl" text NULL,
    "PhoneNumber" character varying(30) NOT NULL DEFAULT '',
    "City" character varying(120) NOT NULL DEFAULT '',
    "LanguagesJson" text NOT NULL DEFAULT '[]',
    "CoachingStylesJson" text NOT NULL DEFAULT '[]',
    "ClientLevelsJson" text NOT NULL DEFAULT '[]',
    "CertificatesJson" text NOT NULL DEFAULT '[]',
    "GalleryUrlsJson" text NOT NULL DEFAULT '[]',
    "Achievements" text NOT NULL DEFAULT '',
    "IdentityDocumentUrl" character varying(1000) NULL,
    "ApplicationStatus" character varying(30) NOT NULL DEFAULT 'Draft',
    "ReviewNote" character varying(1000) NULL,
    "SubmittedAt" timestamp with time zone NULL,
    "ReviewedAt" timestamp with time zone NULL,
    "ReviewedByUserId" uuid NULL,
    "PriceVnd" integer NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_coach_profiles" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_coach_profiles_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_coach_profiles_UserId"
    ON coach_profiles ("UserId");
CREATE INDEX "IX_coach_profiles_ApplicationStatus"
    ON coach_profiles ("ApplicationStatus");

-- Seed Data for coach_profiles
INSERT INTO coach_profiles (
    "Id", "UserId", "Specialty", "Headline", "Bio", "ExperienceYears",
    "CertificateUrl", "PhoneNumber", "City", "LanguagesJson",
    "CoachingStylesJson", "ClientLevelsJson", "CertificatesJson",
    "GalleryUrlsJson", "Achievements", "IdentityDocumentUrl",
    "ApplicationStatus", "SubmittedAt", "ReviewedAt", "PriceVnd", "IsActive",
    "CreatedAt", "UpdatedAt"
)
VALUES
(
    '90000000-0000-0000-0000-000000000002',
    '77777777-7777-7777-7777-777777777777',
    'Giảm cân, giảm mỡ, tăng cơ, dinh dưỡng chuyên sâu',
    'PT tăng cơ và giảm mỡ dành cho người mới',
    'Chào bạn, tôi là PT Coach MenuGreen với nhiều năm kinh nghiệm tư vấn thực đơn và lên kế hoạch luyện tập chuyên biệt.',
    6,
    'https://example.com/certificates/pt_coach.pdf',
    '0901234567',
    'TP. Hồ Chí Minh',
    '["Tiếng Việt","English"]',
    '["Theo sát số liệu","Nhẹ nhàng, động viên","Kỷ luật"]',
    '["Người mới","Trung cấp"]',
    '[{"Name":"NASM Certified Personal Trainer","Issuer":"National Academy of Sports Medicine","CredentialNumber":"NASM-CPT-MG-2024-0188","IssuedDate":"2024-01-15","ExpiryDate":"2028-01-15","ImageUrl":"https://placehold.co/1200x800/EAF4EF/14532D?text=NASM-CPT"},{"Name":"CPR and AED","Issuer":"American Safety Training Institute","CredentialNumber":"CPR-AED-2025-771","IssuedDate":"2025-02-10","ExpiryDate":"2027-02-10","ImageUrl":"https://placehold.co/1200x800/EFF6FF/1D4ED8?text=CPR-AED"}]',
    '["https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200","https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=1200","https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200","https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=1200"]',
    'Đã đồng hành cùng hơn 120 học viên.',
    'https://placehold.co/1200x800/F4F4F5/18181B?text=Identity+Coach+1',
    'Approved',
    now() - interval '1 hour',
    now(),
    500000,
    true,
    now(),
    now()
)
ON CONFLICT DO NOTHING;

COMMIT;
