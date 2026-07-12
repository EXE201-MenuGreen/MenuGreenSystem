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
    "Bio" text NOT NULL,
    "ExperienceYears" integer NOT NULL,
    "CertificateUrl" text NULL,
    "PriceVnd" integer NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_coach_profiles" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_coach_profiles_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

-- Seed Data for coach_profiles
INSERT INTO coach_profiles ("Id", "UserId", "Specialty", "Bio", "ExperienceYears", "CertificateUrl", "PriceVnd", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
('90000000-0000-0000-0000-000000000001', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Tăng cơ giảm mỡ & Thể hình chuyên nghiệp', 'Chào bạn, tôi là PT Hoàng Thị Premium với hơn 5 năm kinh nghiệm huấn luyện thể hình và thiết kế thực đơn ăn uống lành mạnh.', 5, 'https://example.com/certificates/pt_premium.pdf', 500000, true, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;