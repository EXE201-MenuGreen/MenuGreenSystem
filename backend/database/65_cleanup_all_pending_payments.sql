-- Migration: 65_cleanup_all_pending_payments
-- Date: 2026-08-12
-- Description: Cancel all pending SePay payments
-- Reason: Users cannot create new orders due to stale pending payments blocking them
--
-- NOTE: CANCELLED status was already added in migration 63.
-- This migration only updates pending SePay payments.

-- Step 1: Verify constraint exists (if not, skip step 1)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'CK_payments_status'
    ) THEN
        -- Drop and recreate to ensure CANCELLED is included
        ALTER TABLE payments DROP CONSTRAINT IF EXISTS CK_payments_status;
        ALTER TABLE payments ADD CONSTRAINT CK_payments_status 
            CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));
    END IF;
END $$;
LANGUAGE plpgsql;

-- Step 2: Cancel ALL pending SePay payments
UPDATE payments
SET "Status" = 'CANCELLED',
    "UpdatedAt" = NOW()
WHERE "Provider" = 'SEPAY'
    AND "Status" = 'PENDING';
