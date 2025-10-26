# Configuration Reference

Complete reference for all configuration options, environment variables, and settings for the GitHub Actions Runner image.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Volume Mounts](#volume-mounts)
- [Resource Limits](#resource-limits)
- [Network Configuration](#network-configuration)
- [Security Configuration](#security-configuration)
- [Build Arguments](#build-arguments)
- [Runtime Configuration](#runtime-configuration)

## Environment Variables

### GitHub Configuration

#### GITHUB_TOKEN

**Description:** GitHub personal access token for API access and authentication.

**Required:** Yes (for most workflows)

**Format:** `ghp_` followed by alphanumeric characters

**Scopes Required:**
- `repo` - Full control of private repositories
- `workflow` - Update GitHub Action workflows
- `read:org` - Read org and team membership (if applicable)

**Usage:**
```bash
# Via .secrets file
echo "GITHUB_TOKEN=ghp_xxxxxxxxxxxxx" >> .secrets

# Via environment variable
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"
```

**Security Notes:**
- Never commit tokens to version control
- Use read-only tokens when possible
- Rotate tokens regularly
- Store in `.secrets` file (mounted read-only)

#### GITHUB_REPOSITORY

**Description:** Target GitHub repository in format `owner/repo`.

**Required:** No

**Default:** `dahendel/zeeke-ai`

**Format:** `owner/repository-name`

**Usage:**
```bash
export GITHUB_REPOSITORY="myorg/myrepo"
```

**Example:**
```yaml
environment:
  - GITHUB_REPOSITORY=acme-corp/api-server
```

#### GITHUB_WORKSPACE

**Description:** Path to the workspace directory inside the container.

**Required:** No

**Default:** `/home/claude/workspace`

**Usage:**
```bash
export GITHUB_WORKSPACE="/custom/workspace/path"
```

**Notes:**
- Should be owned by `claude` user (UID 1001)
- Must be an absolute path
- Typically mounted from host via volume

### Anthropic Configuration

#### ANTHROPIC_API_KEY

**Description:** API key for Anthropic Claude services.

**Required:** No (but needed for Claude Code features)

**Format:** `sk-ant-` followed by alphanumeric characters

**Usage:**
```bash
# Via .secrets file
echo "ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx" >> .secrets

# Via environment variable
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxxxxxxx"
```

**Security Notes:**
- Never commit to version control
- Mount .secrets file as read-only
- Restrict file permissions: `chmod 600 .secrets`
- Monitor API usage to detect leaks

**Scopes:**
- Full API access for Claude Code
- Required for MCP server interactions
- Needed for agent-based workflows

### Git Configuration

#### GIT_USER_NAME

**Description:** Git user name for commits made in the container.

**Required:** No

**Default:** `Claude Code Runner`

**Usage:**
```bash
export GIT_USER_NAME="John Doe"
```

**Example:**
```yaml
environment:
  - GIT_USER_NAME=CI Bot
```

#### GIT_USER_EMAIL

**Description:** Git user email for commits made in the container.

**Required:** No

**Default:** `claude@zeeke-ai.local`

**Usage:**
```bash
export GIT_USER_EMAIL="ci-bot@example.com"
```

**Example:**
```yaml
environment:
  - GIT_USER_EMAIL=noreply@acme-corp.com
```

### Runner Configuration

#### RUN_PREFLIGHT

**Description:** Enable or disable preflight checks on container startup.

**Required:** No

**Default:** `true`

**Valid Values:** `true`, `false`

**Preflight Checks Include:**
- Go code formatting validation
- Workflow syntax validation with actionlint
- Environment verification

**Usage:**
```bash
# Disable preflight checks
export RUN_PREFLIGHT=false
```

**When to Disable:**
- Fast container startup needed
- Running in CI/CD where validation is separate
- Debugging startup issues

#### RUNNER_ALLOW_RUNASROOT

**Description:** Allow GitHub Actions runner to run as root (NOT RECOMMENDED).

**Required:** No

**Default:** `0` (disabled)

**Valid Values:** `0` (disabled), `1` (enabled)

**Usage:**
```bash
# DO NOT USE unless absolutely necessary
export RUNNER_ALLOW_RUNASROOT=1
```

**Security Warning:**
- Running as root is a security risk
- Container is designed to run as `claude` user (UID 1001)
- Only enable for debugging

### MCP Server Configuration

#### SKILL_SEEKERS_PATH

**Description:** Path to Skill Seekers MCP server directory.

**Required:** No

**Default:** `/mcp/skill-seekers`

**Usage:**
```bash
# On host
export SKILL_SEEKERS_PATH="/path/to/skill-seekers"

# Will be mounted to /mcp/skill-seekers in container
```

**Requirements:**
- Directory must contain `mcp/server.py`
- Must have Python dependencies installed
- Readable by claude user (UID 1001)

**Example:**
```yaml
environment:
  - SKILL_SEEKERS_PATH=/mcp/skill-seekers
volumes:
  - /home/user/projects/skill-seekers:/mcp/skill-seekers:ro
```

### Go Configuration

#### GOPATH

**Description:** Go workspace path.

**Required:** No

**Default:** `/go`

**Usage:**
```bash
export GOPATH=/custom/go/path
```

**Notes:**
- Used for Go module cache
- Should be writable by claude user
- Typically mounted as volume for persistence

#### GOBIN

**Description:** Directory for Go binary installations.

**Required:** No

**Default:** `/go/bin`

**Usage:**
```bash
export GOBIN=/go/bin
```

**Notes:**
- Must be in PATH
- Writable by claude user
- Used by `go install`

#### GO111MODULE

**Description:** Enable Go modules mode.

**Required:** No

**Default:** `on`

**Valid Values:** `on`, `off`, `auto`

**Usage:**
```bash
export GO111MODULE=on
```

**Recommendation:**
- Keep as `on` for modern Go projects
- Required for Go 1.16+

#### CGO_ENABLED

**Description:** Enable C bindings in Go.

**Required:** No

**Default:** `0` (disabled)

**Valid Values:** `0` (disabled), `1` (enabled)

**Usage:**
```bash
# Enable CGO if needed
export CGO_ENABLED=1
```

**Notes:**
- Disabled by default for better portability
- Enable only if dependencies require C bindings
- May increase build time

#### GOMAXPROCS

**Description:** Maximum number of CPU cores Go can use.

**Required:** No

**Default:** Number of available CPUs

**Usage:**
```bash
# Limit to 4 cores
export GOMAXPROCS=4
```

**When to Set:**
- Limit parallel builds
- Reduce memory usage
- Prevent CPU throttling

### Python Configuration

#### PYTHONUNBUFFERED

**Description:** Force Python stdout/stderr to be unbuffered.

**Required:** No

**Default:** `1` (unbuffered)

**Usage:**
```bash
export PYTHONUNBUFFERED=1
```

**Benefits:**
- Real-time log output
- Better for containerized environments
- Prevents output buffering issues

#### PIP_NO_CACHE_DIR

**Description:** Disable pip cache to reduce image size.

**Required:** No

**Default:** `1` (disabled)

**Usage:**
```bash
export PIP_NO_CACHE_DIR=1
```

**Notes:**
- Reduces disk usage
- May slow down repeated installs
- Good for container images

### Logging Configuration

#### LOG_LEVEL

**Description:** Logging verbosity level.

**Required:** No

**Default:** `info`

**Valid Values:** `debug`, `info`, `warn`, `error`

**Usage:**
```bash
export LOG_LEVEL=debug
```

**Levels:**
- `debug` - Verbose output, all messages
- `info` - Normal operation messages
- `warn` - Warning messages only
- `error` - Error messages only

#### LOG_FORMAT

**Description:** Log output format.

**Required:** No

**Default:** `text`

**Valid Values:** `text`, `json`

**Usage:**
```bash
# JSON format for log aggregation
export LOG_FORMAT=json
```

**When to Use JSON:**
- Log aggregation systems (ELK, Splunk)
- Automated log parsing
- Production environments

### Observability Configuration

#### OTEL_ENDPOINT

**Description:** OpenTelemetry collector endpoint for traces and metrics.

**Required:** No

**Default:** None

**Format:** `http://host:port` or `https://host:port`

**Usage:**
```bash
export OTEL_ENDPOINT="http://otel-collector:4318"
```

**Example:**
```yaml
environment:
  - OTEL_ENDPOINT=https://api.honeycomb.io
```

#### OTEL_EXPORTER_OTLP_HEADERS

**Description:** Additional headers for OTLP exporter (e.g., API keys).

**Required:** No (Yes if endpoint requires authentication)

**Format:** Comma-separated key=value pairs

**Usage:**
```bash
export OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=your-api-key"
```

**Example:**
```yaml
environment:
  - OTEL_EXPORTER_OTLP_HEADERS=x-api-key=secret,x-tenant=prod
```

#### OTEL_EXPORTER_OTLP_PROTOCOL

**Description:** Protocol for OTLP exporter.

**Required:** No

**Default:** `http/protobuf`

**Valid Values:** `http/protobuf`, `grpc`

**Usage:**
```bash
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

**Recommendation:**
- `http/protobuf` - Easier firewall traversal
- `grpc` - Better performance, binary protocol

### Advanced Configuration

#### DOCKER_HOST

**Description:** Docker daemon socket location.

**Required:** No

**Default:** `unix:///var/run/docker.sock`

**Usage:**
```bash
# For remote Docker daemon
export DOCKER_HOST="tcp://remote-docker:2375"
```

**Security Notes:**
- Only use over secure networks
- Consider TLS authentication
- Local socket is more secure

#### WORKSPACE

**Description:** Alternative workspace path (overrides GITHUB_WORKSPACE).

**Required:** No

**Default:** `${CLAUDE_HOME}/workspace`

**Usage:**
```bash
export WORKSPACE="/custom/workspace"
```

## Volume Mounts

### Workspace Mount

**Purpose:** Mount project directory for development.

**Configuration:**
```yaml
volumes:
  - ./:/home/claude/workspace:rw
```

**Permissions:** Read-write (rw)

**Notes:**
- Current directory mapped to container workspace
- Files created owned by UID 1001 (claude user)
- Changes persist on host

### Agent Mounts

**Purpose:** Load Claude Code agents from host.

**Configuration:**
```yaml
volumes:
  - ${HOME}/.claude/agents:/home/claude/.claude/agents:ro
```

**Permissions:** Read-only (ro)

**Structure:**
```
~/.claude/agents/
├── devops-engineer.yml
├── golang-pro.yml
├── testing-specialist.yml
└── ...
```

**Notes:**
- Agents are read-only for security
- Supports both YAML and Markdown formats
- Subdirectories are supported

### Secrets Mount

**Purpose:** Securely provide secrets to container.

**Configuration:**
```yaml
volumes:
  - ./.secrets:/home/claude/.secrets:ro
```

**Permissions:** Read-only (ro)

**Format:**
```bash
# .secrets file
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
CUSTOM_SECRET=value
```

**Security:**
- File should be chmod 600 on host
- Never commit to version control
- Mounted read-only to prevent modification
- Add to .gitignore

### Docker Socket Mount

**Purpose:** Allow act to run workflows using host Docker.

**Configuration:**
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

**Security Considerations:**
- Grants container access to host Docker
- Can be used to escape container
- Only mount if needed for act
- Consider Docker-in-Docker alternative

**Alternatives:**
```yaml
# Docker-in-Docker (more isolated)
services:
  docker:
    image: docker:dind
    privileged: true
```

### Cache Volumes

**Purpose:** Persist build caches for faster builds.

**Configuration:**
```yaml
volumes:
  # Go module cache
  - go-cache:/go/pkg/mod

  # Go build cache
  - go-build-cache:/home/claude/.cache/go-build

  # Act cache
  - act-cache:/home/claude/.cache/act

volumes:
  go-cache:
    driver: local
  go-build-cache:
    driver: local
  act-cache:
    driver: local
```

**Benefits:**
- Faster builds (cached dependencies)
- Reduced network usage
- Persistent across container restarts

**Cleanup:**
```bash
# Remove all caches
docker compose down -v

# Remove specific volume
docker volume rm runner_go-cache
```

### MCP Server Mount

**Purpose:** Mount Skill Seekers or other MCP servers.

**Configuration:**
```yaml
volumes:
  - ${SKILL_SEEKERS_PATH:-./mcp/skill-seekers}:/mcp/skill-seekers:ro
```

**Permissions:** Read-only (ro)

**Requirements:**
- Must contain valid MCP server
- Python dependencies must be installed
- Proper file permissions (readable by UID 1001)

## Resource Limits

### CPU Limits

**Configuration:**
```yaml
deploy:
  resources:
    limits:
      cpus: '4'        # Maximum CPUs
    reservations:
      cpus: '2'        # Reserved CPUs
```

**Recommendations:**
- Development: 2-4 CPUs
- CI/CD: 4-8 CPUs
- Production: Based on workload

**Effects of Limits:**
- Throttling if exceeded
- May slow builds
- Go parallel builds affected

### Memory Limits

**Configuration:**
```yaml
deploy:
  resources:
    limits:
      memory: 8G      # Maximum memory
    reservations:
      memory: 4G      # Reserved memory
```

**Recommendations:**
- Minimum: 4GB for basic usage
- Development: 8GB recommended
- Go builds: 8-16GB for large projects
- CI/CD: 16GB+ for parallel workflows

**Out of Memory:**
- Container will be killed
- Builds will fail
- Increase limits if needed

### Storage Limits

**Configuration:**
```yaml
# Via Docker daemon config
{
  "storage-opts": [
    "size=50G"
  ]
}
```

**Considerations:**
- Go modules can be large
- Docker images consume space
- Cache volumes grow over time

**Monitoring:**
```bash
# Check container disk usage
docker exec zeeke-ai-runner df -h

# Check Docker system usage
docker system df
```

## Network Configuration

### Network Mode

**Bridge (Default):**
```yaml
network_mode: bridge
```
- Isolated network
- Port mapping required
- More secure

**Host:**
```yaml
network_mode: host
```
- Share host network
- No port mapping needed
- Less isolation

**Custom Network:**
```yaml
networks:
  custom-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

### DNS Configuration

**Custom DNS Servers:**
```yaml
dns:
  - 8.8.8.8
  - 8.8.4.4
```

**Search Domains:**
```yaml
dns_search:
  - example.com
  - internal.local
```

### Port Mapping

**Expose Services:**
```yaml
ports:
  - "8080:8080"    # HTTP
  - "9090:9090"    # Metrics
```

**Notes:**
- Not required for basic usage
- Needed if running services in container
- Consider security implications

## Security Configuration

### User Configuration

**Run as Non-Root:**
```yaml
user: claude  # UID 1001
```

**Benefits:**
- Reduces security risk
- Prevents privilege escalation
- Best practice for containers

**File Ownership:**
- Files created owned by UID 1001
- Host user should match or use group permissions

### Read-Only Root Filesystem

**Configuration:**
```yaml
read_only: true
tmpfs:
  - /tmp
  - /home/claude/.cache
```

**Benefits:**
- Prevents modifications to image
- Hardens security
- Limits attack surface

**Trade-offs:**
- Requires tmpfs for writable directories
- May complicate some workflows
- Not enabled by default

### Security Options

**Drop Capabilities:**
```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - DAC_OVERRIDE
  - SETGID
  - SETUID
```

**AppArmor/SELinux:**
```yaml
security_opt:
  - apparmor:docker-default
  - label:type:container_runtime_t
```

## Build Arguments

### GO_VERSION

**Description:** Go version to install.

**Default:** `1.25.0`

**Usage:**
```bash
docker build --build-arg GO_VERSION=1.26.0 -t runner:latest .
```

### NODE_VERSION

**Description:** Node.js major version.

**Default:** `20`

**Valid Values:** `18`, `20`, `21`

**Usage:**
```bash
docker build --build-arg NODE_VERSION=21 -t runner:latest .
```

### PYTHON_VERSION

**Description:** Python version.

**Default:** `3.11`

**Valid Values:** `3.9`, `3.10`, `3.11`, `3.12`

**Usage:**
```bash
docker build --build-arg PYTHON_VERSION=3.12 -t runner:latest .
```

### CLAUDE_VERSION

**Description:** Claude CLI version to install.

**Default:** `latest`

**Usage:**
```bash
docker build --build-arg CLAUDE_VERSION=1.2.3 -t runner:latest .
```

## Runtime Configuration

### Health Check

**Configuration:**
```yaml
healthcheck:
  test: ["CMD", "claude", "--version"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

**Customization:**
```yaml
healthcheck:
  test: ["CMD", "bash", "-c", "claude --version && go version"]
  interval: 60s       # Check every 60 seconds
  timeout: 20s        # Wait up to 20 seconds
  retries: 5          # Retry 5 times
  start_period: 60s   # Grace period before checking
```

### Restart Policy

**Configuration:**
```yaml
restart: unless-stopped
```

**Options:**
- `no` - Never restart
- `always` - Always restart
- `on-failure` - Restart on error
- `unless-stopped` - Restart unless manually stopped

### Container Labels

**Add Metadata:**
```yaml
labels:
  com.example.version: "1.0"
  com.example.environment: "production"
  com.example.team: "platform"
```

**Usage:**
- Filter containers
- Monitoring and metrics
- Documentation

## Configuration File Examples

### Minimal Configuration

```yaml
version: '3.8'

services:
  gha-runner:
    image: zeeke-ai-runner:latest
    user: claude
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    volumes:
      - ./:/home/claude/workspace:rw
```

### Development Configuration

```yaml
version: '3.8'

services:
  gha-runner:
    build: .
    user: claude
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - RUN_PREFLIGHT=true
      - LOG_LEVEL=debug
    volumes:
      - ./:/home/claude/workspace:rw
      - ${HOME}/.claude/agents:/home/claude/.claude/agents:ro
      - ./.secrets:/home/claude/.secrets:ro
      - go-cache:/go/pkg/mod
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G

volumes:
  go-cache:
```

### Production Configuration

```yaml
version: '3.8'

services:
  gha-runner:
    image: zeeke-ai-runner:v1.0.0
    user: claude
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
      - RUN_PREFLIGHT=true
      - LOG_LEVEL=info
      - LOG_FORMAT=json
      - OTEL_ENDPOINT=${OTEL_ENDPOINT}
      - OTEL_EXPORTER_OTLP_HEADERS=${OTEL_HEADERS}
    volumes:
      - ./:/home/claude/workspace:rw
      - ./.secrets:/home/claude/.secrets:ro
      - go-cache:/go/pkg/mod
      - go-build-cache:/home/claude/.cache/go-build
    deploy:
      resources:
        limits:
          cpus: '8'
          memory: 16G
        reservations:
          cpus: '4'
          memory: 8G
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "claude", "--version"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    security_opt:
      - no-new-privileges:true
    labels:
      com.example.service: "github-actions-runner"
      com.example.version: "1.0.0"

volumes:
  go-cache:
    driver: local
  go-build-cache:
    driver: local
```

## Related Documentation

- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions
- [Setup Guide](../SETUP_GUIDE.md) - Initial setup instructions
- [API Reference](API_REFERENCE.md) - Script and command reference
