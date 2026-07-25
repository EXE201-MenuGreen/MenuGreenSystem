-- =============================================================================
-- MenuGreen Seed Data - Table: campaigns
-- Sequence Number: 35 (must run before 35_notifications.sql)
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS campaigns CASCADE;

CREATE TABLE campaigns (
    "Id" uuid NOT NULL,
    "Name" character varying(200) NOT NULL,
    "TargetSegment" character varying(100) NOT NULL,
    "Title" character varying(200) NOT NULL,
    "Body" character varying(1000) NOT NULL,
    "StartDate" date NOT NULL,
    "EndDate" date NOT NULL,
    "SendTime" time without time zone NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "Status" character varying(50) NOT NULL DEFAULT 'Draft',
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_campaigns" PRIMARY KEY ("Id")
);

-- Seed Data for campaigns
INSERT INTO campaigns ("Id", "Name", "TargetSegment", "Title", "Body", "StartDate", "EndDate", "SendTime", "IsActive", "Status", "CreatedAt", "UpdatedAt")
VALUES
('c0000000-0000-0000-0000-000000000001', 'Re-engagement 7d', 'inactive_7_days', 'Chúng tôi nhớ bạn!', 'Hãy quay lại và tiếp tục hành trình ăn xanh cùng MenuGreen nhé.', CURRENT_DATE - 5, CURRENT_DATE + 30, '09:00:00', true, 'Running', now(), now()),
('c0000000-0000-0000-0000-000000000002', 'Pro Promo', 'all_users', 'Ưu đãi Pro 20%', 'Nâng cấp Pro ngay hôm nay để nhận thực đơn gym cá nhân hóa.', CURRENT_DATE, CURRENT_DATE + 15, '14:00:00', true, 'Draft', now(), now())
ON CONFLICT DO NOTHING;

COMMIT;
