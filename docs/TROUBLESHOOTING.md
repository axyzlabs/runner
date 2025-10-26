# Troubleshooting Guide

This guide covers common issues and their solutions when working with the GitHub Actions Runner image.

## Table of Contents

- [Container Issues](#container-issues)
- [Claude CLI Issues](#claude-cli-issues)
- [MCP Server Issues](#mcp-server-issues)
- [GitHub Connection Issues](#github-connection-issues)
- [Permission Issues](#permission-issues)
- [Resource Issues](#resource-issues)
- [Build Issues](#build-issues)
- [Workflow Issues](#workflow-issues)
- [Network Issues](#network-issues)
- [General Diagnostics](#general-diagnostics)

## Container Issues

### Container Won't Start

**Symptoms:**
- `docker compose up` fails
- Container exits immediately
- Container stuck in restarting loop

**Diagnosis:**
```bash
# Check container status
docker ps -a

# View container logs
docker logs zeeke-ai-runner

# Check Docker daemon
docker info
```

**Solutions:**

1. **Check Docker Daemon:**
   ```bash
   # Verify Docker is running
   systemctl status docker

   # Restart if needed
   sudo systemctl restart docker
   ```

2. **Verify Docker Compose File:**
   ```bash
   # Validate syntax
   docker compose config

   # Check for errors
   docker compose -f docker-compose.yml config --quiet
   ```

3. **Check Port Conflicts:**
   ```bash
   # List used ports
   netstat -tuln | grep LISTEN

   # Or use ss
   ss -tuln
   ```

4. **Verify Volume Mounts:**
   ```bash
   # Check that mounted directories exist
   ls -la ~/.claude/agents
   ls -la $(pwd)

   # Create missing directories
   mkdir -p ~/.claude/agents
   ```

5. **Check Resource Limits:**
   ```bash
   # View Docker resource usage
   docker stats --no-stream

   # Check system resources
   free -h
   df -h
   ```

### Container Exits Immediately

**Symptoms:**
- Container starts but exits with code 0 or 1
- No interactive shell available

**Solutions:**

1. **Check Entrypoint:**
   ```bash
   # View entrypoint logs
   docker logs zeeke-ai-runner

   # Run with custom command
   docker run -it --rm zeeke-ai-runner:latest /bin/bash
   ```

2. **Verify Tool Installations:**
   ```bash
   # Enter container to check
   docker run -it --rm zeeke-ai-runner:latest bash

   # Inside container
   claude --version
   go version
   python3 --version
   ```

3. **Check Environment Variables:**
   ```bash
   # View container environment
   docker inspect zeeke-ai-runner | jq '.[0].Config.Env'

   # Run with env vars
   docker run -e DEBUG=true -it zeeke-ai-runner:latest
   ```

### Container Stuck in Unhealthy State

**Symptoms:**
- Health check fails repeatedly
- Container marked as unhealthy

**Solutions:**

1. **Check Health Check Command:**
   ```bash
   # View health check config
   docker inspect zeeke-ai-runner | jq '.[0].State.Health'

   # Run health check manually
   docker exec zeeke-ai-runner claude --version
   ```

2. **Increase Health Check Timeouts:**
   ```yaml
   # In docker-compose.yml
   healthcheck:
     test: ["CMD", "claude", "--version"]
     interval: 60s      # Increase from 30s
     timeout: 20s       # Increase from 10s
     retries: 5         # Increase from 3
     start_period: 60s  # Increase from 30s
   ```

3. **Disable Health Check Temporarily:**
   ```bash
   # Run without health check
   docker run --no-healthcheck -it zeeke-ai-runner:latest
   ```

## Claude CLI Issues

### Claude CLI Not Found

**Symptoms:**
- `claude: command not found`
- Claude commands fail in container

**Solutions:**

1. **Verify Installation:**
   ```bash
   # Check if claude binary exists
   docker exec zeeke-ai-runner which claude

   # Check PATH
   docker exec zeeke-ai-runner echo $PATH
   ```

2. **Reinstall Claude CLI:**
   ```bash
   # Rebuild image
   ./build.sh

   # Or install manually in container
   docker exec -u root zeeke-ai-runner npm install -g @anthropic-ai/claude-cli
   ```

3. **Check Permissions:**
   ```bash
   # Verify executable permissions
   docker exec zeeke-ai-runner ls -la /usr/local/bin/claude

   # Fix if needed (as root)
   docker exec -u root zeeke-ai-runner chmod +x /usr/local/bin/claude
   ```

### Claude CLI Authentication Failed

**Symptoms:**
- `Authentication failed` error
- `Invalid API key` messages

**Solutions:**

1. **Verify API Key:**
   ```bash
   # Check if key is set
   docker exec zeeke-ai-runner env | grep ANTHROPIC_API_KEY

   # Test key format
   echo $ANTHROPIC_API_KEY | grep -E '^sk-ant-'
   ```

2. **Set API Key:**
   ```bash
   # Via .secrets file
   echo "ANTHROPIC_API_KEY=sk-ant-xxx" >> .secrets

   # Via environment
   export ANTHROPIC_API_KEY="sk-ant-xxx"
   docker compose up -d
   ```

3. **Verify Key Permissions:**
   ```bash
   # Check .secrets file permissions
   ls -la .secrets

   # Should be readable by Docker
   chmod 600 .secrets
   ```

### Claude Code Agents Not Loading

**Symptoms:**
- Agents not available in Claude Code
- `No agents found` message

**Solutions:**

1. **Check Agent Mounts:**
   ```bash
   # Verify mount exists
   docker exec zeeke-ai-runner ls -la /home/claude/.claude/agents

   # Check host directory
   ls -la ~/.claude/agents
   ```

2. **Verify Agent Files:**
   ```bash
   # List agent files
   docker exec zeeke-ai-runner find /home/claude/.claude/agents -type f

   # Check file format
   docker exec zeeke-ai-runner cat /home/claude/.claude/agents/devops-engineer.yml
   ```

3. **Check Permissions:**
   ```bash
   # Verify read permissions
   docker exec zeeke-ai-runner ls -la /home/claude/.claude/agents

   # Fix on host if needed
   chmod -R 755 ~/.claude/agents
   ```

## MCP Server Issues

### MCP Configuration Not Found

**Symptoms:**
- `MCP configuration not found` warning
- MCP servers not available

**Solutions:**

1. **Create MCP Configuration:**
   ```bash
   # Inside container
   docker exec zeeke-ai-runner bash -c 'mkdir -p /home/claude/.claude'

   # Create basic config
   cat > mcp-config.json << 'EOF'
   {
     "mcpServers": {}
   }
   EOF

   docker cp mcp-config.json zeeke-ai-runner:/home/claude/.claude/.mcp.json
   ```

2. **Verify Configuration Path:**
   ```bash
   # Check if file exists
   docker exec zeeke-ai-runner ls -la /home/claude/.claude/.mcp.json

   # View configuration
   docker exec zeeke-ai-runner cat /home/claude/.claude/.mcp.json
   ```

### Skill Seekers MCP Not Working

**Symptoms:**
- Skill Seekers server not responding
- MCP connection errors

**Solutions:**

1. **Verify Mount:**
   ```bash
   # Check if Skill Seekers is mounted
   docker exec zeeke-ai-runner ls -la /mcp/skill-seekers

   # Verify server file
   docker exec zeeke-ai-runner ls -la /mcp/skill-seekers/mcp/server.py
   ```

2. **Check Python Dependencies:**
   ```bash
   # Test Python import
   docker exec zeeke-ai-runner python3 -c "import anthropic"

   # Install missing dependencies
   docker exec zeeke-ai-runner pip install -r /mcp/skill-seekers/requirements.txt
   ```

3. **Test Server Manually:**
   ```bash
   # Run server directly
   docker exec zeeke-ai-runner python3 /mcp/skill-seekers/mcp/server.py

   # Check for errors
   docker logs zeeke-ai-runner 2>&1 | grep -i mcp
   ```

4. **Update MCP Configuration:**
   ```bash
   # Set correct path
   export SKILL_SEEKERS_PATH=/path/to/skill-seekers
   docker compose up -d
   ```

## GitHub Connection Issues

### GitHub Authentication Failed

**Symptoms:**
- `Authentication failed` when using gh CLI
- Git push/pull fails with auth error

**Solutions:**

1. **Verify GitHub Token:**
   ```bash
   # Check if token is set
   docker exec zeeke-ai-runner env | grep GITHUB_TOKEN

   # Test token validity
   curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
   ```

2. **Set GitHub Token:**
   ```bash
   # Via .secrets
   echo "GITHUB_TOKEN=ghp_xxx" >> .secrets

   # Or via environment
   export GITHUB_TOKEN="ghp_xxx"
   docker compose restart
   ```

3. **Re-authenticate gh CLI:**
   ```bash
   # Inside container
   echo $GITHUB_TOKEN | gh auth login --with-token

   # Verify
   gh auth status
   ```

### Git Operations Fail

**Symptoms:**
- `Permission denied` on git push
- `Authentication required` errors

**Solutions:**

1. **Configure Git Credentials:**
   ```bash
   # Set up credential helper
   docker exec zeeke-ai-runner git config --global credential.helper store

   # Or use gh CLI for auth
   docker exec zeeke-ai-runner gh auth setup-git
   ```

2. **Verify Git Configuration:**
   ```bash
   # Check git config
   docker exec zeeke-ai-runner git config --list

   # Set user info if missing
   docker exec zeeke-ai-runner git config --global user.name "Your Name"
   docker exec zeeke-ai-runner git config --global user.email "you@example.com"
   ```

3. **Use SSH Instead of HTTPS:**
   ```bash
   # Mount SSH keys
   docker run -v ~/.ssh:/home/claude/.ssh:ro zeeke-ai-runner:latest

   # Configure SSH
   docker exec zeeke-ai-runner ssh-keyscan github.com >> ~/.ssh/known_hosts
   ```

### Cannot Access Private Repositories

**Symptoms:**
- `Repository not found` for private repos
- 404 errors when cloning

**Solutions:**

1. **Verify Token Scopes:**
   ```bash
   # Check token permissions
   curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos?type=private

   # Token needs: repo scope for private repos
   ```

2. **Create Token with Correct Scopes:**
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Create token with `repo` scope
   - Update .secrets file

3. **Test Repository Access:**
   ```bash
   # Test clone
   docker exec zeeke-ai-runner gh repo clone owner/private-repo /tmp/test
   ```

## Permission Issues

### Permission Denied Errors

**Symptoms:**
- `Permission denied` when accessing files
- Cannot write to mounted volumes

**Solutions:**

1. **Check File Ownership:**
   ```bash
   # Check ownership on host
   ls -la $(pwd)

   # Check inside container
   docker exec zeeke-ai-runner ls -la /home/claude/workspace
   ```

2. **Fix Ownership:**
   ```bash
   # On host (if files owned by root)
   sudo chown -R $USER:$USER $(pwd)

   # Inside container (claude user is UID 1001)
   docker exec -u root zeeke-ai-runner chown -R claude:claude /home/claude/workspace
   ```

3. **Verify User:**
   ```bash
   # Check running user
   docker exec zeeke-ai-runner whoami
   # Should output: claude

   # Check UID
   docker exec zeeke-ai-runner id
   # Should show uid=1001(claude)
   ```

### Cannot Access Docker Socket

**Symptoms:**
- `Permission denied` when running act
- Docker commands fail inside container

**Solutions:**

1. **Check Docker Socket Permissions:**
   ```bash
   # On host
   ls -la /var/run/docker.sock

   # Should be accessible to docker group
   sudo chmod 666 /var/run/docker.sock
   ```

2. **Add User to Docker Group:**
   ```bash
   # On host
   sudo usermod -aG docker $USER

   # Log out and back in
   ```

3. **Run with Docker Group:**
   ```bash
   # Get docker group ID on host
   getent group docker | cut -d: -f3

   # Update docker-compose.yml
   services:
     gha-runner:
       group_add:
         - "999"  # Your docker GID
   ```

### Cannot Write to Cache Directories

**Symptoms:**
- Go build cache errors
- npm install fails

**Solutions:**

1. **Check Volume Permissions:**
   ```bash
   # Inspect volumes
   docker volume inspect runner_go-cache

   # Remove and recreate if needed
   docker compose down -v
   docker compose up -d
   ```

2. **Use User-Scoped Volumes:**
   ```bash
   # Create volumes with correct permissions
   docker volume create --driver local \
     --opt type=none \
     --opt device=$HOME/.cache/go-build \
     --opt o=bind \
     go-build-cache
   ```

## Resource Issues

### Out of Memory Errors

**Symptoms:**
- Container killed by OOM
- Build processes fail
- `killed` messages in logs

**Solutions:**

1. **Check Memory Usage:**
   ```bash
   # View container stats
   docker stats zeeke-ai-runner --no-stream

   # Check memory limit
   docker inspect zeeke-ai-runner | jq '.[0].HostConfig.Memory'
   ```

2. **Increase Memory Limit:**
   ```yaml
   # In docker-compose.yml
   deploy:
     resources:
       limits:
         memory: 16G  # Increase from 8G
       reservations:
         memory: 8G   # Increase from 4G
   ```

3. **Optimize Build Process:**
   ```bash
   # Use less parallelism for Go builds
   export GOMAXPROCS=2

   # Limit parallel npm installs
   npm install --maxsockets 1
   ```

4. **Check System Memory:**
   ```bash
   # View system memory
   free -h

   # Check Docker daemon limits
   docker info | grep -i memory
   ```

### CPU Throttling

**Symptoms:**
- Slow build times
- High CPU usage
- Processes taking longer than expected

**Solutions:**

1. **Check CPU Usage:**
   ```bash
   # View container CPU
   docker stats zeeke-ai-runner --no-stream

   # Check CPU limit
   docker inspect zeeke-ai-runner | jq '.[0].HostConfig.CpuQuota'
   ```

2. **Increase CPU Limit:**
   ```yaml
   # In docker-compose.yml
   deploy:
     resources:
       limits:
         cpus: '8'  # Increase from 4
       reservations:
         cpus: '4'  # Increase from 2
   ```

3. **Optimize Parallel Builds:**
   ```bash
   # Set Go build parallelism
   export GOMAXPROCS=4

   # Set make parallelism
   make -j4
   ```

### Disk Space Issues

**Symptoms:**
- `No space left on device`
- Build fails with disk errors
- Container cannot write files

**Solutions:**

1. **Check Disk Usage:**
   ```bash
   # Check container disk usage
   docker exec zeeke-ai-runner df -h

   # Check host disk usage
   df -h

   # Check Docker disk usage
   docker system df
   ```

2. **Clean Up Docker:**
   ```bash
   # Remove unused images
   docker image prune -a

   # Remove unused volumes
   docker volume prune

   # Full cleanup
   docker system prune -a --volumes
   ```

3. **Clean Build Artifacts:**
   ```bash
   # Inside container
   docker exec zeeke-ai-runner bash -c '
     go clean -cache -modcache
     npm cache clean --force
     pip cache purge
   '
   ```

## Build Issues

### Build Fails with Network Errors

**Symptoms:**
- `Connection timeout` during build
- Cannot download packages
- `Name resolution failed`

**Solutions:**

1. **Check Network Connectivity:**
   ```bash
   # Test DNS
   docker run --rm alpine ping -c 3 google.com

   # Test HTTPS
   docker run --rm alpine wget -O- https://www.google.com
   ```

2. **Configure DNS:**
   ```json
   // In /etc/docker/daemon.json
   {
     "dns": ["8.8.8.8", "8.8.4.4"]
   }
   ```
   ```bash
   sudo systemctl restart docker
   ```

3. **Use Proxy:**
   ```bash
   # Set proxy during build
   docker build \
     --build-arg HTTP_PROXY=http://proxy:port \
     --build-arg HTTPS_PROXY=http://proxy:port \
     -t zeeke-ai-runner:latest .
   ```

### Base Image Pull Fails

**Symptoms:**
- `Error pulling image`
- `manifest unknown`

**Solutions:**

1. **Verify Base Image:**
   ```bash
   # Test pull manually
   docker pull ghcr.io/catthehacker/ubuntu:act-latest
   ```

2. **Use Alternative Base:**
   ```dockerfile
   # In Dockerfile, try different base
   FROM ubuntu:22.04 AS base
   # Instead of ghcr.io/catthehacker/ubuntu:act-latest
   ```

3. **Authenticate to GHCR:**
   ```bash
   # Login to GitHub Container Registry
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

### Go Module Download Fails

**Symptoms:**
- `go: module not found`
- Checksum mismatch errors

**Solutions:**

1. **Clear Go Cache:**
   ```bash
   # Remove go modules cache volume
   docker compose down -v
   docker compose up -d
   ```

2. **Use Go Proxy:**
   ```bash
   # Set Go proxy
   export GOPROXY=https://proxy.golang.org,direct
   docker compose up -d
   ```

3. **Update Go Modules:**
   ```bash
   # Inside container
   docker exec zeeke-ai-runner bash -c '
     go clean -modcache
     go mod tidy
     go mod download
   '
   ```

## Workflow Issues

### act Cannot Run Workflows

**Symptoms:**
- `Error: unable to get git repo`
- Workflow validation fails

**Solutions:**

1. **Verify Workflow Syntax:**
   ```bash
   # Use actionlint
   docker exec zeeke-ai-runner actionlint .github/workflows/*.yml
   ```

2. **Check Docker Socket:**
   ```bash
   # Verify docker is accessible
   docker exec zeeke-ai-runner docker ps

   # If fails, check socket mount
   ls -la /var/run/docker.sock
   ```

3. **Run with Verbose Output:**
   ```bash
   # See detailed errors
   docker exec zeeke-ai-runner act -v push
   ```

### Workflow Missing Secrets

**Symptoms:**
- Secrets not available in workflow
- Environment variables empty

**Solutions:**

1. **Pass Secrets to act:**
   ```bash
   # Create .secrets file for act
   cat > .secrets << 'EOF'
   GITHUB_TOKEN=ghp_xxx
   ANTHROPIC_API_KEY=sk-ant-xxx
   EOF

   # Run with secrets
   docker exec zeeke-ai-runner act -s GITHUB_TOKEN
   ```

2. **Use Environment File:**
   ```bash
   # Create .env file
   echo "GITHUB_TOKEN=ghp_xxx" > .env

   # Load in act
   docker exec zeeke-ai-runner act --env-file .env
   ```

## Network Issues

### Cannot Connect to External Services

**Symptoms:**
- `Connection refused`
- Cannot reach external APIs
- Timeout errors

**Solutions:**

1. **Check Network Mode:**
   ```bash
   # View network config
   docker inspect zeeke-ai-runner | jq '.[0].HostConfig.NetworkMode'

   # Test connectivity
   docker exec zeeke-ai-runner ping -c 3 8.8.8.8
   ```

2. **Use Host Network:**
   ```yaml
   # In docker-compose.yml (for testing)
   network_mode: host
   ```

3. **Configure Firewall:**
   ```bash
   # Check firewall rules
   sudo iptables -L -n

   # Allow Docker network
   sudo ufw allow from 172.17.0.0/16
   ```

### DNS Resolution Fails

**Symptoms:**
- `Name resolution failed`
- Cannot resolve domain names

**Solutions:**

1. **Test DNS:**
   ```bash
   # Inside container
   docker exec zeeke-ai-runner nslookup github.com
   docker exec zeeke-ai-runner cat /etc/resolv.conf
   ```

2. **Configure Docker DNS:**
   ```bash
   # Add to docker-compose.yml
   dns:
     - 8.8.8.8
     - 8.8.4.4
   ```

## General Diagnostics

### Collecting Debug Information

When reporting issues, collect this information:

```bash
#!/bin/bash
# Debug information collection script

echo "=== System Information ==="
uname -a
docker --version
docker compose version

echo "=== Container Status ==="
docker ps -a | grep zeeke-ai-runner

echo "=== Container Logs (last 50 lines) ==="
docker logs --tail 50 zeeke-ai-runner

echo "=== Image Information ==="
docker images zeeke-ai-runner:latest

echo "=== Resource Usage ==="
docker stats --no-stream zeeke-ai-runner

echo "=== Volume Mounts ==="
docker inspect zeeke-ai-runner | jq '.[0].Mounts'

echo "=== Environment Variables ==="
docker exec zeeke-ai-runner env | grep -E 'GITHUB|ANTHROPIC|CLAUDE'

echo "=== Disk Usage ==="
docker system df

echo "=== Network Configuration ==="
docker inspect zeeke-ai-runner | jq '.[0].NetworkSettings'
```

Save as `debug-info.sh`, run with:
```bash
chmod +x debug-info.sh
./debug-info.sh > debug-output.txt
```

### Enabling Debug Mode

Run container with additional debugging:

```bash
# Set debug environment variables
export DEBUG=true
export LOG_LEVEL=debug

# Run with verbose output
docker compose up

# Or run with shell debugging
docker run -it --rm \
  -e DEBUG=true \
  zeeke-ai-runner:latest \
  bash -x /entrypoint.sh
```

### Resetting to Clean State

If all else fails, reset to clean state:

```bash
# Stop and remove everything
docker compose down -v

# Remove images
docker rmi zeeke-ai-runner:latest

# Clean Docker system
docker system prune -a --volumes

# Rebuild from scratch
./build.sh
docker compose up -d
```

## Getting Help

If you cannot resolve your issue:

1. **Check the logs** thoroughly
2. **Search existing issues** on GitHub
3. **Create a new issue** with:
   - Problem description
   - Steps to reproduce
   - Output from debug-info.sh
   - Relevant log excerpts
   - Environment details

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Environment variables and settings
- [Setup Guide](../SETUP_GUIDE.md) - Initial setup instructions
- [API Reference](API_REFERENCE.md) - Script and command reference
