# GitHub Actions Runner with Claude Code

A production-ready, reusable Docker container for running GitHub Actions workflows locally with Claude Code integration, comprehensive development tools, and agent/skill support.

## Features

- **Claude Code CLI**: Full integration with agents, skills, and MCP servers
- **GitHub Actions**: Run workflows locally with [nektos/act](https://github.com/nektos/act)
- **Development Tools**: Go 1.25.0, Python 3.11, Node.js 20, comprehensive tooling
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

### Workflow Tools

- **act**: Run GitHub Actions workflows locally
- **actionlint**: Validate workflow syntax
- **yq**: YAML processing
- **jq**: JSON processing

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

## Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [DOCKER_SETUP_SUMMARY.md](DOCKER_SETUP_SUMMARY.md) - Technical summary

## Requirements

- **Docker**: 20.10+ with BuildKit support
- **Disk Space**: ~5GB for image and layers
- **Memory**: 4GB minimum, 8GB recommended

## License

MIT License - see [LICENSE](LICENSE) file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/axyzlabs/runner/issues)
- **Documentation**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions

---

**Made with ❤️ by axyzlabs**
