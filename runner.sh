#!/bin/bash
# Helper script for managing GitHub Actions Runner container
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COMPOSE_FILE="docker-compose.runner.yml"
SERVICE_NAME="gha-runner"
IMAGE_NAME="zeeke-ai-runner"

# Functions
usage() {
    cat << EOF
${BLUE}GitHub Actions Runner Container Manager${NC}

${GREEN}Usage:${NC}
    $0 <command> [options]

${GREEN}Commands:${NC}
    ${YELLOW}start${NC}           Start the runner container
    ${YELLOW}stop${NC}            Stop the runner container
    ${YELLOW}restart${NC}         Restart the runner container
    ${YELLOW}shell${NC}           Open shell in runner container
    ${YELLOW}logs${NC}            View container logs
    ${YELLOW}build${NC}           Build the runner image
    ${YELLOW}test${NC}            Test workflows with act
    ${YELLOW}status${NC}          Show container status
    ${YELLOW}clean${NC}           Stop and remove container
    ${YELLOW}purge${NC}           Remove container and volumes
    ${YELLOW}rebuild${NC}         Clean, build, and start
    ${YELLOW}validate${NC}        Validate workflows

${GREEN}Examples:${NC}
    $0 start              # Start the runner
    $0 shell              # Access container shell
    $0 test ci.yml        # Test CI workflow
    $0 logs               # View logs
    $0 rebuild            # Full rebuild

${GREEN}Environment:${NC}
    Set these in .secrets file or export before running:
    - GITHUB_TOKEN
    - ANTHROPIC_API_KEY
    - SKILL_SEEKERS_PATH

EOF
    exit 0
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose not found"
        exit 1
    fi

    if [ ! -f "${COMPOSE_FILE}" ]; then
        log_error "docker-compose.runner.yml not found"
        exit 1
    fi
}

check_secrets() {
    if [ ! -f ".secrets" ]; then
        log_warn "No .secrets file found"
        log_warn "Create .secrets file with required tokens"
        log_warn "See .secrets.example for template"
        return 1
    fi
    return 0
}

# Commands
cmd_start() {
    log_info "Starting runner container..."
    check_secrets || log_warn "Container will start without secrets"
    docker compose -f "${COMPOSE_FILE}" up -d
    log_info "Runner started successfully"
    log_info "Access with: $0 shell"
}

cmd_stop() {
    log_info "Stopping runner container..."
    docker compose -f "${COMPOSE_FILE}" stop
    log_info "Runner stopped"
}

cmd_restart() {
    log_info "Restarting runner container..."
    docker compose -f "${COMPOSE_FILE}" restart
    log_info "Runner restarted"
}

cmd_shell() {
    log_info "Opening shell in runner container..."
    docker compose -f "${COMPOSE_FILE}" exec "${SERVICE_NAME}" bash
}

cmd_logs() {
    local FOLLOW="${1:-false}"
    if [ "$FOLLOW" = "-f" ] || [ "$FOLLOW" = "--follow" ]; then
        docker compose -f "${COMPOSE_FILE}" logs -f "${SERVICE_NAME}"
    else
        docker compose -f "${COMPOSE_FILE}" logs "${SERVICE_NAME}"
    fi
}

cmd_build() {
    log_info "Building runner image..."
    if [ -x "docker/build.sh" ]; then
        ./docker/build.sh
    else
        docker build -f Dockerfile.runner -t "${IMAGE_NAME}:latest" .
    fi
    log_info "Build complete"
}

cmd_test() {
    local WORKFLOW="${1}"
    if [ -z "$WORKFLOW" ]; then
        log_info "Listing available workflows..."
        docker compose -f "${COMPOSE_FILE}" exec "${SERVICE_NAME}" act -l
    else
        log_info "Testing workflow: ${WORKFLOW}"
        docker compose -f "${COMPOSE_FILE}" exec "${SERVICE_NAME}" \
            act -W ".github/workflows/${WORKFLOW}" -n
    fi
}

cmd_status() {
    log_info "Container status:"
    docker compose -f "${COMPOSE_FILE}" ps
    echo ""
    log_info "Image information:"
    docker images "${IMAGE_NAME}:latest" | head -2
}

cmd_clean() {
    log_info "Cleaning up containers..."
    docker compose -f "${COMPOSE_FILE}" down
    log_info "Cleanup complete"
}

cmd_purge() {
    log_warn "This will remove containers and volumes"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Purging containers and volumes..."
        docker compose -f "${COMPOSE_FILE}" down -v
        log_info "Purge complete"
    else
        log_info "Cancelled"
    fi
}

cmd_rebuild() {
    log_info "Full rebuild process..."
    cmd_clean
    cmd_build
    cmd_start
    log_info "Rebuild complete"
}

cmd_validate() {
    log_info "Validating workflows..."
    docker compose -f "${COMPOSE_FILE}" exec "${SERVICE_NAME}" \
        actionlint .github/workflows/*.yml
}

# Main
main() {
    if [ $# -eq 0 ]; then
        usage
    fi

    check_prerequisites

    local COMMAND=$1
    shift

    case "$COMMAND" in
        start)
            cmd_start "$@"
            ;;
        stop)
            cmd_stop "$@"
            ;;
        restart)
            cmd_restart "$@"
            ;;
        shell|bash|sh)
            cmd_shell "$@"
            ;;
        logs)
            cmd_logs "$@"
            ;;
        build)
            cmd_build "$@"
            ;;
        test)
            cmd_test "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        clean)
            cmd_clean "$@"
            ;;
        purge)
            cmd_purge "$@"
            ;;
        rebuild)
            cmd_rebuild "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            echo ""
            usage
            ;;
    esac
}

main "$@"
