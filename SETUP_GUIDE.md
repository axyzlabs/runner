# GitHub Actions Runner Setup Guide

Complete guide for setting up and using the GitHub Actions Runner container with Claude Code.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Configuration](#configuration)
5. [Usage Examples](#usage-examples)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Topics](#advanced-topics)

## Prerequisites

### Required Software

- **Docker**: 20.10 or higher
  ```bash
  docker --version
  ```

- **Docker Compose**: 2.0 or higher
  ```bash
  docker compose version
  ```

### Required Files and Directories

1. **User-level Claude agents** (recommended):
   ```bash
   ~/.claude/agents/
   ```

2. **GitHub Token** (for workflows):
   - Create at: https://github.com/settings/tokens
   - Required scopes: `repo`, `workflow`

3. **Anthropic API Key** (optional, for Claude features):
   - Get from: https://console.anthropic.com/

### System Requirements

- **RAM**: Minimum 8GB, recommended 16GB
- **Disk**: Minimum 10GB free space
- **CPU**: Minimum 2 cores, recommended 4 cores

## Quick Start

### 1. Clone and Setup

```bash
# Navigate to project
cd /home/dahendel/projects/zeeke-ai

# Create secrets file
cp .secrets.example .secrets

# Edit .secrets and add your tokens
nano .secrets
```

### 2. Build the Image

```bash
# Use the build script (recommended)
./docker/build.sh

# Or build manually
docker build -f Dockerfile.runner -t zeeke-ai-runner:latest .
```

### 3. Start the Container

```bash
# Use the runner script (recommended)
./docker/runner.sh start

# Or use docker-compose directly
docker compose -f docker-compose.runner.yml up -d
```

### 4. Access the Container

```bash
# Use the runner script
./docker/runner.sh shell

# Or use docker-compose
docker compose -f docker-compose.runner.yml exec gha-runner bash
```

### 5. Test Workflows

```bash
# Inside container
act -l                                    # List workflows
act push -W .github/workflows/ci.yml     # Test CI workflow
```

## Detailed Setup

### Step 1: Prepare Environment

#### 1.1. Check Prerequisites

```bash
# Verify Docker
docker --version
docker info

# Verify Docker Compose
docker compose version

# Check available resources
docker system df
```

#### 1.2. Verify User-level Agents

```bash
# Check if agents exist
ls -la ~/.claude/agents/

# Count agent files
find ~/.claude/agents -type f | wc -l

# If missing, you can still proceed but without user-level agents
```

#### 1.3. Create Secrets File

```bash
# Copy example
cp .secrets.example .secrets

# Edit with your tokens
cat > .secrets << 'EOF'
GITHUB_TOKEN=ghp_your_github_token_here
ANTHROPIC_API_KEY=sk-ant-your_anthropic_key_here
EOF

# Secure the file
chmod 600 .secrets
```

### Step 2: Build the Image

#### 2.1. Build with Script (Recommended)

```bash
# Standard build
./docker/build.sh

# Build with specific tag
./docker/build.sh v1.0.0

# Build with custom args
./docker/build.sh latest "--no-cache"
```

#### 2.2. Manual Build

```bash
# Enable BuildKit for better performance
export DOCKER_BUILDKIT=1

# Build the image
docker build \
  -f Dockerfile.runner \
  -t zeeke-ai-runner:latest \
  --build-arg GO_VERSION=1.25.0 \
  --build-arg NODE_VERSION=20 \
  --build-arg PYTHON_VERSION=3.11 \
  .

# Verify build
docker images zeeke-ai-runner:latest
```

#### 2.3. Build Verification

```bash
# Test the image
docker run -it --rm zeeke-ai-runner:latest claude --version

# Check image size
docker images zeeke-ai-runner:latest --format "{{.Size}}"

# Inspect image
docker inspect zeeke-ai-runner:latest
```

### Step 3: Configure Container

#### 3.1. Environment Variables

Edit `docker-compose.runner.yml` to customize:

```yaml
environment:
  # GitHub configuration
  - GITHUB_TOKEN=${GITHUB_TOKEN}
  - GITHUB_REPOSITORY=dahendel/zeeke-ai

  # Anthropic configuration
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}

  # Git configuration
  - GIT_USER_NAME=Your Name
  - GIT_USER_EMAIL=your.email@example.com

  # Runner configuration
  - RUN_PREFLIGHT=true
```

#### 3.2. Volume Mounts

Customize volume mounts in `docker-compose.runner.yml`:

```yaml
volumes:
  # Project workspace
  - ./:/home/claude/workspace:rw

  # User agents (adjust path if needed)
  - ${HOME}/.claude/agents:/home/claude/.claude/agents:ro

  # Skill Seekers MCP (adjust path if needed)
  - /path/to/Skill_Seekers:/mcp/skill-seekers:ro

  # Docker socket for act
  - /var/run/docker.sock:/var/run/docker.sock
```

#### 3.3. Resource Limits

Adjust resource limits based on your system:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'      # Max CPUs
      memory: 8G     # Max memory
    reservations:
      cpus: '2'      # Guaranteed CPUs
      memory: 4G     # Guaranteed memory
```

### Step 4: Start and Verify

#### 4.1. Start Container

```bash
# Using runner script
./docker/runner.sh start

# Check status
./docker/runner.sh status

# View logs
./docker/runner.sh logs
```

#### 4.2. Verify Container

```bash
# Check health
docker inspect zeeke-ai-runner | jq '.[0].State.Health'

# Check processes
docker top zeeke-ai-runner

# Check resource usage
docker stats zeeke-ai-runner --no-stream
```

#### 4.3. Test Tools

```bash
# Access container
./docker/runner.sh shell

# Inside container - test tools
claude --version
go version
python3 --version
node --version
act --version
actionlint --version

# Test workspace
ls -la /home/claude/workspace
cat /home/claude/workspace/CLAUDE.md
```

## Configuration

### MCP Server Configuration

#### Default Configuration

The container uses `.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "skill-seeker": {
      "command": "python3",
      "args": ["/mcp/skill-seekers/mcp/server.py"],
      "cwd": "/mcp/skill-seekers"
    }
  }
}
```

#### Custom MCP Configuration

To use a different MCP server path:

```bash
# Set environment variable
export SKILL_SEEKERS_PATH=/custom/path/to/Skill_Seekers

