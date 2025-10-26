#!/bin/bash
# SECURITY: Secret validation script
# Scans for common secret patterns to prevent accidental commits
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Secret patterns to detect
SECRET_PATTERNS=(
    # API Keys
    "ANTHROPIC_API_KEY="
    "GITHUB_TOKEN="
    "OPENAI_API_KEY="
    "AWS_ACCESS_KEY"
    "AWS_SECRET_KEY"
    "AZURE_CLIENT_SECRET"
    "GCP_SERVICE_ACCOUNT"

    # Private Keys
    "BEGIN RSA PRIVATE KEY"
    "BEGIN DSA PRIVATE KEY"
    "BEGIN EC PRIVATE KEY"
    "BEGIN OPENSSH PRIVATE KEY"
    "BEGIN PGP PRIVATE KEY"

    # Passwords
    "password="
    "passwd="
    "pwd="

    # Tokens
    "bearer "
    "token="
    "auth="

    # Connection Strings
    "jdbc:"
    "mongodb://"
    "postgres://"
    "mysql://"
)

# Files to skip
SKIP_PATTERNS=(
    ".git/"
    ".github/"
    "node_modules/"
    "vendor/"
    "*.example"
    "*.md"
    "validate-secrets.sh"
)

echo -e "${BLUE}=== Secret Validation Scanner ===${NC}"
echo "Scanning for secret patterns in repository..."
echo ""

# Build grep exclude arguments
EXCLUDE_ARGS=""
for pattern in "${SKIP_PATTERNS[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$pattern"
done

FOUND_SECRETS=0

# Scan for each pattern
for pattern in "${SECRET_PATTERNS[@]}"; do
    echo -e "${BLUE}Checking for pattern: ${NC}$pattern"

    # Use grep to find matches (case insensitive)
    if grep -rni $EXCLUDE_ARGS "$pattern" . 2>/dev/null; then
        echo -e "${RED}✗ Found potential secret: $pattern${NC}"
        FOUND_SECRETS=$((FOUND_SECRETS + 1))
    fi
done

echo ""
echo -e "${BLUE}=== Validation Results ===${NC}"

if [ $FOUND_SECRETS -gt 0 ]; then
    echo -e "${RED}✗ FAILED: Found $FOUND_SECRETS potential secret(s)${NC}"
    echo ""
    echo "Please review the findings above and:"
    echo "1. Remove any actual secrets from tracked files"
    echo "2. Add secret files to .gitignore"
    echo "3. Use environment variables or secret managers instead"
    echo "4. If false positive, update this script's exclusions"
    echo ""
    exit 1
else
    echo -e "${GREEN}✓ PASSED: No secrets detected${NC}"
    echo ""
    exit 0
fi
