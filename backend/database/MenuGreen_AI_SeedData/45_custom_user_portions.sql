-- =============================================================================
-- MenuGreen Seed Data - Table: custom_user_portions
-- Sequence Number: 45
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS custom_user_portions CASCADE;

CREATE TABLE custom_user_portions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "UnitName" character varying(150) NOT NULL,
    "GramsEquivalent" numeric(18,2) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_custom_user_portions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_custom_user_portions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_custom_user_portions_UserId_UnitName" ON custom_user_portions ("UserId", "UnitName");

-- Seed Data for custom_user_portions
INSERT INTO custom_user_portions ("Id", "UserId", "UnitName", "GramsEquivalent", "CreatedAt", "UpdatedAt")
VALUES
('55000000-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Tô sứ gia đình', 450.00, now(), now()),
('55000000-0000-0000-0000-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Chén cơm nhỏ', 120.00, now(), now())
ON CONFLICT DO NOTHING;

COMMIT;