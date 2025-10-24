# CI/CD Quick Start Guide

This guide will help you get started with the automated Docker build and push workflow for the GitHub Actions Runner container.

## Overview

The workflow automatically:
- Builds multi-architecture Docker images (linux/amd64, linux/arm64)
- Pushes to GitHub Container Registry (GHCR)
- Runs security scans with Trivy
- Tests the images across platforms
- Creates GitHub releases for version tags

## Prerequisites

### 1. Enable GitHub Container Registry

GHCR is enabled by default for public repositories. For private repositories:

1. Go to repository Settings
2. Navigate to "Packages" in the left sidebar
3. Enable "Package creation" if needed

### 2. Set Repository Permissions

The workflow uses the built-in `GITHUB_TOKEN`, which requires:

**Settings → Actions → General → Workflow permissions:**
- Enable "Read and write permissions"
- Enable "Allow GitHub Actions to create and approve pull requests"

## Usage Scenarios

### Scenario 1: Regular Development (Push to Main)

**When to use:** Pushing new features or fixes to the main branch

**Steps:**
```bash
# Make your changes
git checkout main
git add .
git commit -m "feat: add new feature"
git push origin main
```

**What happens:**
1. Workflow triggers automatically
2. Builds image for both architectures
3. Runs security scan (non-blocking)
4. Pushes with tags: `latest` and `main-<sha>`
5. Tests the image on both platforms
6. Results appear in GitHub Actions tab

**Time:** ~15-20 minutes for full build and test

**Access the image:**
```bash
docker pull ghcr.io/axyzlabs/runner:latest
```

---

### Scenario 2: Pull Request Testing

**When to use:** Testing changes before merging to main

**Steps:**
```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
git add .
git commit -m "feat: implement new feature"
git push origin feature/my-feature

# Create PR on GitHub
```

**What happens:**
1. Workflow triggers on PR creation/update
2. Builds image (validates Dockerfile)
3. **Does NOT push to registry**
4. **Does NOT run tests** (no image to test)
5. Shows build status on PR

**Time:** ~8-12 minutes (build only)

**Purpose:** Validate that Docker build succeeds before merge

---

### Scenario 3: Creating a Release

**When to use:** Publishing a new version

**Steps:**

#### Step 1: Decide on Version Number

