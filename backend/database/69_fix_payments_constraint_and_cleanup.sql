-- Migration: 69_fix_payments_constraint_and_cleanup
-- Date: 2026-08-12
-- Description: Fix CK_payments_status constraint then cleanup old pending payments
-- This is the single definitive migration that supersedes 63, 65, 66, 67, 68

-- Step 1: Fix constraint to include CANCELLED status
ALTER TABLE payments DROP CONSTRAINT IF EXISTS "CK_payments_status";
ALTER TABLE payments DROP CONSTRAINT IF EXISTS ck_payments_status;
ALTER TABLE payments ADD CONSTRAINT "CK_payments_status"
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));

-- Step 2: Cleanup old pending payments (older than 7 days)
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE "payments" 
    SET "Status" = 'CANCELLED', 
        "UpdatedAt" = NOW()
    WHERE "Status" = 'PENDING' 
      AND "CreatedAt" < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned up % old PENDING payments', updated_count;
END $$;
