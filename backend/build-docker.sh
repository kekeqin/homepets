#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

docker build -f "$ROOT_DIR/backend/Dockerfile" -t pickstarpet:latest "$ROOT_DIR" \
	&& docker pussh pickstarpet:latest root@kkqin.com
