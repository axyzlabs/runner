# GitHub Actions Runner with Claude Code

A production-ready, reusable Docker container for running GitHub Actions workflows locally with Claude Code integration, comprehensive development tools, DevOps tooling, and agent/skill support.

## Features

- **Claude Code CLI**: Full integration with agents, skills, and MCP servers
- **GitHub Actions**: Run workflows locally with [nektos/act](https://github.com/nektos/act)
- **Development Tools**: Go 1.25.0, Python 3.11, Node.js 20, comprehensive tooling
- **DevOps Tools**: AWS CLI, Terraform, Kubernetes (kubectl, Helm, k9s), Docker Compose
- **Security**: Non-root execution, secret management, vulnerability scanning
- **Extensible**: Easy to customize with your own agents, skills, and tools
- **Tested**: Automated test suite with comprehensive validation

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

### DevOps Tools

All DevOps tools are pinned to specific versions for reproducibility:

- **AWS CLI**: 2.15.17 - AWS command line interface
- **Terraform**: 1.7.3 - Infrastructure as Code
- **tflint**: 0.50.3 - Terraform linter
- **kubectl**: 1.29.2 - Kubernetes command-line tool
- **Helm**: 3.14.2 - Kubernetes package manager
- **k9s**: 0.32.4 - Kubernetes terminal UI
- **Docker Compose**: 2.24.6 - Multi-container orchestration
- **yq**: 4.42.1 - YAML processing
- **jq**: 1.7.1 - JSON processing

Run `version-check` inside the container to verify all tool versions.

### Workflow Tools

- **act**: Run GitHub Actions workflows locally
- **actionlint**: Validate workflow syntax

### Claude Code Integration

- **Claude Code CLI**: Installed and configured
- **Agent Support**: Import user-level and project-level agents
- **Skill Support**: Import Claude skills
- **MCP Integration**: Model Context Protocol server support

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

### Using DevOps Tools

Inside the container:

```bash
# AWS CLI
aws s3 ls
aws ec2 describe-instances

# Terraform
terraform init
terraform plan
terraform apply

# Kubernetes
kubectl get pods
helm list
k9s  # Interactive terminal UI

# Docker Compose
docker-compose up -d
docker-compose ps
```

### Checking Tool Versions

```bash
# Inside container, run the version check script
version-check
```

This will display all installed tool versions with color-coded status indicators.

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

### Environment Variables

- `GITHUB_TOKEN`: GitHub personal access token for gh CLI
- `ANTHROPIC_API_KEY`: Anthropic API key for Claude Code
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: AWS credentials
- `KUBECONFIG`: Kubernetes configuration file path

## Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [DOCKER_SETUP_SUMMARY.md](DOCKER_SETUP_SUMMARY.md) - Technical summary
- [CLAUDE.md](CLAUDE.md) - Development instructions for contributors

## Requirements

- **Docker**: 20.10+ with BuildKit support
- **Disk Space**: ~6GB for image and layers
- **Memory**: 4GB minimum, 8GB recommended
- **CPU**: 2+ cores recommended

## Version Compatibility Matrix

| Tool | Version | Compatibility Notes |
|------|---------|---------------------|
| AWS CLI | 2.15.17 | Compatible with all AWS services |
| Terraform | 1.7.3 | HCL 2.0, compatible with AWS/Azure/GCP |
| kubectl | 1.29.2 | Kubernetes 1.28-1.30 |
| Helm | 3.14.2 | Chart API v2 |
| Docker Compose | 2.24.6 | Compose file format 3.8 |

## Upgrading Tools

To upgrade DevOps tools:

1. Update version environment variables in `Dockerfile`
2. Update expected versions in `scripts/version-check.sh`
3. Rebuild the image: `./build.sh`
4. Run tests: `./test-runner.sh`
5. Update this README with new versions

## License

MIT License - see [LICENSE](LICENSE) file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/axyzlabs/runner/issues)
- **Documentation**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions

---

**Made with ❤️ by axyzlabs**
