#!/bin/bash
# Build script for GitHub Actions Runner with Claude Code
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="${IMAGE_NAME:-axyzlabs/runner}"
IMAGE_TAG="${1:-latest}"
DOCKERFILE="Dockerfile"
BUILD_ARGS="${2:-}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building GitHub Actions Runner Image${NC}"
echo -e "${BLUE}========================================${NC}"

# Verify prerequisites
echo -e "${GREEN}[1/5]${NC} Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not found${NC}"
    exit 1
fi

if [ ! -f "${DOCKERFILE}" ]; then
    echo -e "${RED}Error: ${DOCKERFILE} not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Prerequisites OK"

# Check user-level agents
echo -e "${GREEN}[2/5]${NC} Verifying user-level agents..."

if [ ! -d "${HOME}/.claude/agents" ]; then
    echo -e "${YELLOW}Warning: User-level agents not found at ${HOME}/.claude/agents${NC}"
    echo -e "${YELLOW}The container will work but without user-level agents${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    AGENT_COUNT=$(find "${HOME}/.claude/agents" -type f | wc -l)
    echo -e "${GREEN}✓${NC} Found ${AGENT_COUNT} user-level agent files"
fi

# Check entrypoint script
echo -e "${GREEN}[3/5]${NC} Verifying entrypoint script..."

if [ ! -f "entrypoint.sh" ]; then
    echo -e "${RED}Error: entrypoint.sh not found${NC}"
    exit 1
fi

# Make entrypoint executable
chmod +x entrypoint.sh
echo -e "${GREEN}✓${NC} entrypoint.sh found and made executable"

# Pull base image
echo -e "${GREEN}[4/5]${NC} Pulling base image..."
docker pull ghcr.io/catthehacker/ubuntu:act-latest || {
    echo -e "${YELLOW}Warning: Failed to pull latest base image, using cached version${NC}"
}

# Build image
echo -e "${GREEN}[5/5]${NC} Building Docker image..."
echo -e "${BLUE}Image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"

BUILD_CMD="docker build"
BUILD_CMD+=" -f ${DOCKERFILE}"
BUILD_CMD+=" -t ${IMAGE_NAME}:${IMAGE_TAG}"

# Add build args if provided
if [ -n "${BUILD_ARGS}" ]; then
    BUILD_CMD+=" ${BUILD_ARGS}"
fi

# Enable BuildKit for better caching
BUILD_CMD+=" --progress=plain"
BUILD_CMD+=" ."

echo -e "${BLUE}Command: ${BUILD_CMD}${NC}"

# Export BuildKit env
export DOCKER_BUILDKIT=1

# Execute build
if ${BUILD_CMD}; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${BLUE}Image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"

    # Display image info
    docker images "${IMAGE_NAME}:${IMAGE_TAG}" | grep -v REPOSITORY

    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "  1. Test the image:"
    echo -e "     ${GREEN}docker run -it --rm ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
    echo -e "\n  2. Run with docker-compose:"
    echo -e "     ${GREEN}docker compose up -d${NC}"
    echo -e "\n  3. Access the container:"
    echo -e "     ${GREEN}docker compose exec runner bash${NC}"
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Build failed!${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
