-- Migration: 63_add_cancelled_payment_status
-- Date: 2026-08-12
-- Description: Add CANCELLED status to payments table CHECK constraint
-- Reason: SepayPaymentService.CancelOrderAsync needs to set Status = 'CANCELLED'

-- The base table creates a quoted, case-sensitive constraint name. Older
-- versions of this script accidentally created a second lowercase constraint.
ALTER TABLE payments DROP CONSTRAINT IF EXISTS "CK_payments_status";
ALTER TABLE payments DROP CONSTRAINT IF EXISTS ck_payments_status;
ALTER TABLE payments ADD CONSTRAINT "CK_payments_status"
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));
