#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
BACKEND_DIR="$REPO_ROOT/backend"

IMAGE_NAME="${IMAGE_NAME:-homepets-backend}"
TAG="${1:-${TAG:-v0.0.1}}"

docker build \
  -f "$BACKEND_DIR/Dockerfile" \
  -t "$IMAGE_NAME:$TAG" \
  "$BACKEND_DIR"

echo "Built image: $IMAGE_NAME:$TAG"
