# GitHub Actions Runner - Claude Development Instructions

## Overview

This file provides instructions for Claude Code when working on the GitHub Actions Runner container project. This is a production-ready, reusable Docker container for running GitHub Actions workflows locally with Claude Code integration.

## Project Purpose

The runner container is designed to be:
- **Generic and Reusable**: Works across any project that uses GitHub Actions
- **Production-Ready**: Security hardened, non-root execution, comprehensive testing
- **Developer-Friendly**: Easy to use, well-documented, extensible
- **Claude Code Integrated**: Full support for agents, skills, and MCP servers

## Critical Instructions

### 1. Security First

**This is a Docker container that users will run in their environments. Security is paramount.**

**NEVER:**
- Include secrets or tokens in the image
- Run processes as root (always use `claude` user, UID 1001)
- Skip input validation in scripts
- Expose sensitive information in logs
- Create world-writable files or directories
- Install packages from unverified sources

**ALWAYS:**
- Use official base images with known security records
- Pin package versions in Dockerfile
- Set proper file permissions (scripts: 755, secrets: 600)
- Validate all user inputs in scripts
- Use least privilege principle
- Document security considerations

### 2. Backward Compatibility

**Users depend on this container. Breaking changes require major version bumps.**

**Before making changes:**
- Consider impact on existing users
- Maintain backward compatibility when possible
- Document breaking changes clearly
- Provide migration guides
- Version tag properly (semver)

**When adding features:**
- Make them opt-in when possible
- Use feature flags for experimental features
- Document new capabilities clearly
- Provide usage examples

### 3. Documentation Standards

**Every change must be documented.**

**Update these files as appropriate:**
- `README.md` - User-facing quick start and overview
- `SETUP_GUIDE.md` - Detailed setup and usage instructions
- `DOCKER_SETUP_SUMMARY.md` - Technical reference and troubleshooting
- `CLAUDE.md` - This file, for Claude Code instructions
- Inline comments in scripts and Dockerfile

**Documentation requirements:**
- Clear, concise language
- Practical examples
- Troubleshooting sections
- Security considerations
- Version compatibility notes

## File Structure and Purpose

```
runner/
├── CLAUDE.md                      # This file - development instructions
├── README.md                      # User-facing documentation
├── SETUP_GUIDE.md                 # Detailed setup guide
├── DOCKER_SETUP_SUMMARY.md        # Technical reference
├── LICENSE                        # MIT License
├── .gitignore                     # Git exclusions
├── Dockerfile                     # Multi-stage Docker build
├── docker-compose.yml             # Orchestration configuration
├── .dockerignore                  # Build context exclusions
├── build.sh                       # Build helper script
├── runner.sh                      # Container management script
├── entrypoint.sh                  # Container startup script
└── test-runner.sh                 # Test suite
```

## Development Workflow

### Working on the Dockerfile

**When modifying `Dockerfile`:**

1. **Read the current Dockerfile** to understand the build process
2. **Consider security implications** of any changes
3. **Test multi-stage builds** to ensure optimization
4. **Pin versions** for reproducibility
5. **Document changes** with inline comments
6. **Test the build** with `./build.sh`
7. **Run the test suite** with `./test-runner.sh`

**Multi-stage build structure:**
```dockerfile
# Stage 1: Base - Core dependencies (Go, Python, Node.js)
FROM base AS base

# Stage 2: Tools - Development tools (golangci-lint, act, actionlint)
FROM base AS tools

# Stage 3: Claude - Claude Code CLI and configuration
FROM tools AS claude

# Stage 4: Final - Runtime with proper permissions
FROM claude AS final
```

**Best practices:**
- Keep layers small and cacheable
- Group related commands with `&&`
- Clean up in the same layer (rm after install)
- Use BuildKit cache mounts for package managers
- Set `DEBIAN_FRONTEND=noninteractive` for apt

### Working on Scripts

**When modifying `build.sh`, `runner.sh`, `entrypoint.sh`, or `test-runner.sh`:**

1. **Use bash strict mode**: `set -euo pipefail`
2. **Validate inputs** before using them
3. **Provide helpful error messages** with context
4. **Use color coding** for better UX:
   - `${RED}` for errors
   - `${GREEN}` for success
   - `${YELLOW}` for warnings
   - `${BLUE}` for info
   - `${NC}` to reset color

5. **Make scripts idempotent** - safe to run multiple times
6. **Add usage/help output** for user-facing scripts
7. **Test error paths** not just happy paths