# Start container
./docker/runner.sh start
```

### Agent Configuration

#### User-level Agents

Agents from `~/.claude/agents` are mounted read-only:

```
/home/claude/.claude/agents/
├── categories/
│   ├── 01-core-development/
│   ├── 02-language-specialists/
│   └── ...
├── agent-organizer.md
├── golang-pro.md
└── ...
```

#### Project-level Agents

Agents from `.github/agent-specs/` are copied during build:

```
/home/claude/.claude/agents/project-agents/
├── devops-engineer.yml
├── golang-pro.yml
└── ...
```

### Secrets Management

#### Using .secrets File

```bash
# Create .secrets
cat > .secrets << 'EOF'
GITHUB_TOKEN=ghp_xxx
ANTHROPIC_API_KEY=sk-ant-xxx
CUSTOM_SECRET=value
EOF

# Load automatically with docker-compose
./docker/runner.sh start
```

#### Using Environment Variables

```bash
# Export before running
export GITHUB_TOKEN="ghp_xxx"
export ANTHROPIC_API_KEY="sk-ant-xxx"

# Run container
./docker/runner.sh start
```

#### Using Docker Secrets (Production)

```bash
# Create secrets
echo "ghp_xxx" | docker secret create github_token -
echo "sk-ant-xxx" | docker secret create anthropic_key -

# Update docker-compose.yml to use secrets
```

## Usage Examples

### Example 1: Test CI Workflow

```bash
# Access container
./docker/runner.sh shell

# Inside container
cd /home/claude/workspace

# List workflows
act -l

# Validate CI workflow
actionlint .github/workflows/ci.yml

# Dry run
act push -W .github/workflows/ci.yml -n

# Full test
act push -W .github/workflows/ci.yml
```

### Example 2: Build and Test Go Code

```bash
# Access container
./docker/runner.sh shell

# Inside container
cd /home/claude/workspace

# Download dependencies
go mod download

# Build
go build ./...

# Run tests
go test ./...

# Run with coverage
go test ./... -coverprofile=coverage.out

# View coverage
go tool cover -html=coverage.out
```

### Example 3: Use Claude Code Agents

```bash
# Access container
./docker/runner.sh shell

# Inside container
# List available agents
ls ~/.claude/agents/

# Use golang-pro agent
claude @agent-golang-pro "review pkg/mcp/client.go"

# Use devops-engineer agent
claude @agent-devops-engineer "optimize Dockerfile.runner"
```

### Example 4: Test Multiple Workflows

```bash
# Access container
./docker/runner.sh shell

