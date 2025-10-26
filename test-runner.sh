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

echo -e "\n${YELLOW}Core Tools:${NC}"
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

# Test: gh CLI installation
test_command "gh CLI installed" "gh --version"

echo -e "\n${YELLOW}Go Tools:${NC}"
# Test: Go tools
test_command "golangci-lint installed" "golangci-lint --version"
test_command "staticcheck installed" "staticcheck -version"
test_command "goimports installed" "goimports --help"

echo -e "\n${YELLOW}Utilities:${NC}"
# Test: Utilities
test_command "jq installed" "jq --version"
test_command "yq installed" "yq --version"
test_command "git installed" "git --version"

echo -e "\n${YELLOW}User & Permissions:${NC}"
# Test: User and permissions
test_command "Running as claude user" "[ \$(whoami) = 'claude' ]"
test_command "Home directory exists" "[ -d /home/claude ]"
test_command "Workspace mounted" "[ -d /home/claude/workspace ]"

echo -e "\n${YELLOW}Claude Code Configuration:${NC}"
# Test: Claude configuration directories
test_command "Claude agents directory exists" "[ -d ~/.claude/agents ]"
test_command "Claude skills directory exists" "[ -d ~/.claude/skills ]"
test_command "Claude checkpoints directory exists" "[ -d ~/.claude/checkpoints ]"

# Test: Claude configuration files
test_command "MCP config exists" "[ -f ~/.claude/.mcp.json ]"
test_command "MCP config is valid JSON" "jq empty ~/.claude/.mcp.json"
test_command "Claude config exists" "[ -f ~/.config/claude/config.json ]"
test_command "Claude config is valid JSON" "jq empty ~/.config/claude/config.json"

# Test: MCP configuration content
test_command "MCP servers configured" "jq '.mcpServers | length > 0' ~/.claude/.mcp.json | grep -q true"
test_command "AWS docs server configured" "jq '.mcpServers | has(\"aws-docs\")' ~/.claude/.mcp.json | grep -q true"
test_command "Terraform server configured" "jq '.mcpServers | has(\"terraform\")' ~/.claude/.mcp.json | grep -q true"

# Test: Checkpoint configuration
test_command "Auto-checkpoint disabled" "jq '.checkpoint.auto' ~/.config/claude/config.json | grep -q false"
test_command "Checkpoint threshold set" "jq '.checkpoint.threshold' ~/.config/claude/config.json | grep -q 0.7"
test_command "Checkpoint directory configured" "jq -r '.checkpoint.checkpointDir' ~/.config/claude/config.json | grep -q /home/claude/.claude/checkpoints"
test_command "Checkpoint directory permissions" "[ \$(stat -c '%a' ~/.claude/checkpoints) = '700' ]"

echo -e "\n${YELLOW}Skills:${NC}"
# Test: Skills
test_command "Skills directory has content" "[ \$(find ~/.claude/skills -maxdepth 1 -type f -name '*.md' | wc -l) -ge 2 ]"
test_command "AWS docs skill exists" "[ -f ~/.claude/skills/aws-docs.md ]"
test_command "Terraform docs skill exists" "[ -f ~/.claude/skills/terraform-docs.md ]"

echo -e "\n${YELLOW}Python MCP Dependencies:${NC}"
# Test: Python MCP packages
test_command "Python MCP package installed" "python3 -c 'import mcp'"
test_command "Anthropic SDK installed" "python3 -c 'import anthropic'"
test_command "Python dotenv installed" "python3 -c 'import dotenv'"
test_command "Python pydantic installed" "python3 -c 'import pydantic'"

echo -e "\n${YELLOW}Project Files:${NC}"
# Test: Project files
test_command "Project CLAUDE.md accessible" "[ -f /home/claude/workspace/CLAUDE.md ]"
test_command "Go modules accessible" "[ -f /home/claude/workspace/go.mod ]"
test_command "Workflows accessible" "[ -d /home/claude/workspace/.github/workflows ]"

echo -e "\n${YELLOW}Go Environment:${NC}"
# Test: Go environment
test_command "GOPATH set" "[ -n \"\$GOPATH\" ]"
test_command "GOBIN set" "[ -n \"\$GOBIN\" ]"
test_command "Go can build" "cd /home/claude/workspace && go build ./..."

echo -e "\n${YELLOW}Workflow Validation:${NC}"
# Test: Workflow validation
test_command "Can list workflows" "cd /home/claude/workspace && act -l"

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
