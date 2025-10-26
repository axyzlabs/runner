#!/bin/bash
# Health check script for GitHub Actions Runner container
# Provides /health/live and /health/ready endpoints
# Exit codes: 0 = healthy, 1 = unhealthy

set -euo pipefail

# Default to readiness check if no argument provided
CHECK_TYPE="${1:-ready}"

# Timestamp for logging
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Function to output JSON status
json_output() {
    local status="$1"
    local checks="$2"
    local exit_code="$3"

    cat <<EOF
{
  "status": "${status}",
  "timestamp": "${TIMESTAMP}",
  "checks": ${checks}
}
EOF
    exit "$exit_code"
}

# Liveness check - basic process health
if [ "$CHECK_TYPE" = "live" ] || [ "$CHECK_TYPE" = "liveness" ]; then
    # Simple liveness check - if script runs, container is alive
    json_output "healthy" '{"process": "running"}' 0
fi

# Readiness check - comprehensive health assessment
if [ "$CHECK_TYPE" = "ready" ] || [ "$CHECK_TYPE" = "readiness" ]; then
    CHECKS="{"
    ALL_HEALTHY=true

    # Check 1: Claude Code CLI
    if command -v claude &> /dev/null; then
        if claude --version &> /dev/null; then
            CHECKS="${CHECKS}\"claude_cli\": {\"status\": \"healthy\", \"version\": \"$(claude --version 2>&1 | head -n1)\"}"
        else
            CHECKS="${CHECKS}\"claude_cli\": {\"status\": \"unhealthy\", \"error\": \"version check failed\"}"
            ALL_HEALTHY=false
        fi
    else
        CHECKS="${CHECKS}\"claude_cli\": {\"status\": \"unhealthy\", \"error\": \"not found\"}"
        ALL_HEALTHY=false
    fi

    # Check 2: Go toolchain
    CHECKS="${CHECKS},"
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version 2>&1 | awk '{print $3}')
        CHECKS="${CHECKS}\"go\": {\"status\": \"healthy\", \"version\": \"${GO_VERSION}\"}"
    else
        CHECKS="${CHECKS}\"go\": {\"status\": \"unhealthy\", \"error\": \"not found\"}"
        ALL_HEALTHY=false
    fi

    # Check 3: Python
    CHECKS="${CHECKS},"
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        CHECKS="${CHECKS}\"python\": {\"status\": \"healthy\", \"version\": \"${PYTHON_VERSION}\"}"
    else
        CHECKS="${CHECKS}\"python\": {\"status\": \"unhealthy\", \"error\": \"not found\"}"
        ALL_HEALTHY=false
    fi

    # Check 4: Disk space (warn if < 1GB free)
    CHECKS="${CHECKS},"
    DISK_AVAIL=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$DISK_AVAIL" -gt 1 ]; then
        CHECKS="${CHECKS}\"disk_space\": {\"status\": \"healthy\", \"available_gb\": ${DISK_AVAIL}}"
    else
        CHECKS="${CHECKS}\"disk_space\": {\"status\": \"warning\", \"available_gb\": ${DISK_AVAIL}, \"message\": \"low disk space\"}"
        # Don't fail on low disk, just warn
    fi

    # Check 5: MCP configuration (optional)
    CHECKS="${CHECKS},"
    if [ -f "${HOME}/.claude/.mcp.json" ]; then
        CHECKS="${CHECKS}\"mcp_config\": {\"status\": \"healthy\", \"path\": \"${HOME}/.claude/.mcp.json\"}"
    else
        CHECKS="${CHECKS}\"mcp_config\": {\"status\": \"warning\", \"message\": \"not configured\"}"
        # MCP config is optional, don't fail
    fi

    # Check 6: OTEL Collector (optional, check if running)
    CHECKS="${CHECKS},"
    if pgrep -f "otelcol" > /dev/null 2>&1; then
        CHECKS="${CHECKS}\"otel_collector\": {\"status\": \"healthy\", \"running\": true}"
    else
        CHECKS="${CHECKS}\"otel_collector\": {\"status\": \"info\", \"running\": false, \"message\": \"not started or disabled\"}"
        # OTEL is optional, don't fail
    fi

    # Check 7: Memory usage (warn if > 80%)
    CHECKS="${CHECKS},"
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ] && [ -f /sys/fs/cgroup/memory/memory.usage_in_bytes ]; then
        MEMORY_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
        MEMORY_USAGE=$(cat /sys/fs/cgroup/memory/memory.usage_in_bytes)
        MEMORY_PERCENT=$((MEMORY_USAGE * 100 / MEMORY_LIMIT))

        if [ "$MEMORY_PERCENT" -lt 80 ]; then
            CHECKS="${CHECKS}\"memory\": {\"status\": \"healthy\", \"usage_percent\": ${MEMORY_PERCENT}}"
        else
            CHECKS="${CHECKS}\"memory\": {\"status\": \"warning\", \"usage_percent\": ${MEMORY_PERCENT}, \"message\": \"high memory usage\"}"
            # Don't fail on high memory, just warn
        fi
    else
        # Cgroup v2 or different path
        CHECKS="${CHECKS}\"memory\": {\"status\": \"info\", \"message\": \"metrics unavailable\"}"
    fi

    # Check 8: Workspace accessibility
    CHECKS="${CHECKS},"
    WORKSPACE="${WORKSPACE:-${CLAUDE_HOME}/workspace}"
    if [ -d "$WORKSPACE" ] && [ -w "$WORKSPACE" ]; then
        CHECKS="${CHECKS}\"workspace\": {\"status\": \"healthy\", \"path\": \"${WORKSPACE}\", \"writable\": true}"
    else
        CHECKS="${CHECKS}\"workspace\": {\"status\": \"unhealthy\", \"path\": \"${WORKSPACE}\", \"writable\": false}"
        ALL_HEALTHY=false
    fi

    CHECKS="${CHECKS}}"

    # Return overall health status
    if [ "$ALL_HEALTHY" = true ]; then
        json_output "healthy" "$CHECKS" 0
    else
        json_output "unhealthy" "$CHECKS" 1
    fi
fi

# Unknown check type
json_output "error" "{\"message\": \"Unknown check type: ${CHECK_TYPE}\"}" 1
