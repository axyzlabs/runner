# API Reference

Complete reference for all scripts, commands, and utilities provided by the GitHub Actions Runner image.

## Table of Contents

- [Management Scripts](#management-scripts)
- [Container Scripts](#container-scripts)
- [Utility Scripts](#utility-scripts)
- [CLI Tools](#cli-tools)
- [Docker Compose Reference](#docker-compose-reference)

## Management Scripts

### build.sh

Build the Docker image with optional configuration.

#### Synopsis

```bash
./build.sh [TAG] [BUILD_ARGS]
```

#### Description

Builds the GitHub Actions Runner Docker image with validation checks and proper configuration. Supports custom tags and build arguments for flexibility.

#### Arguments

| Argument | Description | Default | Required |
|----------|-------------|---------|----------|
| TAG | Image tag to apply | `latest` | No |
| BUILD_ARGS | Additional build arguments | None | No |

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| IMAGE_NAME | Docker image name | `axyzlabs/runner` |

#### Examples

**Basic Build:**
```bash
./build.sh
```

**Build with Custom Tag:**
```bash
./build.sh v1.0.0
```

**Build with Custom Image Name:**
```bash
IMAGE_NAME=myorg/runner ./build.sh v1.0.0
```

**Build with Build Arguments:**
```bash
./build.sh latest "--build-arg GO_VERSION=1.26.0"
```

**Build with Multiple Arguments:**
```bash
./build.sh v1.0.0 "--build-arg GO_VERSION=1.26.0 --build-arg NODE_VERSION=21"
```

#### Build Process

The script performs these steps:

1. **Prerequisites Check** - Verifies Docker is installed and Dockerfile exists
2. **Agent Verification** - Checks for user-level agents at `~/.claude/agents`
3. **Entrypoint Validation** - Ensures entrypoint.sh exists and is executable
4. **Base Image Pull** - Pulls latest base image (with fallback to cache)
5. **Image Build** - Builds image with BuildKit enabled

#### Exit Codes

| Code | Description |
|------|-------------|
| 0 | Build successful |
| 1 | Build failed or prerequisites missing |

#### Output

**Success:**
```
========================================
Building GitHub Actions Runner Image
========================================
[1/5] Checking prerequisites...
✓ Prerequisites OK
[2/5] Verifying user-level agents...
✓ Found 15 user-level agent files
[3/5] Verifying entrypoint script...
✓ entrypoint.sh found and made executable
[4/5] Pulling base image...
[5/5] Building Docker image...
========================================
✓ Build successful!
========================================
Image: axyzlabs/runner:latest

Next steps:
  1. Test the image:
     docker run -it --rm axyzlabs/runner:latest
```

**Failure:**
```
========================================
✗ Build failed!
========================================
```

#### Notes

- Automatically enables Docker BuildKit for better caching
- Makes entrypoint.sh executable during build
- Warns if user-level agents are missing
- Uses plain progress output for better CI/CD compatibility

---

### runner.sh

Manage the GitHub Actions Runner container lifecycle.

#### Synopsis

```bash
./runner.sh <command> [options]
```

#### Description

Comprehensive container management script providing start, stop, shell access, testing, and maintenance operations.

#### Commands

| Command | Description |
|---------|-------------|
| `start` | Start the runner container |
| `stop` | Stop the runner container |
| `restart` | Restart the runner container |
| `shell` | Open interactive shell in container |
| `logs` | View container logs |
| `build` | Build the runner image |
| `test` | Test workflows with act |
| `status` | Show container status |
| `clean` | Stop and remove container |
| `purge` | Remove container and volumes |
| `rebuild` | Clean, build, and start |
| `validate` | Validate GitHub workflows |
| `help` | Show usage information |

#### Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| COMPOSE_FILE | Docker Compose file path | `docker-compose.runner.yml` |
| SERVICE_NAME | Service name in compose file | `gha-runner` |
| IMAGE_NAME | Docker image name | `zeeke-ai-runner` |

#### Examples

**Start Container:**
```bash
./runner.sh start
```
Output:
```
[INFO] Starting runner container...
[INFO] Runner started successfully
[INFO] Access with: ./runner.sh shell
```

**Access Container Shell:**
```bash
./runner.sh shell
```
Opens interactive bash shell inside the running container.

**View Logs:**
```bash
# Tail logs
./runner.sh logs

# Follow logs (live)
./runner.sh logs -f
```

**Test Workflow:**
```bash
# List available workflows
./runner.sh test

# Test specific workflow (dry run)
./runner.sh test ci.yml
```

**Check Status:**
```bash
./runner.sh status
```
Output:
```
[INFO] Container status:
NAME              STATUS    PORTS
zeeke-ai-runner   Up

[INFO] Image information:
REPOSITORY        TAG       IMAGE ID      CREATED        SIZE
zeeke-ai-runner   latest    abc123def     2 hours ago    2.5GB
```

**Clean Up:**
```bash
# Stop and remove container (keep volumes)
./runner.sh clean

# Remove everything including volumes
./runner.sh purge
```

**Full Rebuild:**
```bash
./runner.sh rebuild
```
Performs: stop, remove, build, start

**Validate Workflows:**
```bash
./runner.sh validate
```
Runs actionlint on all workflow files.

#### Exit Codes

| Code | Description |
|------|-------------|
| 0 | Command successful |
| 1 | Command failed or prerequisites missing |

#### Prerequisites Check

The script verifies:
- Docker is installed and accessible
- Docker Compose is available
- Compose file exists at configured path

#### Notes

- Requires `.secrets` file for full functionality (warns if missing)
- Color-coded output for better readability
- Safe to run multiple times (idempotent operations)
- Prompts for confirmation on destructive operations (purge)

---

### entrypoint.sh

Container entrypoint that initializes the environment and starts the requested command.

#### Synopsis

```bash
/entrypoint.sh [command] [args...]
```

#### Description

Executed automatically when container starts. Performs environment setup, tool verification, and configuration before running the specified command or starting an interactive shell.

#### Environment Setup

The entrypoint performs these tasks:

1. **Tool Verification** - Checks that required tools are installed
2. **Workspace Setup** - Creates and configures workspace directory
3. **Git Configuration** - Sets up git user name and email
4. **MCP Configuration** - Configures MCP servers if available
5. **Go Setup** - Downloads Go modules if go.mod exists
6. **Authentication** - Configures GitHub CLI and Anthropic API
7. **Agent Loading** - Loads Claude Code agents
8. **Preflight Checks** - Runs validation checks (if enabled)
9. **Command Execution** - Runs specified command or shell

#### Verified Tools

The script checks for:
- **Claude Code** (required) - Exits if not found
- **Go** (required) - Exits if not found
- **Python** (required) - Exits if not found
- **Node.js** (optional) - Warns if not found
- **act** (optional) - Warns if not found
- **actionlint** (optional) - Warns if not found

#### Environment Variables Used

| Variable | Purpose | Required |
|----------|---------|----------|
| WORKSPACE | Workspace directory path | No |
| GIT_USER_NAME | Git commit author name | No |
| GIT_USER_EMAIL | Git commit author email | No |
| GITHUB_TOKEN | GitHub authentication | No |
| ANTHROPIC_API_KEY | Claude API key | No |
| SKILL_SEEKERS_PATH | MCP server path | No |
| RUN_PREFLIGHT | Enable preflight checks | No |
| CLAUDE_HOME | Claude home directory | No |

#### Preflight Checks

When `RUN_PREFLIGHT=true` (default):

**Go Code Validation:**
- Checks if Go files are properly formatted with `gofmt`
- Runs only if `go.mod` exists

**Workflow Validation:**
- Validates GitHub workflow syntax with `actionlint`
- Runs only if `.github/workflows/` exists

#### Output

**Successful Startup:**
```
========================================
GitHub Actions Runner with Claude Code
========================================
[INFO] Verifying tool installations...
[INFO] Claude Code: 1.2.3
[INFO] Go: go1.25.0 linux/amd64
[INFO] Python: Python 3.11.6
[INFO] Node.js: v20.10.0
[INFO] act: 0.2.55
[INFO] actionlint: 1.6.26
[INFO] Workspace: /home/claude/workspace
[INFO] Changed directory to workspace
[INFO] Set git user.name
[INFO] Set git user.email
[INFO] GitHub token provided, configuring gh CLI...
[INFO] Anthropic API key provided
[INFO] Loaded 15 agent specifications
[INFO] Found 3 workflow files
[INFO] Running pre-flight checks...
[INFO] Checking Go code...
[INFO] Go code is properly formatted
[INFO] Validating workflows...
[INFO] All workflows are valid
[INFO] Environment ready!
========================================
Container Information:
  User: claude
  Home: /home/claude
  Workspace: /home/claude/workspace
  Go version: go1.25.0
  Python version: 3.11.6
  Node version: v20.10.0
========================================
[INFO] No command provided, starting interactive shell...
```

#### Exit Codes

| Code | Description |
|------|-------------|
| 0 | Normal exit |
| 1 | Required tool not found or setup failed |

#### Examples

**Start Interactive Shell:**
```bash
docker run -it zeeke-ai-runner:latest
# entrypoint.sh runs with no arguments
```

**Run Specific Command:**
```bash
docker run zeeke-ai-runner:latest go test ./...
# entrypoint.sh runs: go test ./...
```

**Skip Preflight Checks:**
```bash
docker run -e RUN_PREFLIGHT=false zeeke-ai-runner:latest
```

#### Customization

**Disable Preflight:**
```bash
export RUN_PREFLIGHT=false
```

**Custom Workspace:**
```bash
export WORKSPACE=/custom/path
```

**Custom Git Config:**
```bash
export GIT_USER_NAME="CI Bot"
export GIT_USER_EMAIL="ci@example.com"
```

---

## Container Scripts

Scripts available inside the running container at `/home/claude/.local/bin/` or similar paths.

### version-check.sh

Verify installed tool versions.

#### Synopsis

```bash
version-check.sh [--json] [--short]
```

#### Description

Displays versions of all installed tools in the container. Useful for debugging and validation.

#### Options

| Option | Description |
|--------|-------------|
| `--json` | Output in JSON format |
| `--short` | Show only version numbers |

#### Examples

**Basic Usage:**
```bash
version-check.sh
```
Output:
```
Tool Versions:
  Claude Code: 1.2.3
  Go: go1.25.0 linux/amd64
  Python: Python 3.11.6
  Node.js: v20.10.0
  npm: 10.2.3
  act: 0.2.55
  actionlint: 1.6.26
  gh CLI: 2.40.0
```

**JSON Output:**
```bash
version-check.sh --json
```
Output:
```json
{
  "claude": "1.2.3",
  "go": "1.25.0",
  "python": "3.11.6",
  "node": "20.10.0",
  "npm": "10.2.3",
  "act": "0.2.55",
  "actionlint": "1.6.26",
  "gh": "2.40.0"
}
```

**Short Format:**
```bash
version-check.sh --short
```
Output:
```
claude: 1.2.3
go: 1.25.0
python: 3.11.6
```

---

### health-check.sh

Check container health status.

#### Synopsis

```bash
health-check.sh [--verbose]
```

#### Description

Performs health checks on all critical services and tools. Used by Docker health check system.

#### Options

| Option | Description |
|--------|-------------|
| `--verbose` | Show detailed check results |

#### Checks Performed

1. Claude CLI is functional
2. Go toolchain is working
3. Python interpreter is available
4. Workspace is accessible
5. Required directories exist

#### Examples

**Basic Check:**
```bash
health-check.sh
```
Output:
```
✓ All checks passed
```

**Verbose Check:**
```bash
health-check.sh --verbose
```
Output:
```
Checking Claude CLI... ✓
Checking Go toolchain... ✓
Checking Python... ✓
Checking workspace... ✓
Checking directories... ✓
All checks passed
```

#### Exit Codes

| Code | Description |
|------|-------------|
| 0 | All checks passed |
| 1 | One or more checks failed |

---

### security-scan.sh

Scan container for security issues.

#### Synopsis

```bash
security-scan.sh [--fix]
```

#### Description

Scans for common security issues like exposed secrets, incorrect permissions, and insecure configurations.

#### Options

| Option | Description |
|--------|-------------|
| `--fix` | Attempt to fix found issues |

#### Checks

- Secret files have correct permissions (600)
- No secrets in environment variables visible to logs
- Files are owned by correct user
- No world-writable files
- SSH keys have correct permissions

#### Examples

**Scan Only:**
```bash
security-scan.sh
```
Output:
```
Security Scan Results:
  ✓ Secret file permissions correct
  ✓ No exposed secrets in environment
  ✗ Found world-writable file: /tmp/test
  ✓ SSH key permissions correct

Issues found: 1
Run with --fix to attempt automatic repair
```

**Scan and Fix:**
```bash
security-scan.sh --fix
```
Output:
```
Security Scan Results:
  ✓ Secret file permissions correct
  ✓ No exposed secrets in environment
  ✗ Found world-writable file: /tmp/test
    → Fixed: chmod 644 /tmp/test
  ✓ SSH key permissions correct

Issues fixed: 1
```

#### Exit Codes

| Code | Description |
|------|-------------|
| 0 | No issues found |
| 1 | Issues found (without --fix) |
| 2 | Issues found and could not be fixed |

---

### validate-secrets.sh

Validate secrets configuration.

#### Synopsis

```bash
validate-secrets.sh [--strict]
```

#### Description

Validates that required secrets are present and properly formatted.

#### Options

| Option | Description |
|--------|-------------|
| `--strict` | Fail if optional secrets are missing |

#### Validation Checks

**GitHub Token (GITHUB_TOKEN):**
- Starts with `ghp_`, `ghs_`, `gho_`, or `github_pat_`
- Minimum length requirements
- Not expired (if possible to check)

**Anthropic API Key (ANTHROPIC_API_KEY):**
- Starts with `sk-ant-`
- Proper format

#### Examples

**Basic Validation:**
```bash
validate-secrets.sh
```
Output:
```
Validating Secrets:
  ✓ GITHUB_TOKEN present and valid format
  ✓ ANTHROPIC_API_KEY present and valid format
  ℹ Optional secrets not checked

All required secrets valid
```

**Strict Validation:**
```bash
validate-secrets.sh --strict
```
Output:
```
Validating Secrets:
  ✓ GITHUB_TOKEN present and valid format
  ✗ ANTHROPIC_API_KEY not set
  ✓ OTEL_ENDPOINT not set (optional in strict mode)

Validation failed: 1 issue
```

#### Exit Codes

| Code | Description |
|------|-------------|
| 0 | All required secrets valid |
| 1 | Validation failed |

---

## CLI Tools

### claude

Claude Code CLI for AI-assisted development.

#### Synopsis

```bash
claude [command] [options]
```

#### Common Commands

| Command | Description |
|---------|-------------|
| `--version` | Show Claude CLI version |
| `chat` | Start interactive chat session |
| `agent` | Run specific agent |
| `task` | Execute task with Claude |

#### Documentation

See official Claude Code documentation for complete reference.

---

### act

Run GitHub Actions workflows locally.

#### Synopsis

```bash
act [event] [options]
```

#### Common Events

| Event | Description |
|-------|-------------|
| `push` | Simulate push event |
| `pull_request` | Simulate PR event |
| `workflow_dispatch` | Manual trigger |

#### Common Options

| Option | Description |
|--------|-------------|
| `-l, --list` | List available workflows |
| `-n, --dryrun` | Dry run (don't execute) |
| `-W, --workflows` | Specify workflow file |
| `-s, --secret` | Pass secret value |
| `-v, --verbose` | Verbose output |

#### Examples

**List Workflows:**
```bash
act -l
```

**Dry Run:**
```bash
act push -n
```

**Run Specific Workflow:**
```bash
act -W .github/workflows/ci.yml
```

**Pass Secrets:**
```bash
act -s GITHUB_TOKEN=$GITHUB_TOKEN
```

---

### actionlint

Validate GitHub Actions workflow files.

#### Synopsis

```bash
actionlint [files...]
```

#### Options

| Option | Description |
|--------|-------------|
| `-color` | Enable color output |
| `-format` | Output format (default, json) |
| `-ignore` | Ignore patterns |
| `-verbose` | Verbose output |

#### Examples

**Validate All Workflows:**
```bash
actionlint .github/workflows/*.yml
```

**JSON Output:**
```bash
actionlint -format json .github/workflows/ci.yml
```

**Ignore Specific Issues:**
```bash
actionlint -ignore 'property "timeout-minutes" is not set' .github/workflows/*.yml
```

---

### gh

GitHub CLI for repository operations.

#### Synopsis

```bash
gh <command> <subcommand> [options]
```

#### Common Commands

| Command | Description |
|---------|-------------|
| `auth login` | Authenticate with GitHub |
| `repo clone` | Clone repository |
| `pr create` | Create pull request |
| `issue list` | List issues |
| `workflow run` | Trigger workflow |

#### Examples

**Authenticate:**
```bash
echo $GITHUB_TOKEN | gh auth login --with-token
```

**Clone Repository:**
```bash
gh repo clone owner/repo
```

**Create PR:**
```bash
gh pr create --title "Fix bug" --body "Description"
```

**List Workflows:**
```bash
gh workflow list
```

---

## Docker Compose Reference

### Services

#### gha-runner

Main GitHub Actions runner service.

**Image:** `zeeke-ai-runner:latest`

**User:** `claude` (UID 1001)

**Command:** `bash` (interactive shell)

**Restart:** `unless-stopped`

#### act-runner

Optional service for workflow testing.

**Profile:** `testing`

**Command:** `act -l`

**Use:**
```bash
docker compose --profile testing up act-runner
```

### Volumes

| Volume | Purpose | Driver |
|--------|---------|--------|
| `go-cache` | Go module cache | local |
| `go-build-cache` | Go build cache | local |
| `act-cache` | act cache | local |

### Networks

**Default Network:**
- Driver: bridge
- Automatic container DNS resolution

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Environment variables and settings
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions
- [Setup Guide](../SETUP_GUIDE.md) - Initial setup instructions
