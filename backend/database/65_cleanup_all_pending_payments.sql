-- Migration: 65_cleanup_all_pending_payments
-- Date: 2026-08-12
-- Description: Cancel all pending SePay payments
-- Reason: Users cannot create new orders due to stale pending payments blocking them

-- First, ensure constraint allows CANCELLED
ALTER TABLE payments DROP CONSTRAINT IF EXISTS "CK_payments_status";
ALTER TABLE payments DROP CONSTRAINT IF EXISTS ck_payments_status;
ALTER TABLE payments ADD CONSTRAINT "CK_payments_status"
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));

-- Cancel all pending SePay payments
UPDATE payments
SET "Status" = 'CANCELLED',
    "UpdatedAt" = NOW()
WHERE "Provider" = 'SEPAY'
    AND "Status" = 'PENDING';
