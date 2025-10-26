# Migration Guide

Guide for migrating to the GitHub Actions Runner image from various environments and previous versions.

## Table of Contents

- [Migration Overview](#migration-overview)
- [From GitHub-Hosted Runners](#from-github-hosted-runners)
- [From Vanilla Docker Runner](#from-vanilla-docker-runner)
- [From Other Self-Hosted Runners](#from-other-self-hosted-runners)
- [Version Migrations](#version-migrations)
- [Troubleshooting Migration Issues](#troubleshooting-migration-issues)

## Migration Overview

### What This Guide Covers

- Moving from GitHub-hosted runners to this self-hosted container
- Migrating from basic Docker setups to this integrated solution
- Upgrading from previous versions of this image
- Adapting existing workflows and configurations

### Before You Begin

**Checklist:**
- [ ] Review current workflow configurations
- [ ] Document existing environment variables and secrets
- [ ] Backup current runner configurations
- [ ] Note custom tools and dependencies
- [ ] Identify workflow-specific requirements
- [ ] Plan testing strategy for migrated workflows

**Required Information:**
- GitHub repository URLs
- List of secrets and environment variables
- Custom action dependencies
- Resource requirements (CPU, memory, disk)
- Network requirements and firewall rules

## From GitHub-Hosted Runners

### Overview

Migrating from GitHub's hosted runners (`ubuntu-latest`, `ubuntu-22.04`, etc.) to this self-hosted container.

### Key Differences

| Aspect | GitHub-Hosted | This Container |
|--------|---------------|----------------|
| **Environment** | Ephemeral, fresh each run | Persistent, configurable |
| **Tools** | Extensive pre-installed | Focused on Go/Claude/Python |
| **Storage** | 14 GB SSD | Configurable |
| **RAM** | 7 GB | Configurable (default 8 GB) |
| **CPU** | 2 cores | Configurable (default 4 cores) |
| **Secrets** | GitHub secrets | Environment variables/.secrets |
| **Cost** | Free (limits apply) | Self-hosted (infrastructure cost) |

### Migration Steps

#### Step 1: Analyze Current Workflows

**Identify Required Tools:**
```yaml
# Example GitHub-hosted workflow
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v3
  - uses: actions/setup-go@v4
    with:
      go-version: '1.25'
  - uses: actions/setup-node@v3
    with:
      node-version: '20'
  - uses: actions/setup-python@v4
    with:
      python-version: '3.11'
```

**Check if included in container:**
- Go 1.25 ✓ (included)
- Node.js 20 ✓ (included)
- Python 3.11 ✓ (included)

**Additional tools needed:**
- Check [Container Tools List](../README.md#whats-included)
- Add missing tools to Dockerfile if needed

#### Step 2: Update Workflow Files

**Before (GitHub-hosted):**
```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.25'
      - name: Run tests
        run: go test ./...
```

**After (Self-hosted):**
```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: self-hosted
    # Or use specific labels
    # runs-on: [self-hosted, linux, docker]

    steps:
      - uses: actions/checkout@v3
      # No need for setup-go - already installed
      - name: Run tests
        run: go test ./...
```

**Key Changes:**
- Change `runs-on: ubuntu-latest` to `runs-on: self-hosted`
- Remove setup actions for pre-installed tools (Go, Node, Python)
- Adjust paths if needed (workspace is `/home/claude/workspace`)

#### Step 3: Migrate Secrets

**GitHub Secrets → Container Secrets**

**Option 1: Environment Variables**
```bash
# Create .secrets file
cat > .secrets << 'EOF'
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
NPM_TOKEN=npm_xxxxxxxxxxxxx
EOF

chmod 600 .secrets
```

**Option 2: Docker Secrets (Production)**
```bash
# Create Docker secrets
echo "ghp_xxx" | docker secret create github_token -
echo "sk-ant-xxx" | docker secret create anthropic_key -

# Update docker-compose.yml
services:
  gha-runner:
    secrets:
      - github_token
      - anthropic_key

secrets:
  github_token:
    external: true
  anthropic_key:
    external: true
```

**Access in Workflows:**
```yaml
# Secrets are available as environment variables
steps:
  - name: Use secret
    run: echo "Token: $GITHUB_TOKEN"
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Step 4: Test Locally with act

**Before deploying to self-hosted runner, test with act:**

```bash
# Start container
./runner.sh start
./runner.sh shell

# Inside container, test workflow
act push -W .github/workflows/ci.yml -n  # Dry run
act push -W .github/workflows/ci.yml     # Full run
```

#### Step 5: Register Self-Hosted Runner

**Option A: Use this container for local testing only**
- Run workflows with `act`
- No GitHub runner registration needed

**Option B: Register as GitHub Actions runner**
```bash
# Inside container
./runner.sh shell

# Download and configure GitHub Actions runner
cd /tmp
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0-linux-x64.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# Configure
./config.sh --url https://github.com/owner/repo --token YOUR_TOKEN

# Run
./run.sh
```

#### Step 6: Update Repository Settings

1. Go to repository Settings → Actions → Runners
2. Verify self-hosted runner is connected
3. Optionally add labels for targeting
4. Update workflow files to use self-hosted runner

### Common Adjustments

#### File Paths

**GitHub-hosted:**
```yaml
# Workspace: /home/runner/work/repo/repo
working-directory: /home/runner/work/repo/repo
```

**This container:**
```yaml
# Workspace: /home/claude/workspace
working-directory: /home/claude/workspace
```

#### Tool Versions

**Check installed versions:**
```bash
./runner.sh shell
go version
node --version
python3 --version
```

**If different version needed:**
```bash
# Option 1: Rebuild with custom version
docker build --build-arg GO_VERSION=1.26.0 -t runner:latest .

# Option 2: Install in workflow
steps:
  - name: Install specific Go version
    run: |
      wget https://go.dev/dl/go1.26.0.linux-amd64.tar.gz
      sudo tar -C /usr/local -xzf go1.26.0.linux-amd64.tar.gz
```

#### Permissions

**GitHub-hosted:** Runs as `runner` user
**This container:** Runs as `claude` user (UID 1001)

```bash
# If permission issues, fix file ownership
sudo chown -R 1001:1001 /path/to/files
```

### Migration Checklist

- [ ] Workflows updated to use `runs-on: self-hosted`
- [ ] Setup actions removed for pre-installed tools
- [ ] Secrets migrated to .secrets file or Docker secrets
- [ ] Workflows tested locally with act
- [ ] File paths adjusted if needed
- [ ] Tool versions verified
- [ ] Self-hosted runner registered (if using GitHub Actions)
- [ ] First workflow run successful
- [ ] Resource usage monitored
- [ ] Documentation updated

## From Vanilla Docker Runner

### Overview

Migrating from a basic Docker container used for running workflows.

### Typical Vanilla Setup

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential
```

```bash
docker run -v $(pwd):/workspace ubuntu-runner:latest bash -c "cd /workspace && make test"
```

### Migration Benefits

| Feature | Vanilla Docker | This Image |
|---------|----------------|------------|
| Go toolchain | Manual install | ✓ Pre-installed |
| Claude Code | Not included | ✓ Integrated |
| act support | Manual setup | ✓ Built-in |
| MCP servers | Not supported | ✓ Supported |
| Agents | Not available | ✓ Ready to use |
| Workflow validation | Manual | ✓ actionlint included |
| Scripts | None | ✓ Management scripts |

### Migration Steps

#### Step 1: Identify Dependencies

**Inventory current setup:**
```bash
# In your vanilla container
which go
which node
which python3
# ... list all required tools
```

**Check if included:**
- Review [Container Tools](../README.md#whats-included)
- Note any custom tools needed

#### Step 2: Build Custom Image (if needed)

**If additional tools required:**

```dockerfile
# Dockerfile.custom
FROM zeeke-ai-runner:latest

USER root

# Add custom tools
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Switch back to claude user
USER claude
```

**Build:**
```bash
docker build -f Dockerfile.custom -t my-runner:latest .
```

#### Step 3: Update Scripts

**Before (vanilla):**
```bash
docker run -v $(pwd):/workspace \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  ubuntu-runner:latest \
  bash -c "cd /workspace && make test"
```

**After (this image):**
```bash
# Use docker-compose
./runner.sh start
./runner.sh shell
# Inside: make test

# Or one-off command
docker compose run --rm gha-runner make test
```

#### Step 4: Migrate Environment

**Update environment variables:**
```yaml
# docker-compose.yml
environment:
  - GITHUB_TOKEN=${GITHUB_TOKEN}
  - CUSTOM_VAR=${CUSTOM_VAR}
  # Add all your env vars
```

#### Step 5: Migrate Volumes

**Before:**
```bash
-v $(pwd):/workspace
-v ~/.ssh:/root/.ssh:ro
-v /var/run/docker.sock:/var/run/docker.sock
```

**After:**
```yaml
# docker-compose.yml
volumes:
  - ./:/home/claude/workspace:rw
  - ~/.ssh:/home/claude/.ssh:ro
  - /var/run/docker.sock:/var/run/docker.sock
```

**Note:** Change `/root/` to `/home/claude/` (non-root user)

### Migration Checklist

- [ ] All required tools available or added to custom image
- [ ] Environment variables migrated
- [ ] Volume mounts updated for non-root user
- [ ] Scripts updated to use runner.sh or docker-compose
- [ ] File permissions adjusted for UID 1001
- [ ] Testing scripts validated
- [ ] Documentation updated

## From Other Self-Hosted Runners

### From actions-runner-controller (ARC)

**Kubernetes-based runner controller → This container**

#### Key Differences

| Aspect | ARC | This Container |
|--------|-----|----------------|
| Orchestration | Kubernetes | Docker/Docker Compose |
| Scaling | Auto-scaling | Manual/fixed |
| Ephemeral | Yes | Optional |
| Management | kubectl | docker-compose/scripts |

#### Migration Path

**1. Export ARC Configuration:**
```bash
kubectl get runnerdeployment my-runner -o yaml > arc-config.yaml
```

**2. Extract Environment Variables:**
```yaml
# From arc-config.yaml spec.template.spec.env
env:
  - name: GITHUB_TOKEN
    valueFrom:
      secretKeyRef:
        name: github-secret
        key: token
```

**3. Create Equivalent .secrets:**
```bash
# Get secrets from Kubernetes
kubectl get secret github-secret -o jsonpath='{.data.token}' | base64 -d > .secrets
```

**4. Update to Docker Compose:**
```yaml
# docker-compose.yml
services:
  gha-runner:
    image: zeeke-ai-runner:latest
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    # ... rest of config
```

**5. Migrate from Ephemeral to Persistent (Optional):**
- ARC runners are ephemeral by default
- This container is persistent by default
- For ephemeral behavior, recreate container after each workflow

### From Jenkins Docker Agent

**Jenkins agent → GitHub Actions runner**

#### Migration Considerations

1. **Pipeline Syntax Changes**
   - Jenkinsfile → GitHub Actions YAML
   - Groovy → Shell/YAML syntax
   - Different plugin ecosystem

2. **Environment**
   - Jenkins workspace → GitHub workspace
   - Jenkins environment variables → GitHub contexts
   - Jenkins credentials → GitHub secrets

3. **Tool Access**
   - Both support Docker
   - Both can run arbitrary commands
   - This image includes Claude Code integration

#### Example Migration

**Before (Jenkinsfile):**
```groovy
pipeline {
    agent {
        docker {
            image 'golang:1.25'
        }
    }
    stages {
        stage('Test') {
            steps {
                sh 'go test ./...'
            }
        }
    }
}
```

**After (GitHub Actions):**
```yaml
name: CI
on: [push]

jobs:
  test:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v3
      - name: Test
        run: go test ./...
```

### From GitLab Runner

**GitLab CI → GitHub Actions with this container**

#### Key Mapping

| GitLab | GitHub Actions | This Container |
|--------|----------------|----------------|
| `.gitlab-ci.yml` | `.github/workflows/*.yml` | Same |
| `image:` | `runs-on:` | self-hosted |
| `variables:` | `env:` | environment vars |
| `before_script:` | Workflow steps | Entrypoint handles setup |
| `artifacts:` | `actions/upload-artifact` | Same |
| `cache:` | `actions/cache` | Volume mounts |

#### Migration Example

**Before (.gitlab-ci.yml):**
```yaml
image: golang:1.25

variables:
  GO111MODULE: "on"

test:
  stage: test
  script:
    - go test ./...
```

**After (.github/workflows/ci.yml):**
```yaml
name: CI
on: [push]

jobs:
  test:
    runs-on: self-hosted
    env:
      GO111MODULE: "on"
    steps:
      - uses: actions/checkout@v3
      - name: Test
        run: go test ./...
```

## Version Migrations

### Upgrading from v0.x to v1.0

#### Breaking Changes

1. **Directory Structure**
   - Old: `/workspace`
   - New: `/home/claude/workspace`

2. **User Change**
   - Old: `root` user (UID 0)
   - New: `claude` user (UID 1001)

3. **Environment Variables**
   - Removed: `RUNNER_WORKSPACE`
   - Added: `GITHUB_WORKSPACE`
   - Changed: `CLAUDE_CONFIG` → `CLAUDE_HOME`

4. **Volume Mounts**
   - Old: `./:/workspace`
   - New: `./:/home/claude/workspace`

#### Migration Steps

**1. Update docker-compose.yml:**

```diff
services:
  gha-runner:
    image: zeeke-ai-runner:latest
+   user: claude
    environment:
-     - RUNNER_WORKSPACE=/workspace
+     - GITHUB_WORKSPACE=/home/claude/workspace
    volumes:
-     - ./:/workspace:rw
+     - ./:/home/claude/workspace:rw
```

**2. Fix File Ownership:**

```bash
# Files created by old container (root-owned)
sudo chown -R 1001:1001 .

# Or match your user
sudo chown -R $USER:$USER .
```

**3. Update Scripts:**

```diff
# In CI scripts
- cd /workspace
+ cd /home/claude/workspace

- WORKSPACE=/workspace
+ WORKSPACE=/home/claude/workspace
```

**4. Rebuild:**

```bash
./runner.sh clean
./runner.sh build
./runner.sh start
```

#### Compatibility Mode

**Run as root (NOT RECOMMENDED):**
```yaml
services:
  gha-runner:
    user: root  # Security risk!
    environment:
      - RUNNER_ALLOW_RUNASROOT=1
```

### Upgrading v1.0 to v1.1

#### New Features

- Enhanced MCP server support
- Additional security scanning
- Improved health checks
- Better error messages

#### Changes

- No breaking changes
- Drop-in replacement
- Optional new configuration options

#### Migration Steps

**1. Pull New Image:**
```bash
docker pull zeeke-ai-runner:v1.1.0
```

**2. Update docker-compose.yml:**
```yaml
services:
  gha-runner:
    image: zeeke-ai-runner:v1.1.0  # Update version
```

**3. Restart:**
```bash
./runner.sh restart
```

**4. Verify:**
```bash
./runner.sh shell
claude --version
```

### Upgrading v1.1 to v2.0 (Future)

*To be documented when v2.0 is released*

**Expected Breaking Changes:**
- TBD

**Migration Guide:**
- TBD

## Troubleshooting Migration Issues

### Permission Errors After Migration

**Symptoms:**
```
Permission denied: /home/claude/workspace/file.txt
```

**Solution:**
```bash
# Fix ownership
sudo chown -R 1001:1001 .

# Or match your user
sudo chown -R $USER:$USER .

# Fix permissions
chmod -R u+rw .
```

### Workflows Fail with "Tool Not Found"

**Symptoms:**
```
bash: custom-tool: command not found
```

**Solution:**

**Option 1: Add to Dockerfile**
```dockerfile
FROM zeeke-ai-runner:latest
USER root
RUN apt-get update && apt-get install -y custom-tool
USER claude
```

**Option 2: Install in Workflow**
```yaml
steps:
  - name: Install custom tool
    run: |
      wget https://example.com/custom-tool
      chmod +x custom-tool
      sudo mv custom-tool /usr/local/bin/
```

### Secrets Not Available

**Symptoms:**
```
Error: GITHUB_TOKEN is not set
```

**Solution:**

**Check .secrets file:**
```bash
cat .secrets
# Should contain: GITHUB_TOKEN=ghp_xxx

# Fix permissions
chmod 600 .secrets

# Restart container
./runner.sh restart
```

**Verify environment:**
```bash
./runner.sh shell
env | grep GITHUB_TOKEN
```

### Container Exits Immediately

**Symptoms:**
```
zeeke-ai-runner exited with code 1
```

**Solution:**

**Check logs:**
```bash
docker logs zeeke-ai-runner
```

**Common causes:**
- Missing required tool (Claude, Go, Python)
- Invalid entrypoint
- Permission errors

**Debug:**
```bash
# Run with bash directly
docker run -it --rm zeeke-ai-runner:latest /bin/bash

# Inside container, check tools
claude --version
go version
python3 --version
```

### Volume Mount Issues

**Symptoms:**
```
ls: cannot access '/home/claude/workspace': No such file or directory
```

**Solution:**

**Verify mount:**
```bash
docker inspect zeeke-ai-runner | jq '.[0].Mounts'
```

**Fix docker-compose.yml:**
```yaml
volumes:
  # Ensure absolute path or ./ for current dir
  - ./:/home/claude/workspace:rw

  # NOT relative paths like:
  # - workspace:/home/claude/workspace  # Wrong!
```

### High Memory Usage

**Symptoms:**
```
Container killed (OOM)
```

**Solution:**

**Increase memory limit:**
```yaml
deploy:
  resources:
    limits:
      memory: 16G  # Increase from 8G
```

**Or optimize builds:**
```bash
# Reduce parallel builds
export GOMAXPROCS=2
make -j2
```

### Network Connectivity Issues

**Symptoms:**
```
dial tcp: lookup github.com: no such host
```

**Solution:**

**Add DNS servers:**
```yaml
dns:
  - 8.8.8.8
  - 8.8.4.4
```

**Or use host network (testing only):**
```yaml
network_mode: host
```

## Getting Help

### Before Asking for Help

1. **Check Documentation:**
   - [Troubleshooting Guide](TROUBLESHOOTING.md)
   - [Configuration Guide](CONFIGURATION.md)
   - [Setup Guide](../SETUP_GUIDE.md)

2. **Collect Debug Information:**
   ```bash
   # System info
   docker --version
   docker compose version

   # Container logs
   docker logs zeeke-ai-runner > container.log

   # Configuration
   docker compose config > config.yaml
   ```

3. **Search Existing Issues:**
   - Check GitHub Issues for similar problems
   - Review closed issues for solutions

### Creating a Support Request

**Include:**
- Migration source (GitHub-hosted, vanilla Docker, etc.)
- Current version and target version
- Complete error messages
- Relevant configuration (sanitize secrets!)
- Steps already attempted
- Environment details (OS, Docker version)

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Environment variables and settings
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions
- [API Reference](API_REFERENCE.md) - Script and command reference
- [Setup Guide](../SETUP_GUIDE.md) - Initial setup instructions
