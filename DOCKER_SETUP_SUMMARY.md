# Docker GitHub Actions Runner - Setup Summary

## Overview

This directory contains a complete Docker setup for running GitHub Actions workflows locally with Claude Code integration.

## Created Files

### Core Files

1. **Dockerfile.runner** (root)
   - Multi-stage Dockerfile for the runner container
   - Based on `ghcr.io/catthehacker/ubuntu:act-latest`
   - Includes: Go 1.25.0, Python 3.11, Node.js 20, Claude Code
   - Runs as non-root user `claude` (UID 1001)

2. **docker-compose.runner.yml** (root)
   - Docker Compose configuration for easy container management
   - Includes volume mounts, environment variables, resource limits
   - Two services: `gha-runner` (main) and `act-runner` (testing profile)

3. **.dockerignore** (root)
   - Excludes unnecessary files from Docker build context
   - Reduces build time and image size

### Scripts

4. **docker/entrypoint.sh**
   - Container startup script with comprehensive checks
   - Verifies all tools are installed
   - Configures Git, MCP, and environment
   - Provides colorful status output

5. **docker/build.sh**
   - Helper script to build the Docker image
   - Checks prerequisites and project files
   - Pulls latest base image
   - Uses BuildKit for optimized builds

6. **docker/runner.sh**
   - Management script for the runner container
   - Commands: start, stop, shell, logs, test, validate, rebuild
   - Provides easy access to common operations

7. **docker/test-runner.sh**
   - Comprehensive test suite for the container
   - Tests all installed tools and configurations
   - Verifies project files and permissions

### Documentation

8. **docker/README.md**
   - Complete documentation for the Docker setup
   - Usage examples, troubleshooting, advanced topics
   - Security considerations and best practices

9. **docker/SETUP_GUIDE.md**
   - Step-by-step setup guide
   - Configuration options
   - Common issues and solutions
   - Advanced usage patterns

10. **docker/DOCKER_SETUP_SUMMARY.md** (this file)
    - Quick reference and overview
    - File listing and descriptions

### GitHub Workflow

11. **.github/workflows/docker-runner.yml**
    - Automated build and test workflow
    - Security scanning with Trivy
    - Pushes to GitHub Container Registry on main branch

## Quick Reference

### Build

```bash
# Use build script
./docker/build.sh

# Or manually
docker build -f Dockerfile.runner -t zeeke-ai-runner:latest .
```

### Run

```bash
# Use runner script
./docker/runner.sh start

# Access shell
./docker/runner.sh shell

# Or manually
docker compose -f docker-compose.runner.yml up -d
docker compose -f docker-compose.runner.yml exec gha-runner bash
```

### Test

```bash
# Test the container
./docker/test-runner.sh

# Test workflows
./docker/runner.sh test ci.yml

# Or manually inside container
act -l
act push -W .github/workflows/ci.yml
```

### Manage

```bash
./docker/runner.sh start      # Start container
./docker/runner.sh stop       # Stop container
./docker/runner.sh restart    # Restart container
./docker/runner.sh shell      # Open shell
./docker/runner.sh logs       # View logs
./docker/runner.sh status     # Check status
./docker/runner.sh clean      # Remove container
./docker/runner.sh purge      # Remove container + volumes
./docker/runner.sh rebuild    # Clean, build, start
./docker/runner.sh validate   # Validate workflows
```

## Container Features

### Installed Tools

- **Claude Code**: Latest CLI version
- **Go**: 1.25.0 with tools (golangci-lint, staticcheck, goimports)
- **Python**: 3.11 with MCP dependencies
- **Node.js**: 20.x with npm
- **act**: For local workflow testing
- **actionlint**: For workflow validation
- **gh**: GitHub CLI
- **jq/yq**: JSON/YAML processors
- **Docker**: CLI for nested containers

### Agent & Skill Integration

- **User-level agents**: Mounted from `~/.claude/agents`
- **Project agents**: Copied from `.github/agent-specs`
- **Skills**: Copied from `.claude/skills`
- **MCP servers**: Configured from `.claude/.mcp.json`

### Security Features

- Non-root execution (claude user, UID 1001)
- Read-only agent mounts
- Secret file permissions (600)
- Health checks
- Resource limits

## Directory Structure

```
zeeke-ai/
├── Dockerfile.runner              # Main Dockerfile
├── docker-compose.runner.yml      # Docker Compose config
├── .dockerignore                  # Build context exclusions
├── docker/
│   ├── README.md                 # Main documentation
│   ├── SETUP_GUIDE.md            # Setup instructions
│   ├── DOCKER_SETUP_SUMMARY.md   # This file
│   ├── entrypoint.sh             # Container startup
│   ├── build.sh                  # Build helper
│   ├── runner.sh                 # Management helper
│   └── test-runner.sh            # Test suite
└── .github/
    └── workflows/
        └── docker-runner.yml      # CI/CD workflow
```

## Prerequisites

### Required

- Docker 20.10+
- Docker Compose 2.0+
- 8GB+ RAM
- 10GB+ disk space

### Recommended

- User-level Claude agents at `~/.claude/agents`
- GitHub Personal Access Token
- Anthropic API Key (for Claude features)

### Configuration Files

Create `.secrets` file:

```bash
GITHUB_TOKEN=ghp_your_token
ANTHROPIC_API_KEY=sk-ant-your_key
```

## Usage Flow

### First Time Setup