**Script standards:**
```bash
#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validate inputs
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Missing required argument${NC}"
    echo "Usage: $0 <argument>"
    exit 1
fi

# Use variables for paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### Working on Docker Compose

**When modifying `docker-compose.yml`:**

1. **Understand service dependencies** before changing
2. **Test volume mounts** - ensure permissions are correct
3. **Validate environment variables** - provide defaults
4. **Document service purpose** with comments
5. **Test resource limits** - ensure container functions
6. **Verify network configuration** - test connectivity

**Key sections:**
- `services.runner.volumes` - Workspace and agent mounts
- `services.runner.environment` - Configuration
- `services.runner.deploy.resources` - CPU/memory limits
- `services.runner.healthcheck` - Container health monitoring

### Testing Changes

**Before committing any changes:**

1. **Build the image**:
   ```bash
   ./build.sh
   ```

2. **Run the test suite**:
   ```bash
   ./test-runner.sh
   ```

3. **Start the container**:
   ```bash
   ./runner.sh start
   ```

4. **Access and verify**:
   ```bash
   ./runner.sh shell
   # Inside container, verify tools work:
   claude --version
   go version
   act --version
   actionlint --version
   ```

5. **Test with a real workflow**:
   ```bash
   # Inside container:
   cd /tmp
   mkdir test-project
   cd test-project
   git init
   mkdir -p .github/workflows

   # Create simple workflow
   cat > .github/workflows/test.yml << 'EOF'
   name: Test
   on: push
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - run: echo "Hello from act"
   EOF

   # Test with act
   act -l
   act push
   ```

6. **Verify resource usage**:
   ```bash
   # On host:
   docker stats zeeke-ai-runner --no-stream
   ```

7. **Check logs for errors**:
   ```bash
   ./runner.sh logs
   ```

## Code Quality Standards

### Shell Scripts

**Required:**
- Shellcheck clean (no warnings or errors)
- Bash strict mode (`set -euo pipefail`)
- Input validation
- Error handling with informative messages
- Executable bit set (`chmod +x`)

**Run shellcheck**:
```bash
shellcheck build.sh runner.sh entrypoint.sh test-runner.sh
```

### Dockerfile

**Required:**
- Hadolint clean (no warnings for security)
- Multi-stage builds for optimization
- Non-root user for runtime
- Pinned versions for reproducibility
- Layer optimization (combine RUN commands)
- Health check defined

**Run hadolint**:
```bash
hadolint Dockerfile
```

### Docker Compose

**Required:**
- YAML syntax valid
- Services properly defined
- Resource limits set
- Health checks configured
- Proper volume mount permissions

**Validate**:
```bash
docker compose config
```

## Pre-Commit Checklist

**Before committing changes:**

### Build and Test
- [ ] `./build.sh` completes successfully
- [ ] `./test-runner.sh` passes all tests
- [ ] Container starts: `./runner.sh start`
- [ ] Can access shell: `./runner.sh shell`
- [ ] Tools work inside container

### Code Quality
- [ ] Shellcheck passes: `shellcheck *.sh`
- [ ] Hadolint passes: `hadolint Dockerfile`
- [ ] Docker Compose validates: `docker compose config`
- [ ] No hardcoded secrets or tokens
- [ ] Proper file permissions set

### Documentation
- [ ] README.md updated (if user-facing changes)
- [ ] SETUP_GUIDE.md updated (if setup changes)
- [ ] DOCKER_SETUP_SUMMARY.md updated (if technical changes)
- [ ] Inline comments added for complex logic
- [ ] CHANGELOG entry created (for releases)

### Security
- [ ] No secrets in image or code
- [ ] Non-root execution maintained
- [ ] Input validation in scripts
- [ ] File permissions appropriate
- [ ] Dependencies from trusted sources

## Common Tasks

### Adding a New Tool

**To add a new tool to the container:**

1. **Update Dockerfile** in appropriate stage:
   ```dockerfile
   # In tools stage
   RUN wget -qO /usr/local/bin/newtool \
       https://github.com/owner/newtool/releases/download/v1.0.0/newtool_linux_amd64 && \
       chmod +x /usr/local/bin/newtool
   ```

2. **Add version check in entrypoint.sh**:
   ```bash
   # Check newtool
   if command -v newtool &> /dev/null; then
       NEWTOOL_VERSION=$(newtool --version | head -n1)
       echo -e "${GREEN}✓${NC} newtool: ${NEWTOOL_VERSION}"
   else
       echo -e "${RED}✗${NC} newtool not found"
   fi
   ```

3. **Add test in test-runner.sh**:
   ```bash
   test_tool "newtool" "newtool --version"
   ```

4. **Document in README.md**:
   - Add to "What's Included" section
   - Add usage example if needed

5. **Test the changes**:
   ```bash
   ./build.sh
   ./test-runner.sh
   ./runner.sh shell
   newtool --version
   ```

### Updating Go Version

**To update the Go version:**

1. **Update Dockerfile**:
   ```dockerfile
   ARG GO_VERSION=1.26.0  # Update version
   ```

2. **Update documentation**:
   - README.md - Features section
   - DOCKER_SETUP_SUMMARY.md - Version section
   - SETUP_GUIDE.md - Requirements section

3. **Test Go toolchain**:
   ```bash
   ./build.sh
   ./runner.sh shell
   go version
   go build -o /tmp/test << 'EOF'
   package main
   func main() { println("test") }
   EOF
   /tmp/test
   ```

4. **Verify Go tools**:
   ```bash
   gofmt -h
   golangci-lint --version
   staticcheck -version
   ```

### Changing Base Image

**To change the base image:**

1. **Research the new base image**:
   - Security track record
   - Maintenance status
   - Size and dependencies
   - Compatibility with tools

2. **Update Dockerfile**:
   ```dockerfile
   FROM new-base-image:tag AS base
   ```

3. **Test thoroughly**:
   - All tools install correctly
   - Permissions are correct
   - Size is reasonable
   - Security scan passes

4. **Update documentation**:
   - Document base image change
   - Note any breaking changes
   - Update version compatibility

## Version Management

### Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes (e.g., removed tools, changed APIs)
- **MINOR**: New features (e.g., new tools, new capabilities)
- **PATCH**: Bug fixes (e.g., security patches, script fixes)

### Tagging Releases

**When creating a release:**

1. **Update version references**:
   - README.md examples
   - DOCKER_SETUP_SUMMARY.md version section
   - build.sh default tag (if applicable)

2. **Create git tag**:
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0 - Description"
   git push origin v1.1.0
   ```