Follow [Semantic Versioning](https://semver.org/):
- **Patch** (1.0.X): Bug fixes, security patches → `v1.0.1`
- **Minor** (1.X.0): New features, backward compatible → `v1.1.0`
- **Major** (X.0.0): Breaking changes → `v2.0.0`

#### Step 2: Create and Push Tag

```bash
# Ensure you're on main
git checkout main
git pull origin main

# Create annotated tag
git tag -a v1.1.0 -m "Release v1.1.0: Add feature X, fix bug Y"

# Push tag
git push origin v1.1.0
```

**What happens:**
1. Workflow triggers on tag push
2. Builds image for both architectures
3. Runs security scan
4. Pushes with tags: `1.1.0`, `1.1`, `1`, `latest`
5. Tests the image on both platforms
6. **Creates GitHub release** with changelog
7. Generates release notes

**Time:** ~20-25 minutes (full build, test, release)

**Access the image:**
```bash
# Pull specific version
docker pull ghcr.io/axyzlabs/runner:1.1.0
docker pull ghcr.io/axyzlabs/runner:1.1
docker pull ghcr.io/axyzlabs/runner:1

# Pull latest
docker pull ghcr.io/axyzlabs/runner:latest
```

#### Step 3: Verify Release

1. Go to repository on GitHub
2. Click "Releases" in right sidebar
3. Verify new release appears with:
   - Version number
   - Changelog
   - Pull commands
   - Tool versions

---

### Scenario 4: Pre-release (Beta/RC)

**When to use:** Testing a release candidate before stable release

**Steps:**
```bash
# Create pre-release tag
git tag -a v1.1.0-beta.1 -m "Beta release for 1.1.0"
git push origin v1.1.0-beta.1
```

**What happens:**
- Same as regular release
- GitHub release marked as "Pre-release"
- Tags include pre-release identifier: `1.1.0-beta.1`

**Pre-release identifiers:**
- `v1.1.0-alpha.1` - Early testing, unstable
- `v1.1.0-beta.1` - Feature complete, needs testing
- `v1.1.0-rc.1` - Release candidate, final testing

---

### Scenario 5: Manual Workflow Run

**When to use:** Testing or special builds

**Steps:**
1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Build and Push Docker Image" workflow
4. Click "Run workflow" button
5. Select branch to build from
6. Optionally disable push for test builds
7. Click "Run workflow"

**What happens:**
- Builds from selected branch
- Can optionally skip push
- Useful for testing workflow changes

---

## Monitoring Builds

### View Build Progress

1. Go to "Actions" tab on GitHub
2. Click on the running workflow
3. View real-time logs for each job:
   - `build-and-push`: Build and push image
   - `test-image`: Test on amd64 and arm64
   - `create-release`: Create GitHub release (tags only)

### Build Summary

After each build, view the summary:
1. Click on completed workflow run
2. Scroll to "Summary" section
3. View:
   - Build information
   - Generated tags
   - Image digest
   - Pull commands
   - Test results per platform

### Security Scan Results

View Trivy security scan:
1. Go to "Security" tab
2. Click "Code scanning alerts"
3. Filter by "Trivy" tool
4. Review vulnerabilities found

**Note:** Scans don't block builds, they're for monitoring.

---

## Understanding Image Tags

The workflow generates multiple tags for flexibility:

### Main Branch Pushes

| Tag | Example | Description |
|-----|---------|-------------|
| `latest` | `ghcr.io/axyzlabs/runner:latest` | Always points to latest main build |
| `main-<sha>` | `ghcr.io/axyzlabs/runner:main-abc1234` | Specific commit on main |

### Version Tags

| Tag | Example | Description |
|-----|---------|-------------|
| Full version | `ghcr.io/axyzlabs/runner:1.2.3` | Exact version |
| Minor version | `ghcr.io/axyzlabs/runner:1.2` | Latest 1.2.x version |
| Major version | `ghcr.io/axyzlabs/runner:1` | Latest 1.x.x version |
| Latest | `ghcr.io/axyzlabs/runner:latest` | Latest stable release |

### Pull Requests

| Tag | Example | Description |
|-----|---------|-------------|
| `pr-<number>` | `ghcr.io/axyzlabs/runner:pr-42` | Not pushed (build only) |

---

## Common Workflows

### Daily Development Flow

```bash
# Morning: Sync with main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/improve-logging

# Make changes
# ... edit files ...

# Commit and push
git add .
git commit -m "feat: improve logging output"
git push origin feature/improve-logging

# Create PR on GitHub → Build validates

# After PR approved and merged → main gets new build
```

### Release Flow

```bash
# End of sprint: Create release

# 1. Ensure main is stable
git checkout main
git pull origin main

# 2. Update documentation (if needed)
# ... update README.md, CHANGELOG.md ...
git add .
git commit -m "docs: update for v1.2.0 release"
git push origin main

# 3. Create release tag
git tag -a v1.2.0 -m "Release v1.2.0

- Added feature X
- Fixed bug Y
- Improved performance Z"

git push origin v1.2.0

# 4. Wait for workflow to complete (~20-25 min)

# 5. Verify release on GitHub

# 6. Announce release (optional)
```

### Hotfix Flow

```bash
# Critical bug found in production

# 1. Create hotfix branch
git checkout -b hotfix/critical-bug

# 2. Fix the bug
# ... fix bug ...

# 3. Test locally
./build.sh
./test-runner.sh

# 4. Commit and create PR
git add .
git commit -m "fix: resolve critical security issue"
git push origin hotfix/critical-bug

# Create PR → Build validates → Merge to main

# 5. Tag hotfix release immediately
git checkout main
git pull origin main
git tag -a v1.0.1 -m "Hotfix v1.0.1: Security fix"
git push origin v1.0.1

# 6. Wait for workflow and verify
```

---

## Troubleshooting

### Build Fails on Push

**Symptom:** Red X on commit, workflow fails

**Common causes:**
1. Dockerfile syntax error
2. Base image unavailable
3. Network timeout downloading dependencies
4. Out of disk space on runner

**Solution:**
1. Check workflow logs in Actions tab
2. Identify failing step
3. Test locally: `./build.sh`
4. Fix issue and push again

### Security Scan Reports Vulnerabilities

**Symptom:** Security tab shows vulnerabilities

**Understanding:**
- Scans don't block builds (by design)
- Many vulnerabilities are in base image (ubuntu)
- Not all vulnerabilities are exploitable

**Action:**
1. Review vulnerability details
2. Assess risk (is it exploitable in this context?)
3. Update base image if available
4. Update packages in Dockerfile
5. Document accepted risks if needed

### Tests Fail After Successful Build

**Symptom:** Build succeeds but tests fail

**Common causes:**
1. Tool not installed or not in PATH
2. Tool requires permissions
3. ARM64 emulation issues

**Solution:**
1. Check test logs for specific failure
2. Test locally: `./test-runner.sh`
3. Verify tool installation in Dockerfile
4. Check PATH and permissions

### Push Denied to GHCR

**Symptom:** Build succeeds but push fails with 403/401

**Common causes:**
1. Workflow permissions not set correctly
2. Running on forked repository
3. GHCR not enabled

**Solution:**
1. Check Settings → Actions → Workflow permissions
2. Enable "Read and write permissions"
3. For forks: Can't push to upstream GHCR (expected)

### Workflow Doesn't Trigger

**Symptom:** Push to main but no workflow runs

**Common causes:**
1. Workflow file has syntax errors
2. Workflow is disabled
3. Branch name doesn't match

**Solution:**
1. Check Actions tab for disabled workflows
2. Validate workflow syntax: `actionlint .github/workflows/*.yml`
3. Verify branch name matches trigger (`main`)

---

## Performance Tips

### Build Cache

The workflow uses GitHub Actions cache:
- First build: ~15-20 minutes
- Subsequent builds: ~8-12 minutes (with cache)
- Changes to Dockerfile: Cache may miss

**Maximize cache efficiency:**
- Don't change Dockerfile unnecessarily
- Group related commands in single RUN
- Order Dockerfile from least to most changing

### Parallel Jobs

The workflow runs tests in parallel:
- `linux/amd64` and `linux/arm64` test simultaneously
- Saves ~5-10 minutes vs sequential

### Skip Tests (Not Recommended)

If you need fast iteration:
1. Push to PR branch (build only, no tests)
2. Iterate quickly
3. Merge to main when ready (full build + tests)

---

## Advanced Usage

### Custom Branch Builds

Build from specific branch:
```bash
# Workflow automatically handles
git push origin feature/custom-branch

# Manual trigger via Actions UI
# Select branch and run workflow
```

### Multi-Tag Strategy

For complex versioning:
```bash
# Tag with multiple semantics
git tag -a v1.2.3 -m "Release 1.2.3"
git tag -a production-2024-01 -m "Production Jan 2024"
git push origin v1.2.3 production-2024-01
```

### Rollback

If a release has issues:
```bash
# Don't delete the tag, instead:

# 1. Fix the issue
git checkout main
# ... fix ...
git add .
git commit -m "fix: resolve release issue"

# 2. Create new patch version
git tag -a v1.2.4 -m "Hotfix for v1.2.3"
git push origin v1.2.4

# Users can pin to v1.2.4 or previous stable v1.2.2
```

---

## Best Practices

### 1. Test Locally First

Before pushing:
```bash
./build.sh
./test-runner.sh
```

Saves time and CI resources.

### 2. Use Conventional Commits

```bash
feat: add new feature
fix: resolve bug
docs: update documentation
chore: update dependencies
```

Helps generate better changelogs.

### 3. One Feature Per PR

- Smaller PRs = faster reviews
- Easier to validate builds
- Simpler rollback if needed

### 4. Tag from Main Only

```bash
# Always tag from main branch
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release 1.0.0"
```

Ensures tags represent main branch state.

### 5. Semantic Versioning

Follow semver strictly:
- **1.0.0 → 1.0.1**: Patch (bug fixes)
- **1.0.0 → 1.1.0**: Minor (new features)
- **1.0.0 → 2.0.0**: Major (breaking changes)

Users can depend on stable APIs.

### 6. Monitor Security Scans

Regularly check Security tab:
- Address CRITICAL vulnerabilities quickly
- Schedule updates for HIGH vulnerabilities
- Accept or document MEDIUM/LOW if appropriate

---

## Getting Help

### Documentation

- [Workflow README](.github/workflows/README.md) - Detailed workflow documentation
- [Main README](../README.md) - Project overview
- [SETUP_GUIDE](../SETUP_GUIDE.md) - Setup instructions

### Workflow Logs

Access detailed logs:
1. Actions tab → Click workflow run
2. Expand each step to see full output
3. Download logs for offline review (top-right menu)

### Issues

If you encounter problems:
1. Check troubleshooting section above
2. Search [GitHub Issues](https://github.com/axyzlabs/runner/issues)
3. Create new issue with:
   - Workflow run URL
   - Error messages
   - Steps to reproduce
   - Expected behavior

---

## Summary

**For daily development:**
```bash
git push origin main  # Auto-builds and tests
```

**For releases:**
```bash
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0  # Auto-builds, tests, and creates release
```

**For testing:**
```bash
# Create PR → Auto-validates build
```

The workflow handles everything automatically - just push your code or tags!

---

**Questions?** Check the [full workflow documentation](.github/workflows/README.md) or open an issue.
