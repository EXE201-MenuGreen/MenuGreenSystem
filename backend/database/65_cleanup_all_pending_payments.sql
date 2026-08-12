-- Migration: 65_cleanup_all_pending_payments
-- Date: 2026-08-12
-- Description: Cancel all pending SePay payments
-- Reason: Users cannot create new orders due to stale pending payments blocking them

-- This migration only updates pending SePay payments to CANCELLED.
-- The CANCELLED status was already added in migration 63.

-- Cancel all pending SePay payments
UPDATE payments
SET "Status" = 'CANCELLED',
    "UpdatedAt" = NOW()
WHERE "Provider" = 'SEPAY'
    AND "Status" = 'PENDING';
