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
('65ec6d7b-e59e-43ea-b97d-5c7852d91594', '76378876-43df-47db-88d1-1bee4c82077d', 'TXN_65ec6d7b', '999999999999', 790000, 'MG Topup 76378876', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('42eda18f-cd4b-4721-b56c-6c6f6bb8607a', '17605d97-f2f4-422b-90cc-4999a5f1fec0', 'TXN_42eda18f', '999999999999', 99000, 'MG Topup 17605d97', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('f04401b7-b994-4d4f-8b30-75b9b238e742', '0e6db154-5c4f-435a-95e3-937ef4092015', 'TXN_f04401b7', '999999999999', 790000, 'MG Topup 0e6db154', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('efe19b9b-14e2-428d-b524-6ed5ad983122', '856a1f59-b430-4386-b3c9-ba5bd1ddbdd3', 'TXN_efe19b9b', '999999999999', 99000, 'MG Topup 856a1f59', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('f46f1cae-d7f7-449f-9860-489636d27f30', 'f30d1b92-6926-433f-b4c8-d2cbfd559dc6', 'TXN_f46f1cae', '999999999999', 790000, 'MG Topup f30d1b92', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('f5f2cb80-6287-42d4-8757-e621da4025fe', 'ca3479ca-26f1-44db-a245-80371e7e2ce1', 'TXN_f5f2cb80', '999999999999', 99000, 'MG Topup ca3479ca', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('f573a4c2-1ca2-4fe2-905f-60aa94ab9787', 'b771fc44-c0d1-4175-af76-49e5ff5d64fb', 'TXN_f573a4c2', '999999999999', 790000, 'MG Topup b771fc44', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('abfe012f-314a-4053-a9f9-b35818ebb763', 'e2ae9d11-6e00-4f88-9b37-a5f5d3c0d5df', 'TXN_abfe012f', '999999999999', 99000, 'MG Topup e2ae9d11', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('b19bd645-e94d-45fb-a9aa-cbfd92124a37', '9236bd02-6f32-44b1-80a6-df311178ea2b', 'TXN_b19bd645', '999999999999', 790000, 'MG Topup 9236bd02', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('bd307c47-8151-4378-873d-490ffa990d0f', 'cca940d2-f4ad-432b-b6b2-99c504fb71f5', 'TXN_bd307c47', '999999999999', 99000, 'MG Topup cca940d2', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('a54ca10a-d773-4d99-a7b1-c806c94140c9', 'ee658c09-f558-4414-a659-c113b55f4125', 'TXN_a54ca10a', '999999999999', 790000, 'MG Topup ee658c09', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('b7ac0a16-995c-46b3-b5fa-58a0ab19cc3a', 'aeb230f1-5560-4e4d-b462-4c704843cdb7', 'TXN_b7ac0a16', '999999999999', 99000, 'MG Topup aeb230f1', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('30da5403-52ee-47ef-b5bc-1595838f82e2', '5cf0a99a-134f-45a1-9fae-55dee3227308', 'TXN_30da5403', '999999999999', 790000, 'MG Topup 5cf0a99a', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('b2b334c2-9325-4838-b702-d7c1563f548c', '482b0243-65d5-4eae-adf6-5b5b04452fd7', 'TXN_b2b334c2', '999999999999', 99000, 'MG Topup 482b0243', now() - interval '20 days', 'Success', '{}', now() - interval '20 days'),
('3f1933e0-45f2-472d-8567-9b9b9419937f', 'a8bccf2c-d4cb-4a4b-b6d2-7713d38ca525', 'TXN_3f1933e0', '999999999999', 790000, 'MG Topup a8bccf2c', now() - interval '20 days', 'Success', '{}', now() - interval '20 days')
ON CONFLICT DO NOTHING;

COMMIT;