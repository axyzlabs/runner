# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated CI/CD of the runner container.

## Workflows

### docker-build-push.yml

Comprehensive workflow for building, testing, and publishing the Docker image to GitHub Container Registry (GHCR).

#### Features

- **Multi-Architecture Builds**: Supports both `linux/amd64` and `linux/arm64` platforms
- **Smart Tagging**: Automatic semantic versioning with multiple tag strategies
- **Layer Caching**: GitHub Actions cache for faster subsequent builds
- **Security Scanning**: Trivy vulnerability scanning integrated with GitHub Security
- **Comprehensive Testing**: Validates all tools in the container across platforms
- **Automatic Releases**: Creates GitHub releases for version tags
- **Supply Chain Security**: SBOM and provenance attestations included

#### Trigger Conditions

The workflow runs on:

1. **Push to `main` branch**: Builds and pushes with `latest` tag
2. **Version tags** (`v*.*.*`): Builds and pushes with semantic version tags
3. **Pull requests**: Builds only (no push) for validation
4. **Manual dispatch**: Can be triggered manually via GitHub UI

#### Image Tags

The workflow generates multiple tags for flexibility:

| Trigger | Tags Generated | Example |
|---------|----------------|---------|
| Push to main | `latest`, `main-<sha>` | `latest`, `main-abc123` |
| Version tag | `<version>`, `<major>.<minor>`, `<major>`, `latest` | `1.2.3`, `1.2`, `1`, `latest` |
| Pull request | `pr-<number>` | `pr-42` |

#### Jobs

##### 1. build-and-push

Builds the Docker image with multi-architecture support and pushes to GHCR.

**Steps:**
1. Checkout repository
2. Set up QEMU for ARM64 builds
3. Set up Docker Buildx
4. Extract metadata (tags, labels)
5. Login to GHCR
6. Build and push image
7. Run Trivy security scan
8. Upload security results
9. Generate build summary

**Permissions:**
- `contents: read` - Read repository
- `packages: write` - Push to GHCR
- `id-token: write` - Sign images
- `security-events: write` - Upload security scan results

##### 2. test-image

Tests the built image across all supported platforms.

**Tests Performed:**
- Container startup test
- Claude CLI verification
- Go toolchain test
- Python environment test
- Node.js environment test
- act installation test
- actionlint installation test
- gh CLI test
- Go tools test (golangci-lint, etc.)

**Matrix Strategy:**
- Runs tests for both `linux/amd64` and `linux/arm64`
- Uses QEMU for ARM64 emulation on AMD64 runners

##### 3. create-release

Creates a GitHub release for version tags.

**Release Includes:**
- Pull commands for the image
- Changelog since previous tag
- List of supported platforms
- Tool versions included
- Auto-generated release notes

**Triggered only when:**
- A version tag (`v*.*.*`) is pushed
- Both build and test jobs succeed

## Using the Workflow

### Pushing to Main

```bash
git checkout main
git add .
git commit -m "feat: add new feature"
git push origin main
```

**Result:**
- Builds image for both architectures
- Pushes with `latest` and `main-<sha>` tags
- Runs security scan
- Tests the image

### Creating a Release

