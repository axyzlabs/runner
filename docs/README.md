# Documentation

Comprehensive documentation for the GitHub Actions Runner with Claude Code integration.

## Getting Started

New to this project? Start here:

1. **[Setup Guide](../SETUP_GUIDE.md)** - Complete installation and setup instructions
2. **[README](../README.md)** - Project overview and quick start
3. **[Docker Setup Summary](../DOCKER_SETUP_SUMMARY.md)** - Technical reference

## Configuration & Usage

### Configuration

- **[Configuration Guide](CONFIGURATION.md)** - Complete reference for all configuration options
  - Environment variables (GITHUB_TOKEN, ANTHROPIC_API_KEY, etc.)
  - Volume mounts and their purposes
  - Resource limits (CPU, memory, disk)
  - Network configuration
  - Security settings
  - Build arguments

### API Reference

- **[API Reference](API_REFERENCE.md)** - Script and command reference
  - build.sh - Build Docker images
  - runner.sh - Container management
  - entrypoint.sh - Container initialization
  - Container utility scripts
  - CLI tools (claude, act, actionlint, gh)

## Troubleshooting & Migration

### Troubleshooting

- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
  - Container won't start
  - Claude CLI not working
  - MCP servers failing
  - GitHub connection issues
  - Permission errors
  - Resource exhaustion
  - Build failures
  - Network problems

### Migration

- **[Migration Guide](MIGRATION.md)** - Migrate from other environments
  - From GitHub-hosted runners
  - From vanilla Docker setups
  - From other self-hosted runners (ARC, Jenkins, GitLab)
  - Version upgrade guides (v0.x → v1.0, v1.0 → v1.1)
  - Migration troubleshooting

## Workflow Documentation

### GitHub Actions Workflows

- **[Workflow README](.github/workflows/README.md)** - CI/CD pipeline documentation
- **[CI/CD Quick Start](.github/CICD_QUICKSTART.md)** - Get started with automated builds
- **[CI/CD Summary](.github/CICD_SUMMARY.md)** - Complete CI/CD documentation

## Architecture & Design

### Technical Specifications

- **[Architecture Overview](specs/gha-runner-image/README.md)** - System design and architecture
  - Component overview
  - Technology stack
  - Security model
  - Integration points

## Quick Links

### Common Tasks

| Task | Documentation |
|------|---------------|
| Install and set up | [Setup Guide](../SETUP_GUIDE.md) |
| Configure environment variables | [Configuration Guide](CONFIGURATION.md#environment-variables) |
| Manage container lifecycle | [API Reference](API_REFERENCE.md#runner-sh) |
| Fix permission errors | [Troubleshooting Guide](TROUBLESHOOTING.md#permission-issues) |
| Migrate from GitHub-hosted | [Migration Guide](MIGRATION.md#from-github-hosted-runners) |
| Add custom tools | [Setup Guide](../SETUP_GUIDE.md#customization) |
| Debug container issues | [Troubleshooting Guide](TROUBLESHOOTING.md#general-diagnostics) |
| Set up MCP servers | [Configuration Guide](CONFIGURATION.md#mcp-server-configuration) |
| Configure resource limits | [Configuration Guide](CONFIGURATION.md#resource-limits) |
| Validate workflows | [API Reference](API_REFERENCE.md#actionlint) |

### Reference Tables

#### Environment Variables

| Variable | Purpose | Documentation |
|----------|---------|---------------|
| GITHUB_TOKEN | GitHub authentication | [Config](CONFIGURATION.md#github_token) |
| ANTHROPIC_API_KEY | Claude API access | [Config](CONFIGURATION.md#anthropic_api_key) |
| GITHUB_REPOSITORY | Target repository | [Config](CONFIGURATION.md#github_repository) |
| RUN_PREFLIGHT | Enable startup checks | [Config](CONFIGURATION.md#run_preflight) |

Full list: [Configuration Guide](CONFIGURATION.md#environment-variables)

#### Management Scripts

| Script | Purpose | Documentation |
|--------|---------|---------------|
| build.sh | Build Docker image | [API](API_REFERENCE.md#buildsh) |
| runner.sh | Container management | [API](API_REFERENCE.md#runnersh) |
| entrypoint.sh | Container initialization | [API](API_REFERENCE.md#entrypointsh) |

Full list: [API Reference](API_REFERENCE.md)

#### CLI Tools

| Tool | Purpose | Documentation |
|------|---------|---------------|
| claude | Claude Code CLI | [API](API_REFERENCE.md#claude) |
| act | Run workflows locally | [API](API_REFERENCE.md#act) |
| actionlint | Validate workflows | [API](API_REFERENCE.md#actionlint) |
| gh | GitHub CLI | [API](API_REFERENCE.md#gh) |

## Documentation Standards

This documentation follows these principles:

- **User-focused** - Written for developers and operators
- **Example-driven** - Practical examples for common tasks
- **Comprehensive** - Covers setup, usage, troubleshooting
- **Cross-referenced** - Links between related topics
- **Up-to-date** - Maintained with each release

## Contributing to Documentation

Found an issue or want to improve the docs?

1. Issues in docs: Open an issue on GitHub
2. Proposed changes: Submit a pull request
3. Questions: Check [Troubleshooting](TROUBLESHOOTING.md) first
4. Suggestions: Use GitHub Discussions

## Documentation Structure

```
docs/
├── README.md                    # This file - documentation index
├── CONFIGURATION.md             # Complete configuration reference
├── API_REFERENCE.md             # Script and CLI reference
├── TROUBLESHOOTING.md           # Problem solving guide
├── MIGRATION.md                 # Migration and upgrade guide
└── specs/                       # Technical specifications
    └── gha-runner-image/
        └── README.md            # Architecture documentation

Parent directory:
├── README.md                    # Project overview and quick start
├── SETUP_GUIDE.md              # Detailed setup instructions
├── DOCKER_SETUP_SUMMARY.md     # Technical Docker reference
├── CLAUDE.md                   # Claude Code development instructions
└── .github/
    ├── workflows/
    │   └── README.md           # Workflow documentation
    ├── CICD_QUICKSTART.md      # CI/CD getting started
    └── CICD_SUMMARY.md         # Complete CI/CD guide
```

## Version Information

- **Current Documentation Version:** 1.0.0
- **Last Updated:** 2025-10-26
- **Covers Image Versions:** v1.0.0 and later

## License

This documentation is part of the GitHub Actions Runner project and is licensed under the MIT License. See [LICENSE](../LICENSE) for details.
