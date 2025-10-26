# GitHub Actions Runner Image - Specification

**Version:** 1.0.0
**Status:** Draft
**Created:** 2025-10-26
**Last Updated:** 2025-10-26

## Quick Navigation

| Section | Description | Owner | Status |
|---------|-------------|-------|--------|
| [01-overview.md](01-overview.md) | Purpose, scope, and related specs | spec-writer | Draft |
| [02-architecture.md](02-architecture.md) | System design and components | devops-engineer | Draft |
| [03-data-models.md](03-data-models.md) | Configuration schemas | devops-engineer | Draft |
| [04-api-design.md](04-api-design.md) | CLI interfaces and scripts | devops-engineer | Draft |
| [05-implementation.md](05-implementation.md) | Implementation tasks | devops-engineer | Draft |
| [06-testing.md](06-testing.md) | Testing requirements | devops-engineer | Draft |
| [07-security.md](07-security.md) | Security considerations | security-engineer | Draft |
| [08-deployment.md](08-deployment.md) | Deployment and operations | devops-engineer | Draft |
| [09-appendix.md](09-appendix.md) | References and best practices | spec-writer | Draft |

## Executive Summary

This specification defines a production-ready GitHub Actions self-hosted runner Docker image that provides a comprehensive DevOps and Cloud Engineering platform integrated with Claude Code. The image serves as a reusable foundation for any project using GitHub Actions, featuring pre-configured MCP servers, skills, agents, and essential DevOps tooling.

### Key Features

- **Self-Hosted Runner**: Optimized Docker container for GitHub Actions workflows
- **Claude Code Integration**: Full support for MCP servers, skills, agents, and custom commands
- **DevOps Tooling**: Comprehensive suite of cloud and infrastructure tools
- **Security Hardened**: Non-root execution, vulnerability scanning, secret management
- **Observability**: OpenTelemetry metrics exposed to configurable OTEL endpoints
- **Project Agnostic**: User-level configuration independent of specific projects

### Design Principles

1. **Security First**: Non-root execution, minimal privileges, comprehensive scanning
2. **Performance Optimized**: Selective MCP server loading, efficient caching, resource limits
3. **Developer Friendly**: Pre-configured workflows, extensive documentation, easy troubleshooting
4. **Production Ready**: Health checks, metrics, logging, graceful shutdown
5. **Extensible**: Plugin architecture for skills, agents, and MCP servers

## Reading Guide

### For Project Managers
- Start with [01-overview.md](01-overview.md) for project scope and goals
- Review [05-implementation.md](05-implementation.md) for timeline and dependencies
- Check [08-deployment.md](08-deployment.md) for operational requirements

### For Architects
- Begin with [02-architecture.md](02-architecture.md) for system design
- Study [03-data-models.md](03-data-models.md) for configuration structure
- Review [07-security.md](07-security.md) for security architecture

### For Engineers
- Focus on [04-api-design.md](04-api-design.md) for CLI interfaces
- Refer to [05-implementation.md](05-implementation.md) for detailed tasks
- Use [09-appendix.md](09-appendix.md) for technical references

### For QA/Testing
- Start with [06-testing.md](06-testing.md) for testing strategy
- Reference [05-implementation.md](05-implementation.md) for acceptance criteria
- Check [08-deployment.md](08-deployment.md) for integration test environments

### For Security Team
- Review [07-security.md](07-security.md) comprehensively
- Check [02-architecture.md](02-architecture.md) for threat model
- Validate [08-deployment.md](08-deployment.md) for deployment security

## Parallel Development Strategy

This specification is designed for parallel development across multiple teams/agents:

### Phase 1: Foundation (Parallel)
- **Team A**: Docker image optimization ([02-architecture.md](02-architecture.md) sections 2.1-2.3)
- **Team B**: Configuration schema design ([03-data-models.md](03-data-models.md))
- **Team C**: Security hardening ([07-security.md](07-security.md) sections 7.1-7.3)

### Phase 2: Integration (Parallel)
- **Team A**: MCP server integration ([02-architecture.md](02-architecture.md) section 2.4)
- **Team B**: CLI scripts development ([04-api-design.md](04-api-design.md))
- **Team C**: Observability implementation ([02-architecture.md](02-architecture.md) section 2.5)

### Phase 3: Testing (Sequential)
- Unit tests ([06-testing.md](06-testing.md) section 6.2)
- Integration tests ([06-testing.md](06-testing.md) section 6.3)
- Security tests ([06-testing.md](06-testing.md) section 6.4)