# Inside container
# Test all workflows with dry run
for workflow in .github/workflows/*.yml; do
  echo "Testing $workflow..."
  act -W "$workflow" -n
done

# Test specific workflows
act push -W .github/workflows/ci.yml
act pull_request -W .github/workflows/pr-checks.yml
act issues -W .github/workflows/pm-issue-evaluation.yml
```

### Example 5: Debug Failed Workflow

```bash
# Test workflow with verbose output
act push -W .github/workflows/ci.yml -vv

# Keep container on failure
act push -W .github/workflows/ci.yml --rm=false

# Inspect failed container
docker ps -a
docker logs <container-id>
docker exec -it <container-id> /bin/bash
```

## Troubleshooting

### Common Issues

#### Issue 1: Docker Socket Permission Denied

**Problem:**
```
permission denied while trying to connect to Docker daemon socket
```

**Solution:**
```bash
# On host
sudo chmod 666 /var/run/docker.sock

# Or add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### Issue 2: Out of Disk Space

**Problem:**
```
no space left on device
```

**Solution:**
```bash
# Clean up Docker
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

#### Issue 3: Build Fails - Agent Files Not Found

**Problem:**
```
COPY failed: file not found: /home/dahendel/.claude/agents
```

**Solution:**
```bash
# Create dummy agent directory if needed
mkdir -p ~/.claude/agents

# Or modify Dockerfile to make it optional
```

#### Issue 4: MCP Server Not Accessible

**Problem:**
```
MCP server not found at /mcp/skill-seekers
```

**Solution:**
```bash
# Check if mounted
docker exec zeeke-ai-runner ls -la /mcp/skill-seekers

# Verify environment variable
docker exec zeeke-ai-runner env | grep SKILL_SEEKERS

# Update docker-compose.yml with correct path
```

#### Issue 5: Workflow Test Fails

**Problem:**
```
Error: unable to find workflow file
```

**Solution:**
```bash
# Check workspace mount
docker exec zeeke-ai-runner ls -la /home/claude/workspace/.github/workflows

# Use full path
act -W /home/claude/workspace/.github/workflows/ci.yml

# Or cd to workspace first
cd /home/claude/workspace && act -W .github/workflows/ci.yml
```

### Debugging Tips

#### Check Container Logs

```bash
# View startup logs
./docker/runner.sh logs

# Follow logs
./docker/runner.sh logs -f

# Check Docker daemon logs
sudo journalctl -u docker
```

#### Inspect Container

```bash
# Check environment
docker exec zeeke-ai-runner env

# Check user
docker exec zeeke-ai-runner whoami

# Check paths
docker exec zeeke-ai-runner bash -c 'echo $PATH'

# Check mounted volumes
docker inspect zeeke-ai-runner | jq '.[0].Mounts'
```

#### Test Tools Individually

```bash
# Test Claude Code
docker exec zeeke-ai-runner claude --version

# Test Go
docker exec zeeke-ai-runner go version

# Test act
docker exec zeeke-ai-runner act --version

# Test workspace access
docker exec zeeke-ai-runner ls -la /home/claude/workspace
```

## Advanced Topics

### Custom Runner Images

Create custom variants:

```bash
# Build with different Go version
docker build \
  -f Dockerfile.runner \
  -t zeeke-ai-runner:go1.24 \
  --build-arg GO_VERSION=1.24.0 \
  .

# Build minimal version (without Claude Code)
# Create Dockerfile.runner.minimal
docker build -f Dockerfile.runner.minimal -t zeeke-ai-runner:minimal .
```

### CI/CD Integration

Use in GitHub Actions:

```yaml
jobs:
  test-in-container:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/dahendel/zeeke-ai-runner:latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: go test ./...
```

### Multi-stage Workflows

Test complex workflows:

```bash
# Test workflow with dependencies
act -W .github/workflows/ci.yml --sequence

# Test matrix builds
act -W .github/workflows/ci.yml --matrix go-version:1.25
```

### Performance Optimization

Optimize for speed:

```bash
# Use container reuse
act --reuse

# Use BuildKit caching
DOCKER_BUILDKIT=1 docker build ...

# Pre-pull images
docker pull ghcr.io/catthehacker/ubuntu:act-latest
```

### Production Deployment

Deploy as self-hosted runner:

```bash
# Register runner
docker exec zeeke-ai-runner \
  gh auth login --with-token <<< "$GITHUB_TOKEN"

# Configure runner
# Follow GitHub's self-hosted runner setup
```

## Support and Resources

### Documentation

- [Docker README](./README.md) - Comprehensive Docker documentation
- [Main CLAUDE.md](../CLAUDE.md) - Project development instructions
- [Workflow Testing Skill](../.claude/skills/workflow-testing/SKILL.md) - act usage guide

### Helper Scripts

- `./docker/build.sh` - Build the image
- `./docker/runner.sh` - Manage container
- `./docker/test-runner.sh` - Test container

### Getting Help

1. Check logs: `./docker/runner.sh logs`
2. Check status: `./docker/runner.sh status`
3. Run tests: `./docker/test-runner.sh`
4. Review this guide

## Maintenance

### Regular Updates

```bash
# Update base image
docker pull ghcr.io/catthehacker/ubuntu:act-latest

# Rebuild image
./docker/build.sh

# Restart container
./docker/runner.sh rebuild
```

### Cleanup

```bash
# Stop and remove container
./docker/runner.sh clean

# Remove volumes too
./docker/runner.sh purge

# Clean Docker system
docker system prune -a
```

---

**Last Updated:** 2025-01-23
**Version:** 1.0.0
**Maintainer:** Zeeke AI Team
