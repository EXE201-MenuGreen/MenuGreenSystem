-- Migration: 65_cleanup_all_pending_payments
-- Date: 2026-08-12
-- Description: Reset payments CHECK constraint and cancel all pending SePay payments
-- Reason: Users cannot create new orders due to stale pending payments blocking them

-- Step 1: Reset CHECK constraint to allow CANCELLED status
ALTER TABLE payments DROP CONSTRAINT IF EXISTS CK_payments_status;
ALTER TABLE payments ADD CONSTRAINT CK_payments_status 
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));

-- Step 2: Cancel ALL pending SePay payments
UPDATE payments
SET "Status" = 'CANCELLED',
    "UpdatedAt" = NOW()
WHERE "Provider" = 'SEPAY'
    AND "Status" = 'PENDING';
