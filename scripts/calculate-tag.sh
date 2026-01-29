#!/bin/bash
set -e

# Determine Image Name
if [ -z "$IMAGE_NAME" ]; then
  # Default to repo name (remove owner/)
  IMAGE_NAME=${GITHUB_REPOSITORY#*/}
else
  IMAGE_NAME=$IMAGE_NAME
fi

# Validation: Check if empty
if [ -z "$IMAGE_NAME" ]; then
  echo "Error: Image name could not be determined."
  exit 1
fi

# Sanitization: Convert to lowercase
IMAGE_NAME=$(echo "$IMAGE_NAME" | tr '[:upper:]' '[:lower:]')
echo "IMAGE_NAME=$IMAGE_NAME" >> $GITHUB_ENV
echo "IMAGE_NAME=$IMAGE_NAME"

# Determine Base Version
if [ -n "$TAG_OVERRIDE" ]; then
    echo "Using tag override: $TAG_OVERRIDE"
    BASE_VERSION="$TAG_OVERRIDE"
else
    # Try to get latest git tag
    # Try to get latest git tag matching SemVer (vX.Y.Z)
    if git describe --tags --abbrev=0 --match "v*.*.*" > /dev/null 2>&1; then
        BASE_VERSION=$(git describe --tags --abbrev=0 --match "v*.*.*")
    elif git describe --tags --abbrev=0 > /dev/null 2>&1; then
        # Fallback to any tag if semver not found
        BASE_VERSION=$(git describe --tags --abbrev=0)
    else
        echo "No git tags found, using default 0.0.0"
        BASE_VERSION="0.0.0"
    fi
fi

# Determine Branch Logic
# Check Environment Variables for Branch Info
BRANCH_NAME=""
if [ -n "$GITHUB_HEAD_REF" ]; then
    BRANCH_NAME="${GITHUB_HEAD_REF}"
    echo "Detected PR Branch: ${BRANCH_NAME}"
elif [ -n "$GITHUB_REF_NAME" ]; then
    BRANCH_NAME="${GITHUB_REF_NAME}"
    echo "Detected Branch: ${BRANCH_NAME}"
else
    # Fallback to current checked out branch if env not set
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
fi


if [ "$BRANCH_NAME" == "main" ]; then
    echo "Branch is main."
    DOCKER_TAG="${BASE_VERSION}"
else
    echo "Branch is ${BRANCH_NAME}. Generating pre-release version."
    
    # Sanitize branch name (replace slashes/underscores with hyphens)
    SAFE_BRANCH=$(echo "${BRANCH_NAME}" | tr '/_' '-')
    
    # Short SHA
    SHORT_SHA=$(echo "${GITHUB_SHA}" | cut -c1-7)
    
    # If SHA is empty (running locally without env var), try git
    if [ -z "$SHORT_SHA" ]; then
        SHORT_SHA=$(git rev-parse --short HEAD)
    fi

    # Format: {base}-{branch}-{sha}
    DOCKER_TAG="${BASE_VERSION}-${SAFE_BRANCH}-${SHORT_SHA}"
fi

echo "Calculated Docker Tag: $DOCKER_TAG"
echo "DOCKER_TAG=$DOCKER_TAG" >> $GITHUB_ENV
echo "docker-tag=$DOCKER_TAG" >> $GITHUB_OUTPUT
echo "safe-branch=${SAFE_BRANCH}" >> $GITHUB_OUTPUT
