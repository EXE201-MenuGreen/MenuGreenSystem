-- Migration: 68_reset_payment_migrations
-- Date: 2026-08-12
-- Description: Reset migration tracking for broken payment migrations
-- Reason: Migrations 63, 65, 66, 67 have incorrect tracking records that caused failures

-- Remove incorrect tracking records so migrations can be re-applied
DELETE FROM "_RawSqlMigrations" WHERE "ScriptName" IN (
  '63_add_cancelled_payment_status.sql',
  '65_cleanup_all_pending_payments.sql',
  '66_fix_cancelled_payment_constraint.sql',
  '67_cleanup_and_fix_constraint.sql'
);
