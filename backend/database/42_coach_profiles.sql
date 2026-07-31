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
('90000000-0000-0000-0000-000000000002', '77777777-7777-7777-7777-777777777777', 'Huấn luyện viên PT & Dinh dưỡng chuyên sâu', 'Chào bạn, tôi là PT Coach MenuGreen với nhiều năm kinh nghiệm tư vấn thực đơn và lên kế hoạch luyện tập chuyên biệt.', 6, 'https://example.com/certificates/pt_coach.pdf', 500000, true, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;
