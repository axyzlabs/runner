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
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test function with output validation
test_command_output() {
    local TEST_NAME=$1
    local COMMAND=$2
    local EXPECTED_PATTERN=$3

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}Test ${TESTS_RUN}: ${TEST_NAME}${NC}"

    OUTPUT=$(docker exec "${CONTAINER_NAME}" bash -c "${COMMAND}" 2>&1)
    if echo "$OUTPUT" | grep -q "$EXPECTED_PATTERN"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo -e "${YELLOW}Expected pattern: ${EXPECTED_PATTERN}${NC}"
        echo -e "${YELLOW}Got: ${OUTPUT}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
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
echo -e "${BLUE}[1/5]${NC} Checking if image exists..."
if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
    echo -e "${RED}Error: Image ${IMAGE_NAME} not found${NC}"
    echo -e "${YELLOW}Build the image first with: ./build.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Image found"

# Start test container
echo -e "${BLUE}[2/5]${NC} Starting test container..."
cleanup  # Cleanup any existing test container
docker run -d \
    --name "${CONTAINER_NAME}" \
    -v "$(pwd):/home/claude/workspace" \
    -e ENABLE_OTEL=true \
    -e USE_JSON_LOGS=false \
    -p 8889:8889 \
    "${IMAGE_NAME}" \
    sleep 3600

echo -e "${GREEN}✓${NC} Container started"

# Wait for container to be fully ready
echo -e "${BLUE}[3/5]${NC} Waiting for container initialization..."
sleep 5

# Run basic tests
echo -e "${BLUE}[4/5]${NC} Running tests..."

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

# Test: Project files
test_command "Project CLAUDE.md accessible" "[ -f /home/claude/workspace/CLAUDE.md ]"
test_command "Workflows accessible" "[ -d /home/claude/workspace/.github/workflows ]"

# Test: Go environment
test_command "GOPATH set" "[ -n \"\$GOPATH\" ]"
test_command "GOBIN set" "[ -n \"\$GOBIN\" ]"

# Test: Workflow validation
test_command "Can list workflows" "cd /home/claude/workspace && act -l"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Observability & Monitoring Tests${NC}"
echo -e "${BLUE}========================================${NC}"

# Test: OpenTelemetry Collector installation
test_command "OTEL Collector installed" "command -v otelcol"
test_command_output "OTEL Collector version" "otelcol --version" "0.93.0"

# Test: OTEL Collector running
test_command "OTEL Collector process running" "pgrep -f otelcol"

# Test: OTEL configuration exists
test_command "OTEL config exists" "[ -f /etc/otel/config.yaml ]"

# Test: Health check script exists and is executable
test_command "Health check script exists" "[ -x /usr/local/bin/health-check ]"

# Test: Log wrapper script exists and is executable
test_command "Log wrapper script exists" "[ -x /usr/local/bin/log-wrapper ]"

# Test: Health check endpoints
test_command_output "Liveness check returns healthy" "/usr/local/bin/health-check live" '"status": "healthy"'
test_command_output "Readiness check returns status" "/usr/local/bin/health-check ready" '"status":'

# Test: Structured logging wrapper
test_command_output "Log wrapper INFO level" "/usr/local/bin/log-wrapper INFO 'Test message' key1=value1" '"level":"INFO"'
test_command_output "Log wrapper includes timestamp" "/usr/local/bin/log-wrapper INFO 'Test'" '"timestamp":'
test_command_output "Log wrapper includes context" "/usr/local/bin/log-wrapper INFO 'Test' foo=bar" '"foo": "bar"'

# Test: Prometheus metrics endpoint
echo -e "\n${BLUE}Test: Prometheus metrics endpoint${NC}"
sleep 3  # Give OTEL Collector a moment to fully start
if docker exec "${CONTAINER_NAME}" bash -c "curl -s http://localhost:8889/metrics" | grep -q "# TYPE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo -e "${YELLOW}Checking OTEL logs:${NC}"
    docker exec "${CONTAINER_NAME}" bash -c "cat /tmp/otelcol.log" || echo "No OTEL logs found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test: Metrics contain expected data
test_command_output "Metrics contain runner namespace" "curl -s http://localhost:8889/metrics" "runner_"

# Test: Environment variables set correctly
test_command "ENABLE_OTEL environment variable" "[ \"\$ENABLE_OTEL\" = \"true\" ]"
test_command "LOG_LEVEL environment variable set" "[ -n \"\$LOG_LEVEL\" ]"

# Test: Port 8889 is exposed
echo -e "\n${BLUE}Test: Port 8889 exposed on host${NC}"
if curl -s http://localhost:8889/metrics | grep -q "# TYPE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Performance impact test
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Performance Impact Assessment${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${BLUE}Measuring resource usage...${NC}"
STATS=$(docker stats "${CONTAINER_NAME}" --no-stream --format "CPU: {{.CPUPerc}}, Memory: {{.MemPerc}}")
echo -e "${GREEN}Container stats: ${STATS}${NC}"

# Extract CPU percentage (remove % sign for comparison)
CPU_PERCENT=$(echo "$STATS" | grep -oP 'CPU: \K[0-9.]+')
echo -e "${BLUE}CPU Usage: ${CPU_PERCENT}%${NC}"

# Note: In idle state, we expect very low CPU usage
# OTEL collector overhead should be minimal when idle
if (( $(echo "$CPU_PERCENT < 10.0" | bc -l) )); then
    echo -e "${GREEN}✓ CPU usage within acceptable range (<10%)${NC}"
else
    echo -e "${YELLOW}⚠ CPU usage higher than expected (${CPU_PERCENT}%), but this may be normal during initialization${NC}"
fi

# Display results
echo -e "\n${BLUE}[5/5]${NC} Test Results"
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
