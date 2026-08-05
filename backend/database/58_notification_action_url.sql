-- Notification deep-link target used by weekly-report and other actionable
-- notifications. Safe to run repeatedly.
BEGIN;

ALTER TABLE notifications
    ADD COLUMN IF NOT EXISTS "ActionUrl" character varying(500) NULL;

COMMIT;
