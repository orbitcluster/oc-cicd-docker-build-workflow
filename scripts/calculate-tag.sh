#!/bin/bash
set -e

# Determine Image Name
if [ -z "$INPUT_IMAGE_NAME" ]; then
  # Default to repo name (remove owner/)
  IMAGE_NAME=${GITHUB_REPOSITORY#*/}
else
  IMAGE_NAME=$INPUT_IMAGE_NAME
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

# What is the current branch name?
BRANCH_NAME=${GITHUB_REF#refs/heads/}
echo "BRANCH_NAME=${BRANCH_NAME}"

# If the branch is main, use the latest tag
if [ "$BRANCH_NAME" == "main" ]; then
  git fetch --tags
  LATEST_TAG=$(git describe --tags --abbrev=0)
  DOCKER_TAG=$LATEST_TAG

# If the branch is not main, use the branch name and date
else
  # Sanitize branch name (replace slashes with hyphens)
  SAFE_BRANCH_NAME=$(echo "$BRANCH_NAME" | tr '/' '-')
  DOCKER_TAG="${SAFE_BRANCH_NAME}"
fi

echo "DOCKER_TAG=$DOCKER_TAG" >> $GITHUB_ENV
echo "DOCKER_TAG=$DOCKER_TAG"
