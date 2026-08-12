-- Check for pending payments that might be blocking new orders
-- Run this to see pending payments
SELECT 
    p."Id",
    p."UserId",
    p."Status",
    p."CreatedAt",
    p."ExpiredAt",
    us."Status" as "SubscriptionStatus"
FROM payments p
LEFT JOIN user_subscriptions us ON us."Id" = p."UserSubscriptionId"
WHERE p."Provider" = 'SEPAY' 
    AND p."Status" = 'PENDING'
ORDER BY p."CreatedAt" DESC;

-- Cleanup: Cancel all pending payments for subscriptions that are already cancelled
UPDATE payments
SET "Status" = 'CANCELLED',
    "UpdatedAt" = NOW()
WHERE "Provider" = 'SEPAY' 
    AND "Status" = 'PENDING'
    AND "UserSubscriptionId" IN (
        SELECT "Id" FROM user_subscriptions WHERE "Status" = 'Cancelled'
    );
