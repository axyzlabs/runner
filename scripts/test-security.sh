#!/bin/bash
# SECURITY: Comprehensive security test suite
# Tests all security controls and hardening measures
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="${1:-zeeke-ai-runner:latest}"
CONTAINER_NAME="security-test-$$"

echo -e "${BLUE}=== Security Test Suite ===${NC}"
echo "Image: $IMAGE_NAME"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run tests
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -e "${BLUE}Testing: ${test_name}${NC}"

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Test 1: Verify no sudo in image
test_no_sudo() {
    echo "Checking if sudo is NOT installed..."
    ! docker run --rm "$IMAGE_NAME" which sudo &>/dev/null
}

# Test 2: Verify running as non-root
test_non_root() {
    echo "Checking container runs as non-root (UID 1001)..."
    local uid=$(docker run --rm "$IMAGE_NAME" id -u)
    [ "$uid" = "1001" ]
}

# Test 3: Verify user is 'claude'
test_claude_user() {
    echo "Checking container runs as 'claude' user..."
    local username=$(docker run --rm "$IMAGE_NAME" whoami)
    [ "$username" = "claude" ]
}

# Test 4: Test PID limits (fork bomb protection)
test_pid_limits() {
    echo "Testing PID limits (fork bomb protection)..."

    # Start container with PID limit
    docker run -d --name "$CONTAINER_NAME" --pids-limit 100 "$IMAGE_NAME" sleep 300 &>/dev/null

    # Try to trigger fork bomb (should fail safely)
    docker exec "$CONTAINER_NAME" bash -c ':(){ :|:& };:' &>/dev/null && RESULT=1 || RESULT=0

    # Cleanup
    docker rm -f "$CONTAINER_NAME" &>/dev/null

    # Should fail (return 0) due to PID limit
    [ $RESULT -eq 0 ]
}

# Test 5: Verify Trivy is installed
test_trivy_installed() {
    echo "Checking if Trivy scanner is installed..."
    docker run --rm "$IMAGE_NAME" trivy --version &>/dev/null
}

# Test 6: Verify required tools are present
test_required_tools() {
    echo "Checking if required tools are installed..."
    docker run --rm "$IMAGE_NAME" bash -c "
        claude --version && \
        go version && \
        python3 --version && \
        node --version && \
        git --version && \
        gh --version && \
        act --version
    " &>/dev/null
}

# Test 7: Verify Go tools work without root
test_go_tools_nonroot() {
    echo "Checking if Go tools work as non-root user..."
    docker run --rm "$IMAGE_NAME" bash -c "
        golangci-lint --version && \
        goimports -h
    " &>/dev/null
}

# Test 8: Check file permissions on sensitive directories
test_file_permissions() {
    echo "Checking file permissions..."
    docker run --rm "$IMAGE_NAME" bash -c "
        # Check home directory ownership
        [ \$(stat -c '%U' /home/claude) = 'claude' ] && \
        # Check Go directory ownership
        [ \$(stat -c '%U' /go) = 'claude' ]
    " &>/dev/null
}

# Test 9: Verify no world-writable files
test_no_world_writable() {
    echo "Checking for world-writable files..."
    local count=$(docker run --rm "$IMAGE_NAME" find /home/claude -type f -perm -002 2>/dev/null | wc -l)
    [ "$count" -eq 0 ]
}

# Test 10: Verify Docker socket access (for act)
test_docker_socket() {
    echo "Checking Docker socket access (if mounted)..."
    # This test just verifies the container can check for docker
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock "$IMAGE_NAME" \
        test -S /var/run/docker.sock
}

# Run all tests
echo -e "${BLUE}=== Running Security Tests ===${NC}"
echo ""

run_test "No sudo in image" test_no_sudo
run_test "Running as non-root (UID 1001)" test_non_root
run_test "Running as 'claude' user" test_claude_user
run_test "PID limits (fork bomb protection)" test_pid_limits
run_test "Trivy scanner installed" test_trivy_installed
run_test "Required tools present" test_required_tools
run_test "Go tools work without root" test_go_tools_nonroot
run_test "File permissions correct" test_file_permissions
run_test "No world-writable files" test_no_world_writable
run_test "Docker socket accessible" test_docker_socket

# Print summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    exit 1
fi
