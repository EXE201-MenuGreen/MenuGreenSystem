-- Migration: 63_add_cancelled_payment_status
-- Date: 2026-08-12
-- Description: Add CANCELLED status to payments table CHECK constraint
-- Reason: SepayPaymentService.CancelOrderAsync needs to set Status = 'CANCELLED'

-- Drop existing constraint and add new one with CANCELLED
ALTER TABLE payments DROP CONSTRAINT IF EXISTS CK_payments_status;
ALTER TABLE payments ADD CONSTRAINT CK_payments_status 
    CHECK ("Status" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED'));