1. **Clone and prepare**:
   ```bash
   cd /home/dahendel/projects/zeeke-ai
   cp .secrets.example .secrets
   # Edit .secrets with your tokens
   ```

2. **Build the image**:
   ```bash
   ./docker/build.sh
   ```

3. **Start the container**:
   ```bash
   ./docker/runner.sh start
   ```

4. **Access and use**:
   ```bash
   ./docker/runner.sh shell
   # Inside container:
   act -l
   go test ./...
   ```

### Regular Usage

```bash
# Start container (if stopped)
./docker/runner.sh start

# Access shell
./docker/runner.sh shell

# Inside container - test workflows
act push -W .github/workflows/ci.yml

# Inside container - run tests
go test ./... -coverprofile=coverage.out

# Inside container - validate workflows
actionlint .github/workflows/*.yml

# View logs (on host)
./docker/runner.sh logs

# Stop when done
./docker/runner.sh stop
```

## Environment Variables

Key environment variables (set in `.secrets` or docker-compose.yml):

| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_TOKEN` | GitHub API access | Yes (for workflows) |
| `ANTHROPIC_API_KEY` | Claude API key | No |
| `GIT_USER_NAME` | Git author name | No |
| `GIT_USER_EMAIL` | Git author email | No |
| `SKILL_SEEKERS_PATH` | MCP server path | No |
| `RUN_PREFLIGHT` | Run startup checks | No (default: true) |

## Common Commands

### Inside Container

```bash
# List workflows
act -l

# Test workflow (dry run)
act -W .github/workflows/ci.yml -n

# Test workflow (full run)
act -W .github/workflows/ci.yml

# Validate workflows
actionlint .github/workflows/*.yml

# Build Go code
go build ./...

# Run Go tests
go test ./...

# Run tests with coverage
go test ./... -coverprofile=coverage.out

# Check for race conditions
go test -race ./...

# Format code
gofmt -w .

# Lint code
golangci-lint run

# Use Claude Code
claude --version
claude @agent-golang-pro "review code"
```

### On Host

```bash
# Container management
./docker/runner.sh start
./docker/runner.sh stop
./docker/runner.sh restart
./docker/runner.sh shell
./docker/runner.sh logs

# Testing
./docker/runner.sh test
./docker/runner.sh validate
./docker/test-runner.sh

# Maintenance
./docker/runner.sh clean
./docker/runner.sh purge
./docker/runner.sh rebuild
```

## Troubleshooting

### Container won't start

```bash
# Check logs
./docker/runner.sh logs

# Verify Docker
docker ps -a
docker logs zeeke-ai-runner

# Check resources
docker system df
docker stats --no-stream
```

### Tools not working

```bash
# Access container
./docker/runner.sh shell

# Verify tools
claude --version
go version
act --version

# Check PATH
echo $PATH

# Check workspace
ls -la /home/claude/workspace
```

### Workflows fail

```bash
# Validate syntax
actionlint .github/workflows/*.yml

# Test with verbose output
act -vv -W .github/workflows/ci.yml

# Check secrets
cat ~/.secrets

# Verify workspace mount
ls -la /home/claude/workspace/.github/workflows
```

## Advanced Topics

### Custom Build Args

```bash
docker build \
  -f Dockerfile.runner \
  -t zeeke-ai-runner:custom \
  --build-arg GO_VERSION=1.24.0 \
  --build-arg NODE_VERSION=18 \
  .
```

### Resource Limits

Edit `docker-compose.runner.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 16G
```

### Volume Mounts

Add custom volumes in `docker-compose.runner.yml`:

```yaml
volumes:
  - ./custom:/home/claude/custom:ro
```

### Network Configuration

Change network mode:

```yaml
network_mode: host  # or bridge, none
```

## Integration

### GitHub Actions

Use in workflows:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/dahendel/zeeke-ai-runner:latest
    steps:
      - uses: actions/checkout@v4
      - run: go test ./...
```

### Self-hosted Runner

Configure as GitHub self-hosted runner:

```bash
./docker/runner.sh shell
gh auth login
# Follow GitHub's runner setup
```

## Maintenance

### Update Base Image

```bash
docker pull ghcr.io/catthehacker/ubuntu:act-latest
./docker/build.sh
./docker/runner.sh rebuild
```

### Clean Up

```bash
# Remove containers
./docker/runner.sh clean

# Remove everything
./docker/runner.sh purge

# Clean Docker system
docker system prune -a
```

## Support

For issues or questions:

1. Check [README.md](./README.md)
2. Check [SETUP_GUIDE.md](./SETUP_GUIDE.md)
3. Run tests: `./docker/test-runner.sh`
4. Check logs: `./docker/runner.sh logs`
5. Verify status: `./docker/runner.sh status`

## Version

- **Version**: 1.0.0
- **Created**: 2025-01-23
- **Go**: 1.25.0
- **Python**: 3.11
- **Node.js**: 20.x
- **Base Image**: ghcr.io/catthehacker/ubuntu:act-latest

## Next Steps

After setup:

1. ✅ Build the image: `./docker/build.sh`
2. ✅ Test the image: `./docker/test-runner.sh`
3. ✅ Start the container: `./docker/runner.sh start`
4. ✅ Access shell: `./docker/runner.sh shell`
5. ✅ Test workflows: `act -l`
6. ✅ Run Go tests: `go test ./...`
7. ✅ Use Claude Code: `claude @agent-golang-pro`

---

**Happy containerizing!** 🐳
