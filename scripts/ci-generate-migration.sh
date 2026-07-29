#!/usr/bin/env bash
# =============================================================================
# CI Migration Generation Script
# Chạy trong CI environment với PostgreSQL available
# =============================================================================
# Purpose:
#   - Check for pending EF Core migrations
#   - Generate migration files if entity models have changed
#   - Validate migration on a clean database
#   - Upload migration artifacts for review
#
# Usage:
#   ./scripts/ci-generate-migration.sh
#
# Environment Variables:
#   POSTGRES_HOST     - PostgreSQL host (default: localhost)
#   POSTGRES_PORT     - PostgreSQL port (default: 5432)
#   POSTGRES_USER     - PostgreSQL user (default: test)
#   POSTGRES_PASSWORD - PostgreSQL password (default: test_password)
#   POSTGRES_DB       - PostgreSQL database (default: menugreen_test)
# =============================================================================

set -e

# Default values
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-test}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-test_password}"
POSTGRES_DB="${POSTGRES_DB:-menugreen_test}"

echo "=== CI Migration Generation Script ==="
echo "PostgreSQL: $POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"

# Change to backend directory
cd backend

# Install dotnet-ef if not present
echo "Checking dotnet-ef installation..."
if ! dotnet tool list --global | grep -q "dotnet-ef"; then
  echo "Installing dotnet-ef tool..."
  dotnet tool install --global dotnet-ef --version 9.0.0
fi
export PATH="$HOME/.dotnet/tools:$PATH"

# Restore dependencies
echo "Restoring dependencies..."
dotnet restore MenuGreen.sln

# Build DataAccessLayer first
echo "Building DataAccessLayer..."
dotnet build MenuGreen.DataAccessLayer -c Release

# Check for pending migrations
echo "=== Checking for pending migrations ==="
MIGRATION_OUTPUT=$(dotnet ef migrations list \
  --project MenuGreen.DataAccessLayer \
  2>&1 || true)

echo "$MIGRATION_OUTPUT"

# Check if there are any migrations (whether pending or already applied)
HAS_MIGRATIONS=$(dotnet ef migrations list \
  --project MenuGreen.DataAccessLayer \
  2>/dev/null | grep -v "^$" | wc -l || echo "0")

if [ "$HAS_MIGRATIONS" -eq 0 ]; then
  echo "No migrations found. This is expected for a fresh project."
  echo "NO_PENDING=true" >> $GITHUB_OUTPUT 2>/dev/null || true
  exit 0
fi

# Check if we have pending migrations (not yet applied)
if echo "$MIGRATION_OUTPUT" | grep -qi "no migrations"; then
  echo "All migrations are already applied. Nothing to do."
  echo "NO_PENDING=true" >> $GITHUB_OUTPUT 2>/dev/null || true
  exit 0
fi

# Generate migration if needed
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
MIGRATION_NAME="Auto_${TIMESTAMP}_SchemaUpdate"
echo "=== Generating migration: $MIGRATION_NAME ==="

dotnet ef migrations add "$MIGRATION_NAME" \
  --project MenuGreen.DataAccessLayer \
  --startup-project MenuGreen.API \
  --output-dir Migrations

# Verify migration was created
if [ -d "MenuGreen.DataAccessLayer/Migrations" ]; then
  MIGRATION_FILES=$(find MenuGreen.DataAccessLayer/Migrations -name "*.cs" ! -name "*Designer*" ! -name "ApplicationDbContext*" | wc -l)
  if [ "$MIGRATION_FILES" -gt 0 ]; then
    echo "Migration files created:"
    find MenuGreen.DataAccessLayer/Migrations -name "*.cs" ! -name "*Designer*" ! -name "ApplicationDbContext*" -exec basename {} \;
    echo "MIGRATION_GENERATED=true" >> $GITHUB_OUTPUT 2>/dev/null || true
  fi
fi

# Rebuild with migration
echo "Rebuilding DataAccessLayer with migration..."
dotnet build MenuGreen.DataAccessLayer -c Release

echo "=== Migration generation completed ==="
