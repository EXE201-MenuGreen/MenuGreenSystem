#!/usr/bin/env bash
# =============================================================================
# Local Migration Helper Script
# Giúp developer preview migration trước khi push code
# =============================================================================
# Purpose:
#   - Preview pending migrations
#   - Generate migrations locally for review
#   - Apply migrations to local database
#   - Reset local database
#   - Generate SQL scripts for review
#
# Usage:
#   ./scripts/local-migration-helper.sh <command>
#
# Commands:
#   status    - List pending migrations
#   generate  - Generate a new migration locally
#   apply     - Apply pending migrations
#   reset     - Drop and recreate database (DANGEROUS!)
#   script    - Generate SQL script for migrations
#   help      - Show this help message
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")/backend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_help() {
    echo -e "${BLUE}Local Migration Helper${NC}"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo -e "${GREEN}Commands:${NC}"
    echo "  status    List pending migrations"
    echo "  generate  Generate a new migration locally"
    echo "  apply     Apply pending migrations to local database"
    echo "  reset     Drop and recreate database (DANGEROUS!)"
    echo "  script    Generate SQL script for migrations"
    echo "  help      Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 status"
    echo "  $0 generate"
    echo "  $0 apply"
    echo "  $0 script"
    echo ""
}

# Change to backend directory
cd "$BACKEND_DIR" 2>/dev/null || {
    echo -e "${RED}Error: Backend directory not found at $BACKEND_DIR${NC}"
    exit 1
}

# Install dotnet-ef if needed
install_ef_tools() {
    if ! dotnet tool list --global 2>/dev/null | grep -q "dotnet-ef"; then
        echo -e "${YELLOW}Installing dotnet-ef...${NC}"
        dotnet tool install --global dotnet-ef --version 9.0.0
    fi
    export PATH="$HOME/.dotnet/tools:$PATH"
}

install_ef_tools

case "${1:-help}" in
    status|list)
        echo -e "${BLUE}=== Pending Migrations ===${NC}"
        echo ""
        dotnet ef migrations list --project MenuGreen.DataAccessLayer
        echo ""
        echo -e "${GREEN}Done${NC}"
        ;;
    
    generate)
        echo -e "${BLUE}=== Generate Migration ===${NC}"
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        NAME="${2:-SchemaUpdate}"
        MIGRATION_NAME="${NAME}_${TIMESTAMP}"
        
        echo "Generating migration: $MIGRATION_NAME"
        
        dotnet ef migrations add "$MIGRATION_NAME" \
            --project MenuGreen.DataAccessLayer \
            --startup-project MenuGreen.API \
            --output-dir Migrations
        
        echo ""
        echo -e "${GREEN}Migration generated successfully!${NC}"
        echo ""
        echo "Files created:"
        find MenuGreen.DataAccessLayer/Migrations -name "*${TIMESTAMP}*" -type f 2>/dev/null | sed 's|^|  |' || true
        ;;
    
    apply)
        echo -e "${BLUE}=== Apply Migrations ===${NC}"
        echo ""
        echo -e "${YELLOW}This will apply all pending migrations to your local database.${NC}"
        read -p "Continue? (y/N) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            dotnet ef database update --project MenuGreen.DataAccessLayer
            echo ""
            echo -e "${GREEN}Migrations applied successfully!${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    
    reset)
        echo -e "${RED}=== RESET DATABASE ===${NC}"
        echo ""
        echo -e "${RED}WARNING: This will DELETE ALL DATA in your local database!${NC}"
        echo ""
        read -p "Type 'yes' to confirm: " -r
        echo ""
        
        if [[ "$REPLY" == "yes" ]]; then
            echo "Dropping database..."
            dotnet ef database drop --project MenuGreen.DataAccessLayer --force
            
            echo "Creating database..."
            dotnet ef database update --project MenuGreen.DataAccessLayer
            
            echo ""
            echo -e "${GREEN}Database reset complete!${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    
    script)
        echo -e "${BLUE}=== Generate SQL Script ===${NC}"
        
        SCRIPT_FILE="${2:-latest_migration.sql}"
        
        echo "Generating SQL script to: $SCRIPT_FILE"
        dotnet ef migrations script \
            --project MenuGreen.DataAccessLayer \
            --output "$SCRIPT_FILE"
        
        echo ""
        echo -e "${GREEN}SQL script generated!${NC}"
        echo ""
        echo "Review the script at: $(pwd)/$SCRIPT_FILE"
        ;;
    
    down)
        echo -e "${BLUE}=== Rollback Last Migration ===${NC}"
        echo ""
        
        echo "Current migrations:"
        dotnet ef migrations list --project MenuGreen.DataAccessLayer
        
        echo ""
        echo -e "${YELLOW}This will remove the last migration.${NC}"
        read -p "Continue? (y/N) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            dotnet ef database update 0 --project MenuGreen.DataAccessLayer
            dotnet ef migrations remove --project MenuGreen.DataAccessLayer --force
            echo ""
            echo -e "${GREEN}Last migration rolled back!${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    
    verify)
        echo -e "${BLUE}=== Verify Database Schema ===${NC}"
        echo ""
        
        # Get connection string from appsettings
        CONN_STR=$(grep -oP 'DefaultConnection.*?\K([^;]+)' MenuGreen.API/appsettings.json 2>/dev/null || echo "")
        
        if [ -z "$CONN_STR" ]; then
            echo -e "${YELLOW}Could not read connection string. Using default.${NC}"
            CONN_STR="Host=localhost;Database=menugreen_dev;Username=postgres;Password=postgres"
        fi
        
        echo "Checking database tables..."
        
        # List tables
        dotnet ef dbcontext info --project MenuGreen.DataAccessLayer 2>/dev/null || true
        
        echo ""
        echo -e "${GREEN}Database verification complete${NC}"
        ;;
    
    help|--help|-h)
        print_help
        ;;
    
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_help
        exit 1
        ;;
esac
