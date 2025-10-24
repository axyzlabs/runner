# GitHub Actions Runner with Claude Code for zeeke-ai
# Multi-stage build for optimized image size

# Build stage for Go tooling
FROM golang:1.25.0-bookworm AS go-builder

# Install Go tools
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install golang.org/x/lint/golint@latest

# Main runner stage
FROM ghcr.io/catthehacker/ubuntu:act-latest

# Metadata
LABEL maintainer="Zeeke AI Team"
LABEL description="GitHub Actions runner with Claude Code and Go tooling for zeeke-ai project"
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    GO_VERSION=1.25.0 \
    NODE_VERSION=20 \
    PYTHON_VERSION=3.11 \
    CLAUDE_USER=claude \
    CLAUDE_HOME=/home/claude \
    RUNNER_ALLOW_RUNASROOT=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    curl \
    wget \
    git \
    unzip \
    vim \
    jq \
    yq \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    # Build tools
    build-essential \
    gcc \
    g++ \
    make \
    # Python and pip
    python3=${PYTHON_VERSION}* \
    python3-pip \
    python3-venv \
    # Docker CLI (for act and testing)
    docker.io \
    # Additional utilities
    sudo \
    openssh-client \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Set Go environment
ENV PATH="/usr/local/go/bin:${PATH}" \
    GOPATH="/go" \
    GOBIN="/go/bin"

# Copy Go tools from builder
COPY --from=go-builder /go/bin/* /go/bin/

# Install Node.js and npm (for GitHub Actions scripts)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    rm -rf /var/lib/apt/lists/*

# Install actionlint for workflow validation
RUN wget -q https://github.com/rhysd/actionlint/releases/latest/download/actionlint_linux_amd64.tar.gz && \
    tar -xzf actionlint_linux_amd64.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/actionlint && \
    rm actionlint_linux_amd64.tar.gz

# Install act (for local workflow testing)
RUN curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin

# Install gh CLI (GitHub CLI)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN curl -fsSL https://install.claude.ai | sh

# Create claude user with sudo access
RUN useradd -m -s /bin/bash -u 1001 ${CLAUDE_USER} && \
    echo "${CLAUDE_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p ${CLAUDE_HOME}/.claude && \
    mkdir -p ${CLAUDE_HOME}/.config && \
    mkdir -p ${CLAUDE_HOME}/workspace && \
    chown -R ${CLAUDE_USER}:${CLAUDE_USER} ${CLAUDE_HOME}

# Set up Claude Code for claude user
USER ${CLAUDE_USER}
WORKDIR ${CLAUDE_HOME}

# Create Claude directories
RUN mkdir -p ${CLAUDE_HOME}/.claude/agents && \
    mkdir -p ${CLAUDE_HOME}/.claude/skills && \
    mkdir -p ${CLAUDE_HOME}/.config/claude

# Set up project workspace
WORKDIR ${CLAUDE_HOME}/workspace

# Copy project files (this will be mounted in runtime, but we set defaults)
COPY --chown=${CLAUDE_USER}:${CLAUDE_USER} . ${CLAUDE_HOME}/workspace/

# Copy project-level agents and skills
RUN if [ -d "${CLAUDE_HOME}/workspace/.github/agent-specs" ]; then \
        mkdir -p ${CLAUDE_HOME}/.claude/agents/project-agents && \
        cp -r ${CLAUDE_HOME}/workspace/.github/agent-specs/* ${CLAUDE_HOME}/.claude/agents/project-agents/; \
    fi && \
    if [ -d "${CLAUDE_HOME}/workspace/.claude/skills" ]; then \
        cp -r ${CLAUDE_HOME}/workspace/.claude/skills/* ${CLAUDE_HOME}/.claude/skills/; \
    fi

# Set up MCP configuration
RUN if [ -f "${CLAUDE_HOME}/workspace/.claude/.mcp.json" ]; then \
        cp ${CLAUDE_HOME}/workspace/.claude/.mcp.json ${CLAUDE_HOME}/.claude/.mcp.json; \
    fi

# Install Python MCP dependencies
RUN python3 -m pip install --user --upgrade pip setuptools wheel && \
    python3 -m pip install --user mcp anthropic

# Download Go dependencies
RUN if [ -f "go.mod" ]; then \
        go mod download; \
    fi

# Install project-specific Go tools
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest

# Set up Git config
RUN git config --global user.name "Claude Code Runner" && \
    git config --global user.email "claude@zeeke-ai.local" && \
    git config --global init.defaultBranch main

# Copy entrypoint script
COPY --chown=${CLAUDE_USER}:${CLAUDE_USER} entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER ${CLAUDE_USER}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD claude --version && go version && python3 --version || exit 1

# Environment variables for runtime
ENV PATH="${CLAUDE_HOME}/.local/bin:${GOBIN}:${PATH}" \
    WORKSPACE="${CLAUDE_HOME}/workspace"

# Expose no ports (this is a runner, not a service)
EXPOSE 0

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["bash"]
