-- =============================================================================
-- MenuGreen Seed Data - Table: goal_drift_alerts
-- Sequence Number: 41
-- =============================================================================
BEGIN;

DROP TABLE IF EXISTS goal_drift_alerts CASCADE;

CREATE TABLE goal_drift_alerts (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "AlertType" character varying(50) NOT NULL,
    "Message" character varying(1000) NOT NULL,
    "AverageValue" numeric(18,2) NOT NULL,
    "TargetValue" numeric(18,2) NOT NULL,
    "PercentDeviation" numeric(18,2) NOT NULL,
    "IsAcknowledged" boolean NOT NULL DEFAULT false,
    "IsDismissed" boolean NOT NULL DEFAULT false,
    "CreatedAt" timestamp with time zone NOT NULL,
    "AcknowledgedAt" timestamp with time zone NULL,
    "DismissedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_goal_drift_alerts" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_goal_drift_alerts_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_goal_drift_alerts_UserId" ON goal_drift_alerts ("UserId");

-- Seed Data for goal_drift_alerts
INSERT INTO goal_drift_alerts ("Id", "UserId", "AlertType", "Message", "AverageValue", "TargetValue", "PercentDeviation", "IsAcknowledged", "IsDismissed", "CreatedAt", "AcknowledgedAt", "DismissedAt")
VALUES
('88888888-8888-8888-8888-888888888801', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'CalorieDrift', 'Lượng calo thực tế 7 ngày qua cao hơn 15.5% mục tiêu', 2310, 2000, 15.5, false, false, now() - interval '1 day', NULL, NULL),
('88888888-8888-8888-8888-888888888802', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'ProteinDeficit', 'Lượng đạm trung bình tuần qua thấp hơn 20% so với mục tiêu PT thiết lập', 96, 120, -20.0, false, false, now(), NULL, NULL)
ON CONFLICT DO NOTHING;

COMMIT;
