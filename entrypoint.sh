#!/bin/bash
# Entrypoint script for GitHub Actions Runner with Claude Code
set -e

# Source structured logging
source /usr/local/bin/log-wrapper

# Color output (for non-JSON logs)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine if we should use structured logging
USE_JSON_LOGS="${USE_JSON_LOGS:-true}"

# Logging functions
log_info() {
    if [ "$USE_JSON_LOGS" = "true" ]; then
        log_json "INFO" "$1" "component=entrypoint"
    else
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

log_warn() {
    if [ "$USE_JSON_LOGS" = "true" ]; then
        log_json "WARN" "$1" "component=entrypoint"
    else
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

log_error() {
    if [ "$USE_JSON_LOGS" = "true" ]; then
        log_json "ERROR" "$1" "component=entrypoint"
    else
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

log_debug() {
    if [ "$USE_JSON_LOGS" = "true" ]; then
        log_json "DEBUG" "$1" "component=entrypoint"
    else
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GitHub Actions Runner with Claude Code${NC}"
echo -e "${BLUE}========================================${NC}"

# Start OpenTelemetry Collector if enabled
if [ "${ENABLE_OTEL:-true}" = "true" ]; then
    log_info "Starting OpenTelemetry Collector..."

    # Check if OTEL config exists
    if [ -f /etc/otel/config.yaml ]; then
        # Start OTEL Collector in background as root (needs access to host metrics)
        sudo /usr/local/bin/otelcol --config=/etc/otel/config.yaml > /tmp/otelcol.log 2>&1 &
        OTEL_PID=$!

        # Wait a moment for OTEL to start
        sleep 2

        # Check if OTEL is running
        if ps -p $OTEL_PID > /dev/null 2>&1; then
            log_info "OpenTelemetry Collector started (PID: ${OTEL_PID})"
            log_info "Prometheus metrics available at: http://localhost:8889/metrics"

            if [ -n "${OTEL_ENDPOINT}" ]; then
                log_info "OTLP exporter configured: ${OTEL_ENDPOINT}"
            fi
        else
            log_warn "OpenTelemetry Collector failed to start (check /tmp/otelcol.log)"
        fi
    else
        log_error "OTEL config not found at /etc/otel/config.yaml"
        log_warn "OpenTelemetry Collector will not be started"
    fi
else
    log_info "OpenTelemetry Collector disabled (ENABLE_OTEL=false)"
fi

# Verify installations
log_info "Verifying tool installations..."

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -n1)
    log_info "Claude Code: ${CLAUDE_VERSION}"
else
    log_error "Claude Code not found!"
    exit 1
fi

if command -v go &> /dev/null; then
    GO_VERSION=$(go version 2>&1 | awk '{print $3}')
    log_info "Go: ${GO_VERSION}"
else
    log_error "Go not found!"
    exit 1
fi

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    log_info "Python: ${PYTHON_VERSION}"
else
    log_error "Python3 not found!"
    exit 1
fi

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>&1)
    log_info "Node.js: ${NODE_VERSION}"
else
    log_warn "Node.js not found!"
fi

if command -v act &> /dev/null; then
    ACT_VERSION=$(act --version 2>&1 | head -n1)
    log_info "act: ${ACT_VERSION}"
else
    log_warn "act not found!"
fi

if command -v actionlint &> /dev/null; then
    ACTIONLINT_VERSION=$(actionlint --version 2>&1)
    log_info "actionlint: ${ACTIONLINT_VERSION}"
else
    log_warn "actionlint not found!"
fi

if command -v otelcol &> /dev/null; then
    OTEL_VERSION=$(otelcol --version 2>&1 | head -n1)
    log_info "OpenTelemetry Collector: ${OTEL_VERSION}"
else
    log_warn "OpenTelemetry Collector not found!"
fi

# Set up workspace
WORKSPACE="${WORKSPACE:-${CLAUDE_HOME}/workspace}"
log_info "Workspace: ${WORKSPACE}"

if [ -d "${WORKSPACE}" ]; then
    cd "${WORKSPACE}"
    log_debug "Changed directory to workspace"
else
    log_warn "Workspace directory not found, creating..."
    mkdir -p "${WORKSPACE}"
    cd "${WORKSPACE}"
fi

# Configure Git if not already configured
if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "${GIT_USER_NAME:-Claude Code Runner}"
    log_debug "Set git user.name"
fi

if [ -z "$(git config --global user.email)" ]; then
    git config --global user.email "${GIT_USER_EMAIL:-claude@zeeke-ai.local}"
    log_debug "Set git user.email"
fi

# Set up MCP server configuration
if [ -f "${CLAUDE_HOME}/.claude/.mcp.json" ]; then
    log_info "MCP configuration found"

    # Update paths if Skill_Seekers is mounted differently
    if [ -n "${SKILL_SEEKERS_PATH}" ]; then
        log_debug "Updating Skill_Seekers path to: ${SKILL_SEEKERS_PATH}"
        # This would require jq to update JSON - keeping for reference
        if command -v jq &> /dev/null; then
            tmp=$(mktemp)
            jq --arg path "${SKILL_SEEKERS_PATH}" \
                '.mcpServers."skill-seeker".args[0] = ($path + "/mcp/server.py") |
                 .mcpServers."skill-seeker".cwd = $path' \
                "${CLAUDE_HOME}/.claude/.mcp.json" > "$tmp"
            mv "$tmp" "${CLAUDE_HOME}/.claude/.mcp.json"
            log_info "Updated MCP configuration"
        fi
    fi
else
    log_warn "MCP configuration not found at ${CLAUDE_HOME}/.claude/.mcp.json"
fi

# Initialize Go modules if go.mod exists
if [ -f "${WORKSPACE}/go.mod" ]; then
    log_info "Found go.mod, ensuring dependencies are downloaded..."
    go mod download
    log_info "Go dependencies downloaded"
fi

# Set up GitHub token if provided
if [ -n "${GITHUB_TOKEN}" ]; then
    log_info "GitHub token provided, configuring gh CLI..."
    echo "${GITHUB_TOKEN}" | gh auth login --with-token 2>/dev/null || log_warn "Failed to configure gh CLI"
fi

# Set up Anthropic API key if provided
if [ -n "${ANTHROPIC_API_KEY}" ]; then
    log_info "Anthropic API key provided"
    export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
fi

# Display agent and skill counts
if [ -d "${CLAUDE_HOME}/.claude/agents" ]; then
    AGENT_COUNT=$(find "${CLAUDE_HOME}/.claude/agents" -type f -name "*.md" -o -name "*.yml" 2>/dev/null | wc -l)
    log_info "Loaded ${AGENT_COUNT} agent specifications"
fi

if [ -d "${CLAUDE_HOME}/.claude/skills" ]; then
    SKILL_COUNT=$(find "${CLAUDE_HOME}/.claude/skills" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    log_info "Loaded ${SKILL_COUNT} skill modules"
fi

# Display project information
if [ -f "${WORKSPACE}/CLAUDE.md" ]; then
    log_info "Project CLAUDE.md found"
fi

if [ -f "${WORKSPACE}/PRD.md" ]; then
    log_info "Project PRD.md found"
fi

# Check for workflows
if [ -d "${WORKSPACE}/.github/workflows" ]; then
    WORKFLOW_COUNT=$(find "${WORKSPACE}/.github/workflows" -type f -name "*.yml" 2>/dev/null | wc -l)
    log_info "Found ${WORKFLOW_COUNT} workflow files"
fi

# Run pre-flight checks if requested
if [ "${RUN_PREFLIGHT:-true}" = "true" ]; then
    log_info "Running pre-flight checks..."

    # Check Go formatting
    if [ -f "${WORKSPACE}/go.mod" ]; then
        log_debug "Checking Go code..."
        if ! gofmt -l . 2>/dev/null | grep -q .; then
            log_info "Go code is properly formatted"
        else
            log_warn "Some Go files need formatting"
        fi
    fi

    # Validate workflows if actionlint is available
    if command -v actionlint &> /dev/null && [ -d "${WORKSPACE}/.github/workflows" ]; then
        log_debug "Validating workflows..."
        if actionlint "${WORKSPACE}/.github/workflows"/*.yml 2>&1 | grep -q "no errors found"; then
            log_info "All workflows are valid"
        else
            log_warn "Some workflows have validation warnings (check with: actionlint)"
        fi
    fi
fi

# Run health check before marking ready
log_info "Running readiness health check..."
if /usr/local/bin/health-check ready > /tmp/health-check.json 2>&1; then
    log_info "Health check passed"
    if [ "$USE_JSON_LOGS" != "true" ]; then
        cat /tmp/health-check.json | jq '.' 2>/dev/null || cat /tmp/health-check.json
    fi
else
    log_warn "Health check reported issues"
    if [ "$USE_JSON_LOGS" != "true" ]; then
        cat /tmp/health-check.json | jq '.' 2>/dev/null || cat /tmp/health-check.json
    fi
fi

# Display environment information
log_info "Environment ready!"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Container Information:${NC}"
echo -e "  User: $(whoami)"
echo -e "  Home: ${HOME}"
echo -e "  Workspace: ${WORKSPACE}"
echo -e "  Go version: $(go version | awk '{print $3}')"
echo -e "  Python version: $(python3 --version | awk '{print $2}')"
echo -e "  Node version: $(node --version)"
echo -e "  Observability: OTEL Collector $([ "${ENABLE_OTEL:-true}" = "true" ] && echo "enabled" || echo "disabled")"
echo -e "  Metrics endpoint: http://localhost:8889/metrics"
echo -e "  Health endpoint: /usr/local/bin/health-check [live|ready]"
echo -e "${BLUE}========================================${NC}"

# Execute provided command or start interactive shell
if [ $# -eq 0 ]; then
    log_info "No command provided, starting interactive shell..."
    exec /bin/bash
else
    log_info "Executing command: $*"
    exec "$@"
fi
