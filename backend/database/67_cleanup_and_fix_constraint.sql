-- Migration: 67_cleanup_and_fix_constraint
-- Date: 2026-08-12
-- Description: Fix CK_payments_status constraint then cleanup old payments
-- This combines the constraint fix with the cleanup in one atomic migration

-- Step 1: Fix constraint to include CANCELLED status
ALTER TABLE payments DROP CONSTRAINT IF EXISTS CK_payments_status;
ALTER TABLE payments ADD CONSTRAINT CK_payments_status 
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));

-- Step 2: Cleanup old pending payments (older than 7 days)
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE "payments" 
    SET "Status" = 'CANCELLED' 
    WHERE "Status" = 'PENDING' 
      AND "CreatedAt" < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned up % old PENDING payments', updated_count;
END $$;
