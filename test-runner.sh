#!/bin/bash
# Test script for GitHub Actions Runner container
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="zeeke-ai-runner:latest"
CONTAINER_NAME="zeeke-ai-runner-test"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testing GitHub Actions Runner Container${NC}"
echo -e "${BLUE}========================================${NC}"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_command() {
    local TEST_NAME=$1
    local COMMAND=$2
    local EXPECTED=$3

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}Test ${TESTS_RUN}: ${TEST_NAME}${NC}"

    if docker exec "${CONTAINER_NAME}" bash -c "${COMMAND}" &> /dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up test container...${NC}"
    docker stop "${CONTAINER_NAME}" &> /dev/null || true
    docker rm "${CONTAINER_NAME}" &> /dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Check if image exists
echo -e "${BLUE}[1/4]${NC} Checking if image exists..."
if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
    echo -e "${RED}Error: Image ${IMAGE_NAME} not found${NC}"
    echo -e "${YELLOW}Build the image first with: ./docker/build.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Image found"

# Start test container
echo -e "${BLUE}[2/4]${NC} Starting test container..."
cleanup  # Cleanup any existing test container
docker run -d \
    --name "${CONTAINER_NAME}" \
    -v "$(pwd):/home/claude/workspace" \
    "${IMAGE_NAME}" \
    sleep 3600

echo -e "${GREEN}✓${NC} Container started"

# Run tests
echo -e "${BLUE}[3/4]${NC} Running tests..."

# Test: Claude Code installation
test_command "Claude Code installed" "claude --version"

# Test: Go installation
test_command "Go installed" "go version"

# Test: Python installation
test_command "Python installed" "python3 --version"

# Test: Node.js installation
test_command "Node.js installed" "node --version"

# Test: act installation
test_command "act installed" "act --version"

# Test: actionlint installation
test_command "actionlint installed" "actionlint --version"

# Test: gh CLI installation
test_command "gh CLI installed" "gh --version"

# Test: Go tools
test_command "golangci-lint installed" "golangci-lint --version"
test_command "staticcheck installed" "staticcheck -version"
test_command "goimports installed" "goimports --help"

# Test: Utilities
test_command "jq installed" "jq --version"
test_command "yq installed" "yq --version"
test_command "git installed" "git --version"

# Test: User and permissions
test_command "Running as claude user" "[ \$(whoami) = 'claude' ]"
test_command "Home directory exists" "[ -d /home/claude ]"
test_command "Workspace mounted" "[ -d /home/claude/workspace ]"

# Test: Claude configuration
test_command "Claude agents directory exists" "[ -d ~/.claude/agents ]"
test_command "Claude skills directory exists" "[ -d ~/.claude/skills ]"
test_command "MCP config exists" "[ -f ~/.claude/.mcp.json ]"

# Test: Project files
test_command "Project CLAUDE.md accessible" "[ -f /home/claude/workspace/CLAUDE.md ]"
test_command "Go modules accessible" "[ -f /home/claude/workspace/go.mod ]"
test_command "Workflows accessible" "[ -d /home/claude/workspace/.github/workflows ]"

# Test: Go environment
test_command "GOPATH set" "[ -n \"\$GOPATH\" ]"
test_command "GOBIN set" "[ -n \"\$GOBIN\" ]"
test_command "Go can build" "cd /home/claude/workspace && go build ./..."

# Test: Workflow validation
test_command "Can list workflows" "cd /home/claude/workspace && act -l"
test_command "Can validate workflows" "cd /home/claude/workspace && actionlint .github/workflows/ci.yml"

# Display results
echo -e "\n${BLUE}[4/4]${NC} Test Results"
echo -e "${BLUE}========================================${NC}"
echo -e "Total tests run:    ${TESTS_RUN}"
echo -e "${GREEN}Tests passed:       ${TESTS_PASSED}${NC}"
if [ ${TESTS_FAILED} -gt 0 ]; then
    echo -e "${RED}Tests failed:       ${TESTS_FAILED}${NC}"
else
    echo -e "Tests failed:       ${TESTS_FAILED}"
fi
echo -e "${BLUE}========================================${NC}"

# Exit with appropriate code
if [ ${TESTS_FAILED} -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
