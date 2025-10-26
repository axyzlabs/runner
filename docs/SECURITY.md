# Security Documentation

## Overview

This document outlines the security features, hardening measures, and best practices implemented in the GitHub Actions Runner container.

## Security Principles

### Defense in Depth

Multiple layers of security controls protect against various attack vectors:

1. **Privilege Restriction**: Non-root execution, no sudo access
2. **Resource Isolation**: PID, CPU, and memory limits
3. **Network Isolation**: Inter-container communication disabled
4. **Access Control**: Read-only volume mounts for sensitive data
5. **Vulnerability Management**: Regular scanning with Trivy
6. **Secret Protection**: Automated detection and prevention

### Least Privilege

The container follows the principle of least privilege:

- Runs as non-root user `claude` (UID 1001)
- No sudo or privilege escalation capabilities
- Minimal file permissions (755 for executables, 644 for files)
- Read-only mounts for agent and skill directories
- Restricted capabilities (no CAP_SYS_ADMIN, etc.)

## Implemented Security Controls

### 1. Non-Root Execution (CRITICAL)

**Control**: Container runs as `claude` user (UID 1001)

**Protection Against**:
- Privilege escalation attacks
- Container breakout attempts
- Unauthorized system modifications

**Implementation**:
```dockerfile
RUN useradd -m -s /bin/bash -u 1001 ${CLAUDE_USER}
USER ${CLAUDE_USER}
```

**Verification**:
```bash
docker run --rm zeeke-ai-runner:latest id
# Expected: uid=1001(claude) gid=1001(claude)
```

### 2. No Sudo Access (CRITICAL)

**Control**: Sudo package removed from image

**Protection Against**:
- Privilege escalation (CVSS 8.8)
- Unauthorized root access
- Malicious command execution

**Implementation**:
- Sudo removed from package installation
- No sudoers configuration
- /go directory owned by claude user for Go operations

**Verification**:
```bash
docker run --rm zeeke-ai-runner:latest which sudo
# Expected: (no output - sudo not found)
```

### 3. PID Limits (CRITICAL)

**Control**: Maximum 512 processes per container

**Protection Against**:
- Fork bomb attacks (CVSS 5.3)
- Resource exhaustion
- Denial of service

**Implementation**:
```yaml
services:
  gha-runner:
    pids_limit: 512
```

**Verification**:
```bash
# Fork bomb should fail safely
docker run --rm --pids-limit 512 zeeke-ai-runner:latest bash -c ':(){ :|:& };:'
# Expected: fails with "Resource temporarily unavailable"
```

### 4. Resource Limits

**Control**: CPU and memory limits enforced

**Protection Against**:
- Resource exhaustion attacks
- Runaway processes
- System instability

**Implementation**:
```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```

**Verification**:
```bash
docker stats zeeke-ai-runner --no-stream
# Check CPU and memory usage against limits
```

### 5. Network Isolation

**Control**: Inter-container communication disabled

**Protection Against**:
- Lateral movement between containers
- Container-to-container attacks
- Network reconnaissance

**Implementation**:
```yaml
networks:
  runner-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
```

**Verification**:
```bash
docker network inspect runner-network
# Check: "com.docker.network.bridge.enable_icc": "false"
```

### 6. Vulnerability Scanning

**Control**: Trivy scanner integrated for continuous scanning

**Protection Against**:
- Known CVEs in packages
- Vulnerable dependencies
- Outdated components

**Implementation**:
- Trivy 0.48.3 installed in image
- Automated scanning scripts
- CI/CD integration ready

**Usage**:
```bash
# Scan for HIGH and CRITICAL vulnerabilities
./scripts/security-scan.sh zeeke-ai-runner:latest

# Scan for all severities
trivy image --severity LOW,MEDIUM,HIGH,CRITICAL zeeke-ai-runner:latest
```

### 7. Secret Management

**Control**: Automated secret detection and prevention

**Protection Against**:
- Accidental secret commits
- Credential exposure
- API key leakage

**Implementation**:
- Comprehensive .gitignore patterns
- Secret validation script
- Environment variable usage

**Usage**:
```bash
# Scan repository for secrets
./scripts/validate-secrets.sh

# Expected patterns blocked:
# - API keys (ANTHROPIC_API_KEY, GITHUB_TOKEN, etc.)
# - Private keys (BEGIN RSA PRIVATE KEY, etc.)
# - Passwords (password=, passwd=, etc.)
# - Tokens (bearer, token=, etc.)
```

## Security Testing

### Automated Test Suite

Run comprehensive security tests:

```bash
./scripts/test-security.sh zeeke-ai-runner:latest
```

**Tests Include**:
1. No sudo in image
2. Running as non-root (UID 1001)
3. Running as 'claude' user
4. PID limits (fork bomb protection)
5. Trivy scanner installed
6. Required tools present
7. Go tools work without root
8. File permissions correct
9. No world-writable files
10. Docker socket accessible

### Manual Security Validation

#### Check User Context
```bash
docker run --rm zeeke-ai-runner:latest bash -c "id && whoami"
# Expected: uid=1001(claude) gid=1001(claude)
#           claude
```

#### Verify No Privilege Escalation
```bash
docker run --rm zeeke-ai-runner:latest bash -c "sudo echo test"
# Expected: sudo: not found
```

