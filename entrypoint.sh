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

# Claude Code CLI verification
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -n1 || echo "unknown")
    log_info "Claude Code: ${CLAUDE_VERSION}"
else
    log_error "Claude Code not found!"
    exit 1
fi

# Go verification
if command -v go &> /dev/null; then
    log_info "Go: $(go version)"
else
    log_error "Go not found!"
    exit 1
fi

# Python verification
if command -v python3 &> /dev/null; then
    log_info "Python: $(python3 --version)"
else
    log_error "Python3 not found!"
    exit 1
fi

# Node.js verification
if command -v node &> /dev/null; then
    log_info "Node.js: $(node --version)"
else
    log_warn "Node.js not found!"
fi

# act verification
if command -v act &> /dev/null; then
    log_info "act: $(act --version)"
else
    log_warn "act not found!"
fi

# Verify MCP configuration
log_info "Verifying Claude Code configuration..."

if [ -f "${CLAUDE_HOME}/.claude/.mcp.json" ]; then
    log_info "MCP configuration found at ${CLAUDE_HOME}/.claude/.mcp.json"

    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if jq empty "${CLAUDE_HOME}/.claude/.mcp.json" 2>/dev/null; then
            log_info "MCP configuration is valid JSON"

            # Count configured servers
            SERVER_COUNT=$(jq '.mcpServers | length' "${CLAUDE_HOME}/.claude/.mcp.json" 2>/dev/null || echo "0")
            log_info "Configured MCP servers: ${SERVER_COUNT}"

            # List server names
            if [ "${SERVER_COUNT}" -gt 0 ]; then
                SERVERS=$(jq -r '.mcpServers | keys[]' "${CLAUDE_HOME}/.claude/.mcp.json" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
                log_info "Available servers: ${SERVERS}"
            fi
        else
            log_error "MCP configuration JSON is invalid"
            exit 1
        fi
    fi
else
    log_warn "MCP configuration not found at ${CLAUDE_HOME}/.claude/.mcp.json"
fi

# Verify Claude config.json
if [ -f "${CLAUDE_HOME}/.config/claude/config.json" ]; then
    log_info "Claude configuration found"

    # Check if auto-checkpoint is disabled (as per requirements)
    if command -v jq &> /dev/null; then
        AUTO_CHECKPOINT=$(jq -r '.checkpoint.auto // "not set"' "${CLAUDE_HOME}/.config/claude/config.json" 2>/dev/null)
        if [ "${AUTO_CHECKPOINT}" = "false" ]; then
            log_info "Auto-checkpoint: disabled (as configured)"
        else
            log_warn "Auto-checkpoint: ${AUTO_CHECKPOINT}"
        fi
    fi
else
    log_warn "Claude configuration not found at ${CLAUDE_HOME}/.config/claude/config.json"
fi

# Verify checkpoint directory
if [ -d "${CLAUDE_HOME}/.claude/checkpoints" ]; then
    CHECKPOINT_PERMS=$(stat -c "%a" "${CLAUDE_HOME}/.claude/checkpoints")
    if [ "${CHECKPOINT_PERMS}" = "700" ]; then
        log_info "Checkpoint directory permissions: ${CHECKPOINT_PERMS} (secure)"
    else
        log_warn "Checkpoint directory permissions: ${CHECKPOINT_PERMS} (expected 700)"
    fi
else
    log_warn "Checkpoint directory not found, creating..."
    mkdir -p "${CLAUDE_HOME}/.claude/checkpoints"
    chmod 700 "${CLAUDE_HOME}/.claude/checkpoints"
fi

# Verify Python MCP packages
log_info "Verifying Python MCP dependencies..."
if python3 -c "import mcp" 2>/dev/null; then
    log_info "Python MCP package installed"
else
    log_warn "Python MCP package not found"
fi

if python3 -c "import anthropic" 2>/dev/null; then
    log_info "Anthropic Python SDK installed"
else
    log_warn "Anthropic Python SDK not found"
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

# Check for project-specific MCP configuration override
if [ -f "${WORKSPACE}/.claude/.mcp.json" ] && [ "${WORKSPACE}" != "${CLAUDE_HOME}/workspace" ]; then
    log_info "Found project-specific MCP configuration"
    if jq empty "${WORKSPACE}/.claude/.mcp.json" 2>/dev/null; then
        log_info "Using project MCP configuration (overriding default)"
        cp "${WORKSPACE}/.claude/.mcp.json" "${CLAUDE_HOME}/.claude/.mcp.json"
    else
        log_error "Project MCP configuration is invalid JSON"
        exit 1
    fi
fi

# Initialize Go modules if go.mod exists
if [ -f "${WORKSPACE}/go.mod" ]; then
    log_info "Found go.mod, ensuring dependencies are downloaded..."
    go mod download 2>/dev/null || log_warn "Failed to download Go dependencies"
    log_info "Go dependencies ready"
fi

# Set up GitHub token if provided
if [ -n "${GITHUB_TOKEN}" ]; then
    log_info "GitHub token provided, configuring gh CLI..."
    echo "${GITHUB_TOKEN}" | gh auth login --with-token 2>/dev/null || log_warn "Failed to configure gh CLI"
fi

# Set up Anthropic API key if provided
if [ -n "${ANTHROPIC_API_KEY}" ]; then
    log_info "Anthropic API key configured"
    export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
else
    log_warn "ANTHROPIC_API_KEY not set - Claude Code may not function properly"
fi

# Display Claude Code setup summary
log_info "Claude Code Setup Summary:"

# Count skills
if [ -d "${CLAUDE_HOME}/.claude/skills" ]; then
    SKILL_COUNT=$(find "${CLAUDE_HOME}/.claude/skills" -maxdepth 1 -type f -name "*.md" | wc -l)
    log_info "  Skills available: ${SKILL_COUNT}"
    if [ "${SKILL_COUNT}" -gt 0 ]; then
        SKILL_LIST=$(find "${CLAUDE_HOME}/.claude/skills" -maxdepth 1 -type f -name "*.md" -exec basename {} .md \; | tr '\n' ', ' | sed 's/,$//')
        echo -e "    ${SKILL_LIST}"
    fi
fi

# Count agents
if [ -d "${CLAUDE_HOME}/.claude/agents" ]; then
    AGENT_COUNT=$(find "${CLAUDE_HOME}/.claude/agents" -type f \( -name "*.md" -o -name "*.yml" \) | wc -l)
    if [ "${AGENT_COUNT}" -gt 0 ]; then
        log_info "  Agent specifications: ${AGENT_COUNT}"
    fi
fi

# Display project information
if [ -f "${WORKSPACE}/CLAUDE.md" ]; then
    log_info "  Project CLAUDE.md: found"
fi

if [ -f "${WORKSPACE}/PRD.md" ]; then
    log_info "  Project PRD.md: found"
fi

# Check for workflows
if [ -d "${WORKSPACE}/.github/workflows" ]; then
    WORKFLOW_COUNT=$(find "${WORKSPACE}/.github/workflows" -type f -name "*.yml" -o -name "*.yaml" | wc -l)
    if [ "${WORKFLOW_COUNT}" -gt 0 ]; then
        log_info "  GitHub Actions workflows: ${WORKFLOW_COUNT}"
    fi
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
        WORKFLOW_FILES=$(find "${WORKSPACE}/.github/workflows" -type f \( -name "*.yml" -o -name "*.yaml" \))
        if [ -n "${WORKFLOW_FILES}" ]; then
            if echo "${WORKFLOW_FILES}" | xargs actionlint 2>&1 | grep -q "no errors found"; then
                log_info "All workflows are valid"
            else
                log_warn "Some workflows have validation warnings (check with: actionlint)"
            fi
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
echo -e "  Claude Code: ${CLAUDE_VERSION}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Usage:${NC}"
echo -e "  Manual checkpoints: ${YELLOW}/checkpoint save \"description\"${NC}"
echo -e "  List checkpoints:   ${YELLOW}/checkpoint list${NC}"
echo -e "  Context threshold:  ${YELLOW}70% (warning)${NC}"
echo -e "${BLUE}========================================${NC}"

# Execute provided command or start interactive shell
if [ $# -eq 0 ]; then
    log_info "No command provided, starting interactive shell..."
    exec /bin/bash
else
    log_info "Executing command: $*"
    exec "$@"
fi