### Phase 4: Documentation (Parallel with Phase 3)
- User documentation ([08-deployment.md](08-deployment.md))
- API documentation ([04-api-design.md](04-api-design.md))
- Troubleshooting guides ([09-appendix.md](09-appendix.md))

## Dependencies Between Sections

### Critical Path
```
01-overview → 02-architecture → 05-implementation → 06-testing → 08-deployment
```

### Parallel Tracks
```
Track A: 02-architecture → 04-api-design → 05-implementation
Track B: 03-data-models → 04-api-design → 06-testing
Track C: 07-security → 06-testing → 08-deployment
```

### Integration Points

1. **Architecture ↔ Data Models**
   - Component structure defines configuration schema
   - Configuration validation impacts architecture

2. **API Design ↔ Implementation**
   - CLI interface defines implementation tasks
   - Script behavior informs API design refinement

3. **Security ↔ Testing**
   - Security requirements drive security test cases
   - Test results inform security hardening

4. **Architecture ↔ Deployment**
   - System design impacts deployment topology
   - Operational requirements influence architecture

## Acceptance Criteria Summary

### Must Have (MVP)
- ✅ Docker image builds successfully
- ✅ Runner connects to GitHub Actions
- ✅ Non-root execution (UID 1001)
- ✅ Essential tools installed (npm, yq, jq)
- ✅ Claude Code CLI functional
- ✅ At least 2 MCP servers configured (AWS docs, Terraform)
- ✅ Basic metrics exposed
- ✅ Security scanning passes
- ✅ All tests pass (≥80% coverage)

### Should Have (v1.0)
- ✅ All documented MCP servers operational
- ✅ Skills for each MCP server
- ✅ Custom checkpoint system
- ✅ OpenTelemetry integration
- ✅ Comprehensive documentation
- ✅ Multi-architecture support (amd64, arm64)
- ✅ Automated vulnerability scanning

### Could Have (Future)
- ⏳ Ephemeral runner pattern
- ⏳ Advanced monitoring dashboards
- ⏳ Custom metrics exporters
- ⏳ Additional cloud provider MCP servers
- ⏳ AI-powered troubleshooting

## GitHub Tracking

**GitHub Issue**: [#1](https://github.com/axyzlabs/runner/issues/1)
**Feature Branch**: `feature/gha-runner-image`
**Status**: In Progress
**Created**: 2025-10-26

### Implementation Issues

**Phase 2: Claude Integration** (32 hours)
- [#2](https://github.com/axyzlabs/runner/issues/2) - Claude Code CLI, MCP servers, skills, checkpoint system

**Phase 3: DevOps Tools** (24 hours)
- [#3](https://github.com/axyzlabs/runner/issues/3) - AWS CLI, Terraform, kubectl, Helm, Docker Compose

**Phase 4: Observability** (32 hours)
- [#4](https://github.com/axyzlabs/runner/issues/4) - OpenTelemetry, Prometheus, logging, health checks

**Phase 5: Security Hardening** (24 hours) ⚠️ **CRITICAL**
- [#5](https://github.com/axyzlabs/runner/issues/5) - Remove sudo, PID limits, Trivy scanning, secret management

**Phase 6: Documentation** (48 hours)
- [#6](https://github.com/axyzlabs/runner/issues/6) - User guides, API reference, troubleshooting

### Implementation Strategy

**Sequential Phases**:
1. Phase 2 (Claude Integration) - Start immediately ✅
2. Phase 3 (DevOps Tools) - After Phase 2
3. Phase 4 (Observability) - After Phase 3
4. Phase 5 (Security Hardening) - After Phase 4 ⚠️ **Must complete before production**
5. Phase 6 (Documentation) - Can run in parallel, complete before release

**Total Remaining Effort**: 160 hours (Phase 1 already complete)

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-10-26 | spec-writer | Initial specification created |
| 1.0.1 | 2025-10-26 | spec-writer | Added GitHub tracking information |

## Related Specifications

- [Git Template Configuration](../../../git-template/README.md) - Reference for workflow patterns
- [User Claude Config](~/.claude/README.md) - Checkpoint system and global config patterns

## Feedback and Questions

For questions or clarifications about this specification:
1. Review the relevant section in detail
2. Check [09-appendix.md](09-appendix.md) for additional context
3. Open a discussion in the project repository
4. Tag the section owner for specific technical questions

---

**Next Steps:**
1. Begin Phase 2 implementation: [#2](https://github.com/axyzlabs/runner/issues/2)
2. Address critical security fixes in Phase 5: [#5](https://github.com/axyzlabs/runner/issues/5)
3. Follow TDD workflow for each task
4. Run comprehensive testing before release