#### Test PID Limits
```bash
docker run --rm --pids-limit 100 zeeke-ai-runner:latest bash -c '
  for i in {1..200}; do sleep 1 & done
'
# Expected: fails with "fork: retry: Resource temporarily unavailable"
```

#### Check File Permissions
```bash
docker run --rm zeeke-ai-runner:latest bash -c "
  ls -la /home/claude/.claude &&
  ls -la /go
"
# Expected: all owned by claude:claude
```

## Vulnerability Management

### Scanning Schedule

1. **Pre-Build**: Scan base images before use
2. **Post-Build**: Scan built image before deployment
3. **Weekly**: Scheduled scans of production images
4. **On-Demand**: Manual scans when needed

### Severity Levels

| Severity | CVSS Score | Action Required |
|----------|------------|-----------------|
| CRITICAL | 9.0-10.0   | Immediate fix (< 24 hours) |
| HIGH     | 7.0-8.9    | Fix within 7 days |
| MEDIUM   | 4.0-6.9    | Fix within 30 days |
| LOW      | 0.1-3.9    | Fix when convenient |

### Vulnerability Response Process

1. **Detection**: Trivy scan identifies vulnerability
2. **Assessment**: Review CVE details and impact
3. **Prioritization**: Assign severity and timeline
4. **Remediation**: Update package or apply patch
5. **Verification**: Rescan to confirm fix
6. **Documentation**: Update changelog and advisories

## Secret Management Best Practices

### Environment Variables

Use environment variables for secrets:

```bash
docker run -e ANTHROPIC_API_KEY="sk-..." zeeke-ai-runner:latest
```

### Secret Files

Mount secret files read-only:

```bash
docker run -v ~/.secrets:/home/claude/.secrets:ro zeeke-ai-runner:latest
```

### Docker Secrets

Use Docker secrets for production:

```bash
echo "my-secret-value" | docker secret create anthropic_api_key -
docker service create --secret anthropic_api_key zeeke-ai-runner:latest
```

### Never Commit Secrets

The following patterns are automatically blocked:

- `.secrets`, `.secrets.*` (except `.secrets.example`)
- `*.key`, `*.pem`, `*.p12`
- `*_rsa`, `*_dsa`, `*_ecdsa`, `*_ed25519`
- `credentials.json`, `auth.json`, `token.json`
- `*apikey*`, `*api_key*`, `*secret*`, `*password*`

## Network Security

### Isolation Strategy

1. **Bridge Network**: Custom bridge network with ICC disabled
2. **No Host Network**: Never use `--network=host`
3. **Minimal Exposure**: No ports exposed (EXPOSE 0)
4. **Egress Control**: Consider using Docker firewall rules

### Docker Socket Access

The Docker socket is mounted for `act` to work:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

**Risks**:
- Docker socket grants significant privileges
- Can be used to escape container

**Mitigations**:
- Run as non-root user
- No sudo access in container
- Monitor socket usage
- Use rootless Docker when possible

## Compliance and Standards

### CIS Docker Benchmark

This container aligns with CIS Docker Benchmark recommendations:

| Control | Status | Implementation |
|---------|--------|----------------|
| 4.1 - Create user for container | ✓ | UID 1001 (claude) |
| 4.6 - Add HEALTHCHECK | ✓ | Health check configured |
| 5.12 - Mount container root filesystem as read-only | ⚠️ | Workspace needs write access |
| 5.25 - Restrict container from acquiring additional privileges | ✓ | No sudo, no new privileges |
| 5.26 - Check container health at runtime | ✓ | Health check implemented |

### OWASP Docker Security

Follows OWASP Docker Security Cheat Sheet:

- ✓ Use minimal base images
- ✓ Don't run as root
- ✓ Set resource limits
- ✓ Use vulnerability scanning
- ✓ Implement health checks
- ✓ Use read-only volumes when possible
- ✓ Limit capabilities

## Incident Response

### Security Event Detection

Monitor for:
- Failed authentication attempts
- Privilege escalation attempts
- Unusual resource usage
- Network anomalies
- File system modifications

### Response Procedure

1. **Identify**: Detect security event via logs/monitoring
2. **Contain**: Stop affected containers immediately
3. **Analyze**: Review logs and determine root cause
4. **Remediate**: Apply fixes and rebuild image
5. **Recover**: Deploy patched version
6. **Document**: Record incident details and lessons learned

### Contact Information

- **Security Issues**: Report privately to security@axyzlabs.com
- **General Issues**: Use GitHub Issues
- **Emergency**: Contact maintainers directly

## Regular Maintenance

### Security Checklist

Weekly:
- [ ] Run Trivy scan
- [ ] Review logs for anomalies
- [ ] Check for base image updates
- [ ] Review dependency updates

Monthly:
- [ ] Full security audit
- [ ] Review access controls
- [ ] Update security documentation
- [ ] Test incident response procedures

Quarterly:
- [ ] Penetration testing
- [ ] Compliance review
- [ ] Security training updates
- [ ] Third-party security assessment

## References

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [NIST Container Security](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)

## Version History

- **v1.1.0** (2025-10-26): Implemented Phase 5 security hardening
  - Removed sudo access
  - Added PID limits
  - Integrated Trivy scanner
  - Enhanced secret management
  - Configured network isolation
  - Added security test suite

---

**Last Updated**: 2025-10-26
**Review Date**: 2025-11-26
