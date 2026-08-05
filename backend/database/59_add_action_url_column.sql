-- =============================================================================
-- MenuGreen Migration - Add ActionUrl column to notifications table
-- Sequence Number: 59
-- Description: Add missing ActionUrl column for deep-link support
-- Safe: uses IF NOT EXISTS to avoid errors on re-run
-- =============================================================================

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS "ActionUrl" character varying(500) NULL;

-- Optional: Add index for ActionUrl if needed for queries
-- CREATE INDEX IF NOT EXISTS idx_notifications_action_url ON notifications("ActionUrl");
