# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of GitHub Actions Runner with Claude Code
- Multi-stage Docker build with optimized layers
- Go 1.25.0, Python 3.11, Node.js 20 development environments
- Claude Code CLI with full agent and skill support
- nektos/act for local GitHub Actions workflow testing
- actionlint for workflow validation
- Comprehensive Go toolchain (golangci-lint, staticcheck, goimports)
- Non-root execution as `claude` user (UID 1001)
- User-level and project-level agent import system
- MCP (Model Context Protocol) server integration
- Docker Compose orchestration with resource limits
- Automated test suite (test-runner.sh)
- Container management CLI (runner.sh)
- Build helper script (build.sh)
- Health checks and monitoring
- Security hardening (read-only mounts, secret management)
- Comprehensive documentation (README, SETUP_GUIDE, CLAUDE.md)

### Security
- Non-root container execution
- Read-only volume mounts for sensitive directories
- Secret file permissions (600)
- Minimal base image attack surface
- No secrets in image or code

## [1.0.0] - 2025-01-23

### Added
- Initial public release
- Production-ready Docker container for GitHub Actions workflows
- Full Claude Code integration
- Comprehensive tooling for Go, Python, and Node.js development
- Complete documentation and setup guides

[Unreleased]: https://github.com/axyzlabs/runner/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/axyzlabs/runner/releases/tag/v1.0.0