3. **Build and tag images**:
   ```bash
   ./build.sh v1.1.0
   docker tag axyzlabs/runner:v1.1.0 axyzlabs/runner:latest
   ```

4. **Create GitHub release**:
   - Use tag v1.1.0
   - Add release notes
   - Link to documentation
   - List breaking changes if any

## Troubleshooting Development Issues

### Build Fails

**If `./build.sh` fails:**

1. **Check Docker BuildKit**:
   ```bash
   export DOCKER_BUILDKIT=1
   docker version
   ```

2. **Verify base image availability**:
   ```bash
   docker pull ghcr.io/catthehacker/ubuntu:act-latest
   ```

3. **Check Dockerfile syntax**:
   ```bash
   hadolint Dockerfile
   ```

4. **Review build logs**:
   - Look for network errors
   - Check package availability
   - Verify URL endpoints

### Container Won't Start

**If `./runner.sh start` fails:**

1. **Check Docker daemon**:
   ```bash
   docker ps
   docker info
   ```

2. **Review logs**:
   ```bash
   docker logs axyzlabs-runner
   ```

3. **Verify resources**:
   ```bash
   docker stats --no-stream
   df -h
   ```

4. **Check volume mounts**:
   ```bash
   ls -la ~/.claude/agents
   ```

### Tests Fail

**If `./test-runner.sh` fails:**

1. **Run tests individually**:
   ```bash
   ./runner.sh shell
   # Inside container, test each tool
   claude --version
   go version
   act --version
   ```

2. **Check file permissions**:
   ```bash
   ls -la /home/claude
   ls -la /home/claude/.claude
   ```

3. **Verify PATH**:
   ```bash
   echo $PATH
   which claude go act
   ```

4. **Check workspace mount**:
   ```bash
   ls -la /workspace
   mount | grep workspace
   ```

## Security Considerations

### Running as Non-Root

**The container runs as `claude` user (UID 1001).**

**When adding functionality:**
- Don't require root access
- Use proper file permissions
- Test as non-root user
- Document any sudo requirements

**File ownership:**
```dockerfile
# In Dockerfile:
COPY --chown=claude:claude file /home/claude/
RUN chown -R claude:claude /home/claude/.claude
```

### Secret Management

**Secrets should NEVER be in the image.**

**Proper secret handling:**
1. Mount secrets as files: `-v ~/.secrets:/home/claude/.secrets:ro`
2. Pass as environment variables: `-e SECRET_KEY`
3. Use Docker secrets: `docker secret create`

