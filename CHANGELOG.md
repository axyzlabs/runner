# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Trivy vulnerability scanner (v0.48.3) integrated into image
- Automated security test suite (scripts/test-security.sh)
- Vulnerability scanning script (scripts/security-scan.sh)
- Secret validation script (scripts/validate-secrets.sh)
- Comprehensive security documentation (docs/SECURITY.md)
- Network isolation with inter-container communication disabled
- Enhanced .gitignore with security patterns
- Security compliance documentation (CIS, OWASP)

### Security - CRITICAL FIXES
- **CRITICAL**: Removed sudo package and passwordless sudo access (prevents privilege escalation, CVSS 8.8)
- **CRITICAL**: Added PID limits (512 processes) to prevent fork bombs (CVSS 5.3)
- **HIGH**: Configured network isolation with ICC disabled
- **HIGH**: Enhanced secret management with automated detection
- **MEDIUM**: Added resource limits (CPU: 4 cores, Memory: 8GB)
- Fixed /go directory permissions for non-root Go operations

### Changed
- User `claude` no longer has sudo access (security hardening)
- /go directory now owned by `claude` user instead of requiring root
- Network configuration uses dedicated runner-network with isolation
- All security scripts made executable and tested

### Documentation
- Updated README.md with security features section
- Added comprehensive SECURITY.md documentation
- Documented security testing procedures
- Added security compliance information

## [1.0.0] - 2025-01-23

### Added
- Initial public release
- Production-ready Docker container for GitHub Actions workflows
- Full Claude Code integration
- Comprehensive tooling for Go, Python, and Node.js development
- Complete documentation and setup guides
- Multi-stage Docker build with optimized layers
- Go 1.25.0, Python 3.11, Node.js 20 development environments
- Claude Code CLI with full agent and skill support
- nektos/act for local GitHub Actions workflow testing
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

[Unreleased]: https://github.com/axyzlabs/runner/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/axyzlabs/runner/releases/tag/v1.0.0
