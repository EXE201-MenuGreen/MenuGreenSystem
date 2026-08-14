# MenuGreen SQL organization

- `01` through `58` are the canonical schema and seed files, ordered by foreign-key dependency.
- Put a table's columns, constraints, indexes, and canonical seed rows in that table's numbered file.

When adding a field, update the owning table's `CREATE TABLE` statement and canonical seed directly. Do not add another numbered `fix`, `add_column`, or compatibility file.

The 500-food catalog is embedded directly in `15_ingredients.sql` through
`18_recipe_ingredients.sql`. Generated nutrition values and prices are planning estimates
and should be reviewed before they are presented as authoritative values.
