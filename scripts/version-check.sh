#!/bin/bash
# Version check script for all DevOps tools in the runner image
# This script verifies that all required tools are installed with correct versions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Expected versions
EXPECTED_AWS_CLI="2.15.17"
EXPECTED_TERRAFORM="1.7.3"
EXPECTED_TFLINT="0.50.3"
EXPECTED_KUBECTL="1.29.2"
EXPECTED_HELM="3.14.2"
EXPECTED_K9S="0.32.4"
EXPECTED_DOCKER_COMPOSE="2.24.6"
EXPECTED_YQ="4.42.1"
EXPECTED_JQ="1.7.1"

# Counters
TOTAL_TOOLS=0
TOOLS_OK=0
TOOLS_MISSING=0
TOOLS_VERSION_MISMATCH=0

# Check function
check_tool() {
    local tool_name=$1
    local version_cmd=$2
    local expected_version=$3
    local version_extract=$4  # sed/awk command to extract version

    TOTAL_TOOLS=$((TOTAL_TOOLS + 1))

    if ! command -v "${tool_name}" &> /dev/null; then
        echo -e "${RED}✗${NC} ${tool_name}: NOT FOUND"
        TOOLS_MISSING=$((TOOLS_MISSING + 1))
        return 1
    fi

    local actual_version
    actual_version=$(eval "${version_cmd}" 2>/dev/null | eval "${version_extract}" || echo "unknown")

    if [[ "${actual_version}" == "${expected_version}" ]]; then
        echo -e "${GREEN}✓${NC} ${tool_name}: ${actual_version}"
        TOOLS_OK=$((TOOLS_OK + 1))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} ${tool_name}: ${actual_version} (expected: ${expected_version})"
        TOOLS_VERSION_MISMATCH=$((TOOLS_VERSION_MISMATCH + 1))
        return 0
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DevOps Tools Version Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check AWS CLI
check_tool "aws" \
    "aws --version" \
    "${EXPECTED_AWS_CLI}" \
    "awk '{print \$1}' | cut -d'/' -f2"

# Check Terraform
check_tool "terraform" \
    "terraform version" \
    "${EXPECTED_TERRAFORM}" \
    "head -n1 | awk '{print \$2}' | sed 's/^v//'"

# Check tflint
check_tool "tflint" \
    "tflint --version" \
    "${EXPECTED_TFLINT}" \
    "head -n1 | awk '{print \$3}' | sed 's/^v//'"

# Check kubectl
check_tool "kubectl" \
    "kubectl version --client=true --output=json" \
    "${EXPECTED_KUBECTL}" \
    "jq -r '.clientVersion.gitVersion' | sed 's/^v//'"

# Check Helm
check_tool "helm" \
    "helm version" \
    "${EXPECTED_HELM}" \
    "awk '{print \$1}' | cut -d':' -f2 | sed 's/^v//; s/\"//g'"

# Check k9s
check_tool "k9s" \
    "k9s version" \
    "${EXPECTED_K9S}" \
    "grep Version | awk '{print \$2}' | sed 's/^v//'"

# Check Docker Compose
check_tool "docker-compose" \
    "docker-compose version --short" \
    "${EXPECTED_DOCKER_COMPOSE}" \
    "cat"

# Check yq
check_tool "yq" \
    "yq --version" \
    "${EXPECTED_YQ}" \
    "awk '{print \$NF}' | sed 's/^v//'"

# Check jq
check_tool "jq" \
    "jq --version" \
    "${EXPECTED_JQ}" \
    "sed 's/jq-//'"

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total tools checked:     ${TOTAL_TOOLS}"
echo -e "${GREEN}Tools OK:                ${TOOLS_OK}${NC}"

if [ ${TOOLS_MISSING} -gt 0 ]; then
    echo -e "${RED}Tools missing:           ${TOOLS_MISSING}${NC}"
fi

if [ ${TOOLS_VERSION_MISMATCH} -gt 0 ]; then
    echo -e "${YELLOW}Version mismatches:      ${TOOLS_VERSION_MISMATCH}${NC}"
fi

echo -e "${BLUE}========================================${NC}"

# Exit with error if any tools are missing
if [ ${TOOLS_MISSING} -gt 0 ]; then
    echo -e "${RED}ERROR: Some required tools are missing!${NC}"
    exit 1
fi

# Exit successfully (version mismatches are warnings, not errors)
exit 0