```bash
# Tag the release
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

**Result:**
- Builds image for both architectures
- Pushes with tags: `1.2.3`, `1.2`, `1`, `latest`
- Runs security scan
- Tests the image
- Creates GitHub release with changelog

### Testing Pull Requests

```bash
git checkout -b feature/my-feature
git add .
git commit -m "feat: implement new feature"
git push origin feature/my-feature
# Create PR on GitHub
```

**Result:**
- Builds image (no push)
- Validates build succeeds
- No tests run (image not pushed)

### Manual Workflow Run

1. Go to GitHub Actions tab
2. Select "Build and Push Docker Image" workflow
3. Click "Run workflow"
4. Select branch
5. Optionally disable push

**Result:**
- Builds image with selected options
- Can be used for testing or special builds

## Environment Variables

The workflow uses these environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `REGISTRY` | Container registry URL | `ghcr.io` |
| `IMAGE_NAME` | Full image name | `axyzlabs/runner` |

## Secrets Required

| Secret | Description | Source |
|--------|-------------|--------|
| `GITHUB_TOKEN` | GitHub authentication | Auto-provided by GitHub |

**No additional secrets required!** The workflow uses the built-in `GITHUB_TOKEN` which is automatically provided by GitHub Actions.

## Permissions

The workflow requires these repository permissions:

- **Read access to contents**: Clone the repository
- **Write access to packages**: Push images to GHCR
- **Write access to security events**: Upload Trivy scan results

These are configured via the `permissions:` key in each job.

## Caching Strategy

The workflow uses GitHub Actions cache to speed up builds:

- **Cache type**: `gha` (GitHub Actions cache)
- **Cache mode**: `max` (cache all layers)
- **Cache key**: Automatically managed by Docker Buildx
- **Benefits**:
  - Faster builds (up to 90% faster for unchanged layers)
  - Reduced bandwidth usage
  - Lower build costs

## Security Features

### 1. Vulnerability Scanning

- **Tool**: Trivy by Aqua Security
- **Scope**: CRITICAL and HIGH severity vulnerabilities
- **Output**: SARIF format uploaded to GitHub Security tab
- **Policy**: Non-blocking (exit code 0) to allow monitoring without blocking releases

### 2. Supply Chain Security

- **Provenance**: Enabled for all builds
- **SBOM**: Software Bill of Materials generated
- **Signing**: Image attestations signed with OIDC token

### 3. Secret Protection

- **No hardcoded secrets**: All authentication via `GITHUB_TOKEN`
- **Read-only base images**: Pull from trusted registries
- **Non-root execution**: Container runs as `claude` user (UID 1001)

## Troubleshooting

### Build Fails on ARM64

**Symptom**: Build succeeds on amd64 but fails on arm64

**Solution:**
1. Check if all dependencies support ARM64
2. Verify base image has ARM64 variant
3. Test locally with: `docker buildx build --platform linux/arm64 .`

### Cache Not Working

**Symptom**: Builds are slow, not using cache

**Solution:**
1. Verify GitHub Actions cache is enabled
2. Check cache storage limits (10GB per repository)
3. Review build logs for cache hits/misses
4. Force cache refresh by changing Dockerfile

### Security Scan Failing

**Symptom**: Trivy scan reports vulnerabilities

**Solution:**
1. Review vulnerabilities in GitHub Security tab
2. Update base image to latest version
3. Update package versions in Dockerfile
4. Consider accepting risk for base image vulnerabilities

### Tests Failing

**Symptom**: Image builds but tests fail

**Solution:**
1. Check which test failed in the logs
2. Verify tool is installed in Dockerfile
3. Check PATH environment variable
4. Test locally: `./test-runner.sh`

### Push Denied

**Symptom**: Build succeeds but push fails with permission denied

**Solution:**
1. Verify `packages: write` permission is set
2. Check repository settings allow GHCR
3. Ensure workflow is running from main or tag
4. Verify not running on fork (forks can't push to upstream GHCR)

## Best Practices

### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/):

- **Major** (`v2.0.0`): Breaking changes, major updates
- **Minor** (`v1.1.0`): New features, backward compatible
- **Patch** (`v1.0.1`): Bug fixes, security patches

### Pre-release Tags

Use pre-release identifiers for testing:

- **Alpha**: `v1.0.0-alpha.1` - Early testing
- **Beta**: `v1.0.0-beta.1` - Feature complete, needs testing
- **RC**: `v1.0.0-rc.1` - Release candidate

The workflow automatically marks these as pre-releases.

### Branch Protection

Recommended branch protection rules for `main`:

- Require pull request reviews
- Require status checks to pass
- Require conversation resolution
- Include administrators
- Require linear history

### Testing Strategy

1. **Local testing**: Use `./build.sh` and `./test-runner.sh` before pushing
2. **PR testing**: Create PR to validate build before merging
3. **Pre-release**: Tag with `-beta` or `-rc` for validation
4. **Release**: Tag with stable version only after validation

## Monitoring

### Build Status

Monitor build status via:

- **GitHub Actions tab**: Real-time build logs
- **Commit status checks**: Green checkmark on commits
- **Email notifications**: Configure in GitHub settings
- **Status badges**: Add to README.md

### Security Alerts

Monitor security via:

- **Security tab**: View Trivy scan results
- **Dependabot**: Enable for automated dependency updates
- **Code scanning**: Review vulnerability trends

### Image Metrics

Monitor usage via:

- **GHCR package page**: View pull statistics
- **Image size**: Track size changes over versions
- **Build time**: Monitor build duration trends

## Extending the Workflow

### Adding New Tests

Edit the `test-image` job in `docker-build-push.yml`:

```yaml
# Add new test
echo "Test 10: Testing new tool..."
docker run --platform=${{ matrix.platform }} --rm ${IMAGE} new-tool --version
```

### Adding New Platforms

Add to the platforms list:

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

**Note**: Ensure all dependencies support the new platform.

### Custom Tags

Add custom tag patterns to the metadata step:

```yaml
tags: |
  type=raw,value=custom-tag
  # ... existing tags
```

### Additional Scanners

Add more security scanners:

```yaml
- name: Run additional scanner
  uses: scanner/action@v1
  with:
    image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

## Support

For issues or questions:

1. Check this documentation
2. Review workflow logs in GitHub Actions
3. Search [GitHub Issues](https://github.com/axyzlabs/runner/issues)
4. Create new issue with:
   - Workflow run URL
   - Error messages
   - Steps to reproduce
