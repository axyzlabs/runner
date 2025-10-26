# GitHub Actions Runner with Claude Code

A production-ready, security-hardened Docker container for running GitHub Actions workflows locally with Claude Code integration, comprehensive development tools, and agent/skill support.

## Features

- **Claude Code CLI**: Full integration with agents, skills, and MCP servers
- **GitHub Actions**: Run workflows locally with [nektos/act](https://github.com/nektos/act)
- **Development Tools**: Go 1.25.0, Python 3.11, Node.js 20, comprehensive tooling
- **Security Hardened**: Non-root execution, no sudo, PID limits, vulnerability scanning
- **Trivy Scanner**: Built-in container vulnerability scanning
- **Resource Protected**: CPU/memory/PID limits to prevent resource exhaustion
- **Network Isolated**: Inter-container communication disabled for security
- **Extensible**: Easy to customize with your own agents, skills, and tools
- **Tested**: Automated test suite with comprehensive security validation

## Quick Start

```bash
# Clone this repository
git clone https://github.com/axyzlabs/runner.git
cd runner

# Build the runner image
./build.sh

# Start the runner
./runner.sh start

# Access the container
./runner.sh shell

# Inside the container, test workflows
act -l
act push
```

## What's Included

### Core Tools

- **Go**: 1.25.0 with full toolchain (gofmt, golint, golangci-lint, staticcheck, goimports)
- **Python**: 3.11 with pip, venv
- **Node.js**: 20.x LTS with npm
- **Docker**: For running containers within workflows
- **Git**: Latest version with gh CLI

### Workflow Tools

- **act**: Run GitHub Actions workflows locally
- **yq**: YAML processing
- **jq**: JSON processing

### Security Tools

- **Trivy**: Container vulnerability scanner (v0.48.3)
- **Secret Scanner**: Automated secret pattern detection
- **Security Tests**: Comprehensive security validation suite

### Claude Code Integration

- **Claude Code CLI**: Installed and configured
- **Agent Support**: Import user-level and project-level agents
- **Skill Support**: Import Claude skills
- **MCP Integration**: Model Context Protocol server support

## Security Features

### Hardening Measures

- **Non-Root Execution**: Runs as `claude` user (UID 1001)
- **No Sudo Access**: Sudo removed to prevent privilege escalation
- **PID Limits**: Limited to 512 processes to prevent fork bombs
- **Resource Limits**: CPU (4 cores) and Memory (8GB) limits enforced
- **Network Isolation**: Inter-container communication disabled
- **Read-Only Mounts**: Sensitive volumes mounted read-only
- **Secret Management**: Automated secret detection and validation

### Security Testing

```bash
# Run comprehensive security tests
./scripts/test-security.sh

# Scan for vulnerabilities
./scripts/security-scan.sh zeeke-ai-runner:latest

# Validate no secrets in repository
./scripts/validate-secrets.sh
```

## Usage

### Building the Image

```bash
# Basic build
./build.sh

# Build with custom tag
./build.sh v1.0.0
```

### Managing the Container

```bash
# Start the runner
./runner.sh start

# Stop the runner
./runner.sh stop

# Access shell
./runner.sh shell

# View logs
./runner.sh logs

# Run tests
./runner.sh test
```

### Running Workflows

Inside the container:

```bash
# List all workflows
act -l

# Run push event
act push

# Test specific workflow
act -W .github/workflows/ci.yml

# Dry run
act -n
```

### Security Scanning

```bash
# Scan image for vulnerabilities
docker run --rm zeeke-ai-runner:latest trivy image zeeke-ai-runner:latest

# Or use the provided script
./scripts/security-scan.sh
```

## Customization

### Adding Your Agents

Place your agents in `~/.claude/agents/` on your host machine. The container will automatically import them.

### Mount Your Project

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.claude:/home/claude/.claude:ro \
  axyzlabs/runner:latest
```

### Secret Management

Create a `.secrets` file for environment-specific secrets:

```bash
# .secrets file (automatically ignored by git)
export ANTHROPIC_API_KEY="your-key-here"
export GITHUB_TOKEN="your-token-here"
```

## Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [DOCKER_SETUP_SUMMARY.md](DOCKER_SETUP_SUMMARY.md) - Technical summary
- [SECURITY.md](docs/SECURITY.md) - Security documentation

## Requirements

- **Docker**: 20.10+ with BuildKit support
- **Disk Space**: ~5GB for image and layers
- **Memory**: 4GB minimum, 8GB recommended
- **CPU**: 2 cores minimum, 4 cores recommended

## Security Compliance

This container follows security best practices:

- **CIS Docker Benchmark**: Aligned with CIS recommendations
- **Non-Root**: No root execution or sudo access
- **Least Privilege**: Minimal permissions and capabilities
- **Resource Limits**: Protection against resource exhaustion
- **Vulnerability Scanning**: Regular Trivy scans
- **Secret Management**: Automated secret detection

## License

MIT License - see [LICENSE](LICENSE) file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/axyzlabs/runner/issues)
- **Documentation**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions
- **Security**: Report security issues privately to security@axyzlabs.com

---

**Made with security in mind by axyzlabs**
