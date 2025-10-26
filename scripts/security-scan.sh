#!/bin/bash
# SECURITY: Trivy vulnerability scanner integration
# Scans Docker images for vulnerabilities
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="${1:-zeeke-ai-runner:latest}"
SEVERITY="${2:-HIGH,CRITICAL}"
EXIT_CODE_THRESHOLD="${3:-0}"

echo -e "${BLUE}=== Trivy Security Scanner ===${NC}"
echo "Image: $IMAGE_NAME"
echo "Severity: $SEVERITY"
echo "Exit code threshold: $EXIT_CODE_THRESHOLD"
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}✗ Trivy not found. Installing...${NC}"

    TRIVY_VERSION="0.48.3"
    wget -qO /tmp/trivy.tar.gz \
        "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
    tar xzf /tmp/trivy.tar.gz -C /tmp/
    sudo mv /tmp/trivy /usr/local/bin/
    rm /tmp/trivy.tar.gz

    echo -e "${GREEN}✓ Trivy installed${NC}"
fi

# Update vulnerability database
echo -e "${BLUE}Updating vulnerability database...${NC}"
trivy image --download-db-only

echo ""
echo -e "${BLUE}=== Scanning Image ===${NC}"

# Run Trivy scan
trivy image \
    --severity "$SEVERITY" \
    --exit-code "$EXIT_CODE_THRESHOLD" \
    --no-progress \
    "$IMAGE_NAME"

SCAN_EXIT_CODE=$?

echo ""
echo -e "${BLUE}=== Scan Results ===${NC}"

if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED: No vulnerabilities found (severity: $SEVERITY)${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ FAILED: Vulnerabilities detected (severity: $SEVERITY)${NC}"
    echo ""
    echo "To fix vulnerabilities:"
    echo "1. Update base image to latest secure version"
    echo "2. Update vulnerable packages in Dockerfile"
    echo "3. Review Trivy output above for specific CVEs"
    echo "4. Check for available patches"
    echo ""
    exit $SCAN_EXIT_CODE
fi
