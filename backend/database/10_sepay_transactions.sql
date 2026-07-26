-- =============================================================================
-- MenuGreen Seed Data - Table: sepay_transactions
-- Sequence Number: 10
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS sepay_transactions CASCADE;

CREATE TABLE sepay_transactions (
    "Id" uuid NOT NULL,
    "PaymentId" uuid NOT NULL,
    "TransactionCode" character varying(128) NOT NULL,
    "BankAccount" character varying(64) NULL,
    "TransferAmount" integer NOT NULL,
    "TransferContent" character varying(256) NOT NULL,
    "TransactionTime" timestamp with time zone NOT NULL,
    "Status" character varying(32) NOT NULL,
    "RawPayloadJson" text NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_sepay_transactions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_sepay_transactions_payments_PaymentId" FOREIGN KEY ("PaymentId") REFERENCES payments ("Id") ON DELETE CASCADE
);

INSERT INTO sepay_transactions ("Id", "PaymentId", "TransactionCode", "BankAccount", "TransferAmount", "TransferContent", "TransactionTime", "Status", "RawPayloadJson", "CreatedAt")
VALUES
('efe19b9b-14e2-428d-b524-6ed5ad983122', '856a1f59-b430-4386-b3c9-ba5bd1ddbdd3', 'TXN_efe19b9b', '999999999999', 99000, 'MG Topup 856a1f59', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('f46f1cae-d7f7-449f-9860-489636d27f30', 'f30d1b92-6926-433f-b4c8-d2cbfd559dc6', 'TXN_f46f1cae', '999999999999', 790000, 'MG Topup f30d1b92', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('bd307c47-8151-4378-873d-490ffa990d0f', 'cca940d2-f4ad-432b-b6b2-99c504fb71f5', 'TXN_bd307c47', '999999999999', 99000, 'MG Topup cca940d2', now() - interval '20 days', 'Success', '{}', now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;
