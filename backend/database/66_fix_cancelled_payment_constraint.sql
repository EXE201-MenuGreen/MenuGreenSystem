-- Migration: 66_fix_cancelled_payment_constraint
-- Date: 2026-08-12
-- Description: Fix CK_payments_status constraint to include CANCELLED
-- Reason: Migration 63 may have failed to update the constraint on production

-- Drop existing constraint
ALTER TABLE payments DROP CONSTRAINT IF EXISTS "CK_payments_status";
ALTER TABLE payments DROP CONSTRAINT IF EXISTS ck_payments_status;

-- Add constraint with CANCELLED
ALTER TABLE payments ADD CONSTRAINT "CK_payments_status"
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));
