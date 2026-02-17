#!/bin/bash
set -e

# Default to repo name (remove owner/) if IMAGE_NAME not set
IMAGE_NAME=${IMAGE_NAME:-${GITHUB_REPOSITORY#*/}}

# Validation: Check if empty
[ -z "$IMAGE_NAME" ] && echo "Error: Image name could not be determined." && exit 1

# Sanitization: Convert to lowercase
IMAGE_NAME=$(echo "$IMAGE_NAME" | tr '[:upper:]' '[:lower:]')
echo "IMAGE_NAME=$IMAGE_NAME" >> $GITHUB_ENV
echo "IMAGE_NAME=$IMAGE_NAME"

# Determine Base Version
# Priority: TAG_OVERRIDE > Latest SemVer Tag > 0.0.0
# Using a function to keep it clean without if/else blocks in main logic
get_version() {
    # Check override
    [ -n "$TAG_OVERRIDE" ] && echo "$TAG_OVERRIDE" && return

    # Check git tags
    git describe --tags --abbrev=0 --match "v*.*.*" 2>/dev/null || \
    git describe --tags --abbrev=0 2>/dev/null || \
    echo "0.0.0"
}

BASE_VERSION=$(get_version)
[ -z "$BASE_VERSION" ] && echo "No git tags found, using default 0.0.0" && BASE_VERSION="0.0.0"

# Determine Branch Logic
# Priority: GITHUB_HEAD_REF (PR) > GITHUB_REF_NAME (Push) > git branch (Local)
BRANCH_NAME=${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}}

# Determine Docker Tag
# If main branch: use version only
# If not main: use version-branch-sha
SAFE_BRANCH=$(echo "${BRANCH_NAME}" | tr '/_' '-')
SHORT_SHA=$(echo "${GITHUB_SHA}" | cut -c1-7)
SHORT_SHA=${SHORT_SHA:-$(git rev-parse --short HEAD)}

DOCKER_TAG="${BASE_VERSION}"
[ "$BRANCH_NAME" != "main" ] && DOCKER_TAG="${BASE_VERSION}-${SAFE_BRANCH}-${SHORT_SHA}"

echo "Calculated Docker Tag: $DOCKER_TAG"
echo "DOCKER_TAG=$DOCKER_TAG" >> $GITHUB_ENV
echo "docker-tag=$DOCKER_TAG" >> $GITHUB_OUTPUT
echo "safe-branch=${SAFE_BRANCH}" >> $GITHUB_OUTPUT
