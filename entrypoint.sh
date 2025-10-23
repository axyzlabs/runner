#!/bin/bash
# Entrypoint script for GitHub Actions Runner with Claude Code
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GitHub Actions Runner with Claude Code${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verify installations
log_info "Verifying tool installations..."

if command -v claude &> /dev/null; then
    log_info "Claude Code: $(claude --version)"
else
    log_error "Claude Code not found!"
    exit 1
fi

if command -v go &> /dev/null; then
    log_info "Go: $(go version)"
else
    log_error "Go not found!"
    exit 1
fi

if command -v python3 &> /dev/null; then
    log_info "Python: $(python3 --version)"
else
    log_error "Python3 not found!"
    exit 1
fi

if command -v node &> /dev/null; then
    log_info "Node.js: $(node --version)"
else
    log_warn "Node.js not found!"
fi

if command -v act &> /dev/null; then
    log_info "act: $(act --version)"
else
    log_warn "act not found!"
fi

if command -v actionlint &> /dev/null; then
    log_info "actionlint: $(actionlint --version)"
else
    log_warn "actionlint not found!"
fi

# Set up workspace
WORKSPACE="${WORKSPACE:-${CLAUDE_HOME}/workspace}"
log_info "Workspace: ${WORKSPACE}"

if [ -d "${WORKSPACE}" ]; then
    cd "${WORKSPACE}"
    log_info "Changed directory to workspace"
else
    log_warn "Workspace directory not found, creating..."
    mkdir -p "${WORKSPACE}"
    cd "${WORKSPACE}"
fi

# Configure Git if not already configured
if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "${GIT_USER_NAME:-Claude Code Runner}"
    log_info "Set git user.name"
fi

if [ -z "$(git config --global user.email)" ]; then
    git config --global user.email "${GIT_USER_EMAIL:-claude@zeeke-ai.local}"
    log_info "Set git user.email"
fi

# Set up MCP server configuration
if [ -f "${CLAUDE_HOME}/.claude/.mcp.json" ]; then
    log_info "MCP configuration found"

    # Update paths if Skill_Seekers is mounted differently
    if [ -n "${SKILL_SEEKERS_PATH}" ]; then
        log_info "Updating Skill_Seekers path to: ${SKILL_SEEKERS_PATH}"
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
    AGENT_COUNT=$(find "${CLAUDE_HOME}/.claude/agents" -type f -name "*.md" -o -name "*.yml" | wc -l)
    log_info "Loaded ${AGENT_COUNT} agent specifications"
fi

if [ -d "${CLAUDE_HOME}/.claude/skills" ]; then
    SKILL_COUNT=$(find "${CLAUDE_HOME}/.claude/skills" -type d -mindepth 1 -maxdepth 1 | wc -l)
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
    WORKFLOW_COUNT=$(find "${WORKSPACE}/.github/workflows" -type f -name "*.yml" | wc -l)
    log_info "Found ${WORKFLOW_COUNT} workflow files"
fi

# Run pre-flight checks if requested
if [ "${RUN_PREFLIGHT:-true}" = "true" ]; then
    log_info "Running pre-flight checks..."

    # Check Go formatting
    if [ -f "${WORKSPACE}/go.mod" ]; then
        log_info "Checking Go code..."
        if ! gofmt -l . | grep -q .; then
            log_info "Go code is properly formatted"
        else
            log_warn "Some Go files need formatting"
        fi
    fi

    # Validate workflows if actionlint is available
    if command -v actionlint &> /dev/null && [ -d "${WORKSPACE}/.github/workflows" ]; then
        log_info "Validating workflows..."
        if actionlint "${WORKSPACE}/.github/workflows"/*.yml 2>&1 | grep -q "no errors found"; then
            log_info "All workflows are valid"
        else
            log_warn "Some workflows have validation warnings (check with: actionlint)"
        fi
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
echo -e "${BLUE}========================================${NC}"

# Execute provided command or start interactive shell
if [ $# -eq 0 ]; then
    log_info "No command provided, starting interactive shell..."
    exec /bin/bash
else
    log_info "Executing command: $*"
    exec "$@"
fi