**In scripts:**
```bash
# Check for secret file
if [ -f ~/.secrets ]; then
    source ~/.secrets
else
    echo -e "${YELLOW}Warning: ~/.secrets not found${NC}"
fi
```

### Dependency Security

**When adding dependencies:**

1. **Verify source**: Only use official/trusted sources
2. **Pin versions**: Never use `latest` or floating versions
3. **Check vulnerabilities**: Run security scanners
4. **Verify checksums**: When downloading binaries

**Example:**
```dockerfile
# Good - pinned version with checksum
RUN wget -O tool.tar.gz \
    https://github.com/owner/tool/releases/download/v1.2.3/tool_linux_amd64.tar.gz && \
    echo "abc123... tool.tar.gz" | sha256sum -c - && \
    tar xzf tool.tar.gz && \
    mv tool /usr/local/bin/
```

## Best Practices

### Docker Best Practices

1. **Minimize layers**: Combine related commands
2. **Leverage caching**: Order commands from least to most changing
3. **Clean up in same layer**: Remove cache in same RUN command
4. **Use .dockerignore**: Exclude unnecessary files
5. **Multi-stage builds**: Separate build and runtime
6. **Health checks**: Define container health
7. **Labels**: Add metadata for tracking

### Shell Script Best Practices

1. **Strict mode**: `set -euo pipefail`
2. **Quoting**: Quote all variables: `"${VAR}"`
3. **Input validation**: Check arguments before use
4. **Error messages**: Provide context and solutions
5. **Idempotency**: Safe to run multiple times
6. **Logging**: Use color coding for clarity
7. **Exit codes**: Return appropriate codes

### Documentation Best Practices

1. **User-first**: Write for the user, not yourself
2. **Examples**: Provide practical, working examples
3. **Troubleshooting**: Anticipate common issues
4. **Versioning**: Document version compatibility
5. **Updates**: Keep docs in sync with code
6. **Structure**: Use clear headings and formatting
7. **Completeness**: Cover setup, usage, and troubleshooting

## Commit Message Standards

Follow conventional commit format:

```
type(scope): description

Longer description if needed.

- Bullet points for changes
- More details

Breaking changes:
- Document breaking changes clearly
```

**Types:**
- `feat`: New feature (e.g., new tool, new capability)
- `fix`: Bug fix (e.g., script error, permission issue)
- `docs`: Documentation only
- `chore`: Maintenance (e.g., version bump, cleanup)
- `refactor`: Code refactoring
- `test`: Test additions or modifications
- `security`: Security improvements
- `perf`: Performance improvements

**Scopes:**
- `docker`: Dockerfile changes
- `scripts`: Shell script changes
- `compose`: Docker Compose changes
- `docs`: Documentation changes
- `ci`: CI/CD changes

**Examples:**
```
feat(docker): add jq tool for JSON processing

fix(scripts): handle spaces in directory paths correctly

docs(readme): add troubleshooting section for build failures

security(docker): update base image to patch CVE-2024-1234
```

## Getting Help

### Before Asking for Help

1. **Read the documentation**:
   - This CLAUDE.md
   - README.md
   - SETUP_GUIDE.md
   - DOCKER_SETUP_SUMMARY.md

2. **Check logs**:
   - Build logs: `./build.sh` output
   - Container logs: `./runner.sh logs`
   - Docker logs: `docker logs axyzlabs-runner`

3. **Run tests**:
   - Test suite: `./test-runner.sh`
   - Individual tool tests in container

4. **Search for similar issues**:
   - GitHub Issues
   - Docker documentation
   - Tool-specific documentation

### When Reporting Issues

**Include:**
- Operating system and version
- Docker version: `docker --version`
- Error messages (full output)
- Steps to reproduce
- Expected vs actual behavior
- Relevant log excerpts

## Summary

**Before making any changes:**

1. ✅ Read relevant documentation
2. ✅ Understand security implications
3. ✅ Consider backward compatibility
4. ✅ Plan the change

**When making changes:**

5. ✅ Follow coding standards
6. ✅ Validate inputs
7. ✅ Handle errors gracefully
8. ✅ Add inline comments

**Before committing:**

9. ✅ Build successfully: `./build.sh`
10. ✅ Tests pass: `./test-runner.sh`
11. ✅ Container works: `./runner.sh start && ./runner.sh shell`
12. ✅ Documentation updated
13. ✅ Security checked
14. ✅ Conventional commit message

**Remember**: This container is used by others. Prioritize security, reliability, and backward compatibility. When in doubt, ask before making breaking changes.

---

**Questions?** Check the documentation or open an issue on GitHub.
