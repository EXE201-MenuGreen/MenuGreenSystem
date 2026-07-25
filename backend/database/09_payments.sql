-- =============================================================================
-- MenuGreen Seed Data - Table: payments
-- Sequence Number: 09
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS payments CASCADE;

CREATE TABLE payments (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "UserSubscriptionId" uuid NULL,
    "UserPremiumProgramId" uuid NULL,
    "AmountVnd" integer NOT NULL,
    "Status" character varying(32) NOT NULL,
    "PaymentMethod" character varying(32) NOT NULL,
    "Provider" character varying(32) NOT NULL,
    "ProviderOrderCode" character varying(128) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NULL,
    "ExpiredAt" timestamp with time zone NULL,
    "PaidAt" timestamp with time zone NULL,
    CONSTRAINT "PK_payments" PRIMARY KEY ("Id"),
    CONSTRAINT "CK_payments_status" CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED')),
    CONSTRAINT "FK_payments_user_subscriptions_UserSubscriptionId" FOREIGN KEY ("UserSubscriptionId") REFERENCES user_subscriptions ("Id") ON DELETE SET NULL
);

CREATE INDEX "IX_payments_UserPremiumProgramId" ON payments ("UserPremiumProgramId");

INSERT INTO payments ("Id", "UserId", "UserSubscriptionId", "AmountVnd", "Status", "PaymentMethod", "Provider", "ProviderOrderCode", "CreatedAt", "UpdatedAt", "ExpiredAt", "PaidAt")
VALUES
('856a1f59-b430-4386-b3c9-ba5bd1ddbdd3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '00e3373b-a66f-4ae4-acf1-873d4f21e735', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_856a1f59', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('f30d1b92-6926-433f-b4c8-d2cbfd559dc6', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '5a589d0c-0879-4211-bcde-b80d8f872a2c', 790000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_f30d1b92', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days'),
('cca940d2-f4ad-432b-b6b2-99c504fb71f5', '586209d0-d3c4-43a4-bba7-5d4c73b37bc1', '137a2257-8c0b-4b56-b4fa-be8da55e7c14', 99000, 'PAID', 'QR_CODE', 'SEPAY', 'ORDER_cca940d2', now() - interval '20 days', now() - interval '20 days', NULL, now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;
