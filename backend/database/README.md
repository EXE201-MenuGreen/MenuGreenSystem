# MenuGreen SQL organization

- `01` through `58` are the canonical schema and seed files, ordered by foreign-key dependency.
- Put a table's columns, constraints, indexes, and canonical seed rows in that table's numbered file.

When adding a field, update the owning table's `CREATE TABLE` statement and canonical seed directly. Do not add another numbered `fix`, `add_column`, or compatibility file.

The 500-food catalog is embedded directly in `15_ingredients.sql` through
`18_recipe_ingredients.sql`. Generated nutrition values and prices are planning estimates
and should be reviewed before they are presented as authoritative values.

## Normalize legacy subscription roles in an existing database

The canonical account roles are `User`, `Coach`, and `Admin`. Subscription tiers
(`Free`, `Casual`, `Gymer`, and `Office`) belong in `user_subscriptions`, not in
`roles`. Do not rerun `01_roles.sql` against an existing database because it drops
the table with `CASCADE`. Apply the following transaction once instead:

```sql
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM roles
        WHERE "Id" = '00000000-0000-0000-0000-000000000001'
    ) THEN
        RAISE EXCEPTION 'Canonical User role is missing';
    END IF;
END $$;

UPDATE users
SET "RoleId" = '00000000-0000-0000-0000-000000000001',
    "UpdatedAt" = now()
WHERE "RoleId" IN (
    SELECT "Id"
    FROM roles
    WHERE lower("Name") IN ('user', 'free', 'casual', 'gymer', 'office')
);

DELETE FROM roles
WHERE "Id" <> '00000000-0000-0000-0000-000000000001'
  AND lower("Name") IN ('user', 'free', 'casual', 'gymer', 'office');

UPDATE roles
SET "Name" = 'User',
    "Description" = 'Standard application user',
    "UpdatedAt" = now()
WHERE "Id" = '00000000-0000-0000-0000-000000000001';

COMMIT;
```

Existing access tokens may continue to display a legacy role until refreshed,
but `UserOnly` endpoints authorize any valid authenticated account. Subscription
features continue to be enforced by their entitlement policies.
