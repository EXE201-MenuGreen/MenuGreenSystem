#!/bin/bash
# Generate htpasswd file for Nginx basic auth
# Usage: ./generate-password.sh username

set -e

HTPASSWD_FILE="./monitoring/nginx/.htpasswd"

if [ -z "$1" ]; then
    echo "Usage: ./generate-password.sh <username>"
    echo "Example: ./generate-password.sh admin"
    exit 1
fi

USERNAME=$1

# Check if htpasswd exists, if not create it
if [ ! -f "$HTPASSWD_FILE" ]; then
    echo "Creating new htpasswd file..."
    touch "$HTPASSWD_FILE"
fi

# Generate password
echo "Enter password for $USERNAME:"
read -s PASSWORD

# Generate htpasswd entry
# Using openssl (works on most systems)
PASSWORD_HASH=$(openssl passwd -apr1 "$PASSWORD")

# Add to htpasswd file
echo "$USERNAME:$PASSWORD_HASH" >> "$HTPASSWD_FILE"

echo ""
echo "✅ User '$USERNAME' added to htpasswd file"
echo "📁 File location: $HTPASSWD_FILE"
