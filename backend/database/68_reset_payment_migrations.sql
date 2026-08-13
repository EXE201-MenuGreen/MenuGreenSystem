-- Migration: 68_reset_payment_migrations
-- Date: 2026-08-12
-- Description: Reset migration tracking for broken payment migrations
-- Reason: Migrations 63, 65, 66, 67 have incorrect tracking records that caused failures

-- Remove incorrect tracking records so migrations can be re-applied.
-- Local/full seed runs do not create the production-only tracking table, so
-- guard the cleanup instead of failing the entire seed sequence.
DO $$
BEGIN
  IF to_regclass('public."_RawSqlMigrations"') IS NOT NULL THEN
    DELETE FROM "_RawSqlMigrations"
    WHERE "ScriptName" IN (
      '63_add_cancelled_payment_status.sql',
      '65_cleanup_all_pending_payments.sql',
      '66_fix_cancelled_payment_constraint.sql',
      '67_cleanup_and_fix_constraint.sql'
    );
  ELSE
    RAISE NOTICE 'Skipping migration tracking reset: table "_RawSqlMigrations" does not exist';
  END IF;
END $$;
